---
title: Error Handling
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 24px;
  }
---

# Error Handling

---

### Error Handling

**Why Error Handling Matters**

- Programs fail: invalid input, missing data, network issues
- Imperative approach: try-catch, null checks, error codes
- Functional approach: **make errors explicit in types**

**The Goal**

- Errors as values, not exceptions
- Clear function signatures that show success AND failure
- Compose functions naturally, even when they can fail
<!--
Hvorfor er det her vigtigt? Fordi alle programmer kan fejle. Vi får ugyldigt input, netværket er nede, databasen svarer ikke.

Den imperative tilgang er ofte baseret på exceptions, null-tjek og fejlkoder. Dette kan skjule, hvor og hvordan en funktion kan fejle.

Den funktionelle tilgang er anderledes. Målet er at gøre potentielle fejl til en _eksplicit_ del af en funktions typesignatur. Vi vil behandle fejl som almindelige værdier, ikke som en speciel kontrolstruktur. Dette gør det muligt at komponere funktioner, der kan fejle, på en forudsigelig og sikker måde.
-->

---

### Our Simple Example: User Registration

**The Task**

Register a user with these steps:

1. Validate email format
2. Check email isn't already taken
3. Hash the password
4. Save to database

Each step can fail. How do we handle it elegantly?

<!--
For at illustrere dette, bruger vi et simpelt, genkendeligt eksempel: en brugerregistrerings-workflow.

Processen består af flere trin, og hvert eneste trin kan gå galt. E-mailen kan have et forkert format, den kan allerede være i brug, kodeordet kan være for svagt, og databasen kan være nede.

Udfordringen er at kæde disse operationer sammen, så hele processen stopper, så snart det første trin fejler.
-->

---

### The Naive Approach: Exceptions

```fsharp
let validateEmail email =
    if email.Contains("@") then email
    else failwith "Invalid email"

let checkNotTaken email =
    if email = "taken@test.com" then
        failwith "Email already exists"
    else email

let hashPassword password =
    if String.length password < 6 then
      failwith "Password too short"
    password + "_hashed"

let saveUser email password =
    // save user to db
    "Success"
```

<!--
Den første indskydelse, især hvis man kommer fra en C# eller Java baggrund, er at bruge exceptions.

Hver funktion tjekker for en fejl-betingelse, og hvis den opstår, kaster den en exception med `failwith`. Hvis alt går godt, returnerer den en succes-værdi.

Dette virker, men det har nogle alvorlige ulemper, som vi skal se nu.
-->

---

### The Problem with Exceptions

```fsharp
let registerUser email password =
    try
        let validEmail = validateEmail email
        let availableEmail = checkNotTaken validEmail
        let hashedPw = hashPassword password
        saveUser availableEmail hashedPw
    with
    | ex -> "Error: " + ex.Message
```

**Issues:**

- Errors hidden in function signatures
- Can't see what might fail by reading types
- Hard to handle different error cases differently
<!--
Når vi skal bruge vores exception-baserede funktioner, er vi tvunget til at pakke hele vores "happy path" logik ind i en stor `try-catch` blok.

Det store problem er, at en funktions typesignatur ikke fortæller os, at den kan kaste en exception. `validateEmail` har typen `string -> string`. Der er ingen indikation af, at den kan eksplodere. Man er nødt til at læse koden (eller dokumentationen) for at vide det. Dette kaldes "usynlige fejl".

Det gør det også svært at håndtere forskellige fejl på forskellige måder. Alt ender i den samme `catch`-blok.
-->

---

### The Solution: The Result Type

```fsharp
type Result<'Success, 'Failure> =
    | Ok of 'Success
    | Error of 'Failure
```

**Two tracks:**

- **Success track**: `Ok` contains the value
- **Failure track**: `Error` contains the error

Flow is always forward moving.
Functions return `Result` instead of throwing exceptions.

<!--
Løsningen i funktionel programmering er at bruge en type, der eksplicit repræsenterer både succes og fiasko. Den mest almindelige er `Result`-typen, som er en Discriminated Union.

En værdi af typen `Result` kan være én af to ting:
- `Ok`, som indeholder en succes-værdi.
- `Error`, som indeholder en fejl-værdi.

Dette er kernen i Railway-Oriented Programming. Vi har to spor: et succes-spor og et fejl-spor. Alle vores funktioner vil nu returnere en `Result`, hvilket gør deres signatur ærlig omkring, at de kan fejle.
-->

---

### Rewriting with Result

```fsharp
let validateEmail email =
    if email.Contains("@") then Ok email
    else Error "Invalid email format"

let checkNotTaken email =
    if email = "taken@test.com" then Error "Email already exists"
    else Ok email

let hashPassword password =
    if String.length password < 6 then Error "Password too short"
    else Ok (password + "_hashed")

let saveUser email password =
    // save user to db
    Ok (sprintf "Saved user: %s" email)
```

<!--
Her har vi omskrevet vores funktioner til at bruge `Result`.

I stedet for at kaste en exception med `failwith`, returnerer de nu en `Error`-værdi. Og i stedet for at returnere den rå succes-værdi, pakker de den ind i `Ok`.

Nu er funktionernes signaturer ærlige. `validateEmail` har nu typen `string -> Result<string, string>`. Ved at se på typen alene ved vi, at den tager en string, og returnerer enten en `Ok` med en string, eller en `Error` med en string. Fejlene er ikke længere usynlige.
-->

---

### The Composition Problem

```fsharp
let registerUser email password =
    let result1 = validateEmail email
    match result1 with
    | Error e -> Error e
    | Ok validEmail ->
        let result2 = checkNotTaken validEmail
        match result2 with
        | Error e -> Error e
        | Ok availableEmail ->
            let result3 = hashPassword password
            match result3 with
            | Error e -> Error e
            | Ok hashedPw ->
                saveUser availableEmail hashedPw
```

**This is tedious!** We need a better way to chain these functions.

<!--
Men nu har vi et nyt problem. Hvordan kæder vi disse funktioner sammen?

Den naive tilgang er at pattern-matche på resultatet af hver funktion. Dette fører til dybt indlejret kode, den såkaldte "Pyramid of Doom".

For hvert trin i vores workflow skal vi tjekke, om det forrige var `Ok` eller `Error`. Dette er ekstremt repetitivt og grimt. Vi har byttet `try-catch` ud med et `match`-helvede. Det kan vi gøre bedre.
-->

---

### The Bind Function: Switching Tracks

```fsharp
let bind nextFunction result =
    match result with
    | Ok value -> nextFunction value
    | Error e -> Error e
```

**What bind does:**

- If `Ok`: apply the next function (stay on success track)
- If `Error`: skip the function (stay on error track)

Bind lets us **compose functions that return Result**.

<!--
Løsningen er en hjælpefunktion, som vi kalder `bind`. `bind` er designet til at forbinde to funktioner, der begge returnerer en `Result`.

`bind` tager en funktion (`nextFunction`) og et `Result`.
- Hvis `result` er `Ok value`, så pakker `bind` værdien `value` ud og kalder `nextFunction` med den.
- Hvis `result` er `Error e`, så ignorerer `bind` `nextFunction` fuldstændig og sender bare `Error e` videre.

`bind` er den "skinne-skifter", der automatiserer logikken med at tjekke for `Ok` eller `Error`. Den holder os på succes-sporet, så længe alt går godt, og skifter os over på fejl-sporet ved den første fejl.
-->

---

### Clean Composition with Bind

```fsharp
let (>>=) result nextFunction =
    bind nextFunction result

let registerUser email password =
    validateEmail email
    >>= checkNotTaken
    >>= (fun validEmail ->
            hashPassword password
            >>= (fun hashedPw ->
                    saveUser validEmail hashedPw))
```

Or with better formatting:

```fsharp
let registerUser email password =
    validateEmail email
    >>= checkNotTaken
    >>= fun email -> saveUser email (password + "_hashed")
```

<!--
For at gøre det endnu mere elegant, definerer vi en custom operator for `bind`, `>>=`, som er standarden i F# og Haskell.

Nu kan vi omskrive vores `registerUser`-funktion til en smuk, flad pipeline.

`validateEmail email` bliver kaldt. Resultatet (`Ok` eller `Error`) bliver "pipet" ind i `checkNotTaken` via `>>=`. `>>=` (vores `bind`-funktion) håndterer `match`'et. Hvis det første resultat var `Ok`, kaldes `checkNotTaken`. Hvis det var `Error`, stoppes flowet.

Resultatet af *det* bliver så pipet videre. Hele pyramiden er blevet fladtrykt til en læsbar sekvens.
-->

---

### Railway-Oriented Programming

**The Mental Model**

```
Input ──> [validateEmail] ──> [checkNotTaken] ──> [save] ──> Output
          Success ↓ Error ↓    Success ↓ Error ↓   Success ↓ Error ↓
                   ↓           ↓                    ↓
                   └──────────>└───────────────────> Error Output
```

- Functions on the success track
- Any error switches to error track
- Once on error track, stay there
- Both tracks lead to final result
<!--
Dette er den visuelle metafor for Railway-Oriented Programming.

Vores data starter på det øverste "succes-spor". Hver funktion er en station. Så længe funktionen returnerer `Ok`, fortsætter toget på succes-sporet til næste station.

Men så snart en funktion returnerer `Error`, bliver toget ledt ned på det nederste "fejl-spor" via et sporskifte. Når først toget er på fejl-sporet, kører det forbi alle de efterfølgende stationer uden at stoppe.

Til sidst ankommer toget til endestationen, enten med et `Ok`-resultat fra succes-sporet, eller et `Error`-resultat fra fejl-sporet.
-->

---

### Result is a Monad

**What makes Result a monad?**

1. **Return**: Put a value in the monad

   ```fsharp
   let return' x = Ok x
   ```

2. **Bind**: Chain operations

   ```fsharp
   let bind f m = match m with
                  | Ok x -> f x
                  | Error e -> Error e
   ```

3. **Monad Laws**: Ensures composition works predictably
<!--
Dette mønster, vi har bygget med `Result`, `bind` og en `return`-funktion (`Ok`), er ikke bare et smart trick. Det er et veldefineret matematisk koncept, der kaldes en **monade**.

En type er en monade, hvis den har de to funktioner:

1. `return` (eller `pure`): At tage en simpel værdi og løfte den ind i monade-konteksten. For `Result` er det `Ok`-konstruktøren.
2. `bind` (`>>=`): At tage en monadisk værdi og en funktion, der returnerer en ny monadisk værdi, og kæde dem sammen.

Der er også nogle love, de skal overholde, men de sikrer blot, at komposition opfører sig forudsigeligt.
-->

---

### Why Monads Matter Here

**Benefits of the monadic structure:**

- **Automatic error propagation**: No manual checking needed
- **Composability**: Chain operations with `>>=`
- **Type safety**: Compiler forces you to handle both tracks
- **Clear intent**: Function signature shows it can fail
- **Separation of concerns**: Business logic separate from error handling

The monad handles the "plumbing" of passing success/failure through the chain.

<!--
Hvorfor er det vigtigt, at det er en monade? Fordi det giver os en masse fordele "gratis":

- Fejl bliver propageret automatisk. `bind` tager sig af det.
- Vores kode bliver ekstremt komponerbar. Vi kan bygge komplekse workflows ved at sætte simple, monadiske funktioner sammen med `>>=`.
- Typesystemet tvinger os til at anerkende og håndtere både succes- og fejl-tilfælde til sidst.
- Vores forretningslogik (happy path) bliver adskilt fra fejlhåndterings-"infrastrukturen". `bind` er infrastrukturen. Vores funktioner er forretningslogikken.

Monaden er det, der håndterer alt "rørarbejdet" (plumbing) for os, så vi kan fokusere på, hvad vores kode skal gøre.

Tak.
-->

---

