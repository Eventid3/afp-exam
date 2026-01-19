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
<!-- Emne: Funktionel fejlhåndtering. Eksplicit, sikker og komponerbar håndtering af fejl vha. Railway-Oriented Programming. -->
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
- Problem: Programmer fejler (input, netværk, etc.).
- Imperativ tilgang: `try-catch`, `null`, fejlkoder. Skjuler potentielle fejl.
- Funktionel tilgang: Gør fejl eksplicitte i typesystemet.
- Mål: Fejl som værdier, ærlige signaturer, komponerbarhed.
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
- Eksempel: Brugerregistrering.
- Workflow: Validering, tjek for dublet, hash password, gem i DB.
- Udfordring: Hvert trin kan fejle. Processen skal stoppe ved første fejl.
-->
---

### The Naive Approach: Exceptions

```fsharp
let validateEmail email =
    if email.Contains("@") then email
    else failwith "Invalid email"
// ...
```
<!--
- Naiv tilgang: Brug exceptions (`failwith`).
- Hver funktion kaster en exception ved fejl.
- Virker, men har ulemper ift. typesikkerhed og komposition.
-->
---

### The Problem with Exceptions

```fsharp
let registerUser email password =
    try
        // ...
    with
    | ex -> "Error: " + ex.Message
```
**Issues:**
- Errors hidden in function signatures
- Can't see what might fail by reading types
- Hard to handle different error cases differently
<!--
- Problem: "Usynlige fejl". `string -> string` signaturen lyver; den kan eksplodere.
- Man skal læse koden for at kende til fejlene.
- Hele "happy path" ender i en stor `try-catch` blok.
- Svært at håndtere forskellige fejltyper forskelligt.
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
- Løsning: En type, der eksplicit repræsenterer succes og fiasko.
- `Result<'T, 'E>`: En Discriminated Union med to cases:
    - `Ok of 'T`: Indeholder succes-værdien.
    - `Error of 'E`: Indeholder fejl-værdien.
- Kernen i Railway-Oriented Programming (to spor).
- Funktioner returnerer nu `Result`, hvilket gør signaturen ærlig.
-->
---

### Rewriting with Result

```fsharp
let validateEmail email =
    if email.Contains("@") then Ok email
    else Error "Invalid email format"
// ...
```
<!--
- Funktionerne omskrives til at returnere `Result`.
- I stedet for `failwith`, returneres `Error e`.
- I stedet for en rå værdi, returneres `Ok value`.
- Signaturen er nu ærlig: `string -> Result<string, string>`. Fejl er synlige i typen.
-->
---

### The Composition Problem

```fsharp
let registerUser email password =
    let result1 = validateEmail email
    match result1 with
    | Error e -> Error e
    | Ok validEmail ->
        // ... nested match
```
**This is tedious!** We need a better way to chain these functions.
<!--
- Nyt problem: Hvordan kædes funktioner, der returnerer `Result`, sammen?
- Naiv tilgang: Indlejrede `match`-udtryk.
- "Pyramid of Doom": Koden bliver repetitiv og grim.
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
- Løsning: `bind`-funktionen, en "skinne-skifter".
- Formål: At forbinde to `Result`-returnerende funktioner.
- Logik:
    - Hvis input er `Ok value`, kald `nextFunction` med `value`.
    - Hvis input er `Error e`, ignorer `nextFunction` og propager `Error e`.
- Automatiserer `match`-logikken.
-->
---

### Clean Composition with Bind

```fsharp
let (>>=) result nextFunction =
    bind nextFunction result

let registerUser email password =
    validateEmail email
    >>= checkNotTaken
    >>= // ...
```
<!--
- For elegance defineres en `>>=` (bind) operator.
- Workflowet omskrives til en flad, læsbar pipeline.
- `>>=` håndterer `match`'et og "short-circuiting" ved fejl.
- Pyramiden er fladtrykt.
-->
---

### Railway-Oriented Programming

**The Mental Model**
```
Input ──> [validate] ──> [save] ──> Output
          Success ↓         ↓
          Error   └─>─────>─┘ Error
```
- Functions on the success track
- Any error switches to error track
- Once on error track, stay there
- Both tracks lead to final result
<!--
- Metafor: To jernbanespor.
- Data starter på succes-sporet (øverst).
- Hver funktion er en station. Ved `Ok` fortsætter toget.
- Ved `Error` skifter toget til fejl-sporet (nederst) og kører forbi alle resterende stationer.
- Resultatet er enten `Ok` fra enden af succes-sporet eller `Error` fra fejl-sporet.
-->
---

### Result is a Monad

**What makes Result a monad?**
1. **Return**: Put a value in the monad
   `let return' x = Ok x`
2. **Bind**: Chain operations
   `let bind f m = ...`

3. **Monad Laws**: Ensures composition works predictably
<!--
- Mønsteret (`Result` + `bind` + `return`) er en **monade**.
- Krav for en monade:
    1. `return` (eller `pure`): Løfter en værdi ind i konteksten (`Ok` for `Result`).
    2. `bind` (`>>=`): Kæder monadiske operationer sammen.
- Monade-lovene sikrer forudsigelig opførsel.
-->
---

### Why Monads Matter Here

**Benefits of the monadic structure:**
- **Automatic error propagation**
- **Composability**
- **Type safety**
- **Clear intent**
- **Separation of concerns**

The monad handles the "plumbing".
<!--
- Fordele ved monaden:
    - Automatisk propagering af fejl.
    - Let at komponere komplekse workflows (`>>=`).
    - Typesystemet tvinger håndtering af `Ok`/`Error`.
    - Ærlige signaturer.
    - Adskiller forretningslogik fra fejlhåndterings-"infrastruktur".
- Monaden håndterer "rørarbejdet" for os.
-->