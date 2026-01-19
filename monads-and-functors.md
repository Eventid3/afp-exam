---
title: Monads and Functors
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 26px;
  }
---

# Monads and Functors

---

### Functors

- A design pattern that alters nested values
- The structure is kept
- Typically called a 'map' function:

```fsharp
List.map: ('a -> 'b) -> list<'a> -> list<'b>
```

<!--
Lad os starte med Funktorer. En funktor er basalt set en type, der understøtter en `map`-operation.

Tænk på en `list<'a>`. `List.map` tager en funktion fra `'a` til `'b` og en `list<'a>` og giver dig en `list<'b>`.

Det vigtige er, at `map` anvender funktionen på hver værdi *indeni* strukturen, men selve strukturen (listen) bevares. Hvis du starter med en liste med 5 elementer, ender du med en liste med 5 elementer. Kun værdierne indeni er blevet transformeret.

Andre eksempler er `Option.map`, `Array.map`, og `Async.map`. De er alle funktorer.
-->

---

### Functor laws

- Using the identity function should results in the same data

```fsharp
List.map (fun i -> i) [1; 2; 3;]
// [1; 2; 3;]
```

<!--
For at en `map`-funktion kan siges at opføre sig som en "rigtig" funktor, skal den overholde to simple love.

Den første er identitetsloven. Den siger, at hvis du mapper med identitetsfunktionen (en funktion der bare returnerer sit input), så skal du have den oprindelige struktur tilbage, helt uændret.

Som vi ser her, at mappe `[1; 2; 3]` med `fun i -> i` giver os `[1; 2; 3]` tilbage. Det virker indlysende, men det er en vigtig garanti: `map` må ikke lave andet end at anvende den givne funktion.
-->

---

### Functor laws

- A sequence of mapper functions should give the same result as function composition

```fsharp
let f x = x * 2
let g x = x + 1
[1;2;3;] |> List.map f |> List.map g
// val it: int list = [3; 5; 7]
[1;2;3;] |> List.map (f >> g)
// val it: int list = [3; 5; 7]
```

<!--
Den anden lov er kompositionsloven. Den siger, at hvis du mapper med en funktion `f` og derefter mapper med en funktion `g`, skal det give præcis samme resultat, som hvis du først sammensætter `f` og `g` til én funktion, og derefter mapper med den sammensatte funktion.

Her ser vi, at at mappe med `f` og så `g` giver `[3; 5; 7]`. Og at mappe med den komponerede funktion `f >> g` giver præcis det samme.

Denne lov garanterer, at vi kan optimere vores `map`-operationer ved at kombinere dem, og at `map` ikke laver noget "sjovt" mellem kaldene.
-->

---

### Monads

- Functional design pattern
- Applies a function to a wrapped value, and returns a wrapped value
- Exists to avoid imperative style programming
- Must implement return and bind functions

```fsharp
val return': 'a -> M<'a>
val bind: ('a -> M<'b>) -> M<'a> -> M<'b>
```

<!--
Nu til monader. En monade er også et designmønster for indpakkede værdier, men den er mere kraftfuld end en funktor.

Hvor en funktors `map` tager en funktion `a -> b`, tager en monades `bind`-funktion en funktion `a -> M<b>`, hvor `M` er monade-typen (f.eks. `Option`). Funktionen, vi giver til `bind`, ved altså selv, hvordan den skal pakke sin returværdi ind i monaden.

Formålet med monader er at sekventere beregninger, der arbejder med disse indpakkede værdier, på en elegant og funktionel måde, så vi undgår grim, indlejret imperativ kode.

En type skal implementere to funktioner for at være en monade: `return` og `bind`.
-->

---

### Monads - return

Return is just implemented as a type constructor
The Option type is a monad

```fsharp
let x = Some 1
let y = None
```

<!--
`return`-funktionen (også kaldet `pure` i nogle sprog) er den simpleste. Den tager en almindelig værdi og pakker den ind i monade-konteksten.

For `Option`-monaden er `return` bare `Some`-konstruktøren. Den tager en værdi, f.eks. `1`, og returnerer den indpakkede værdi `Some 1`.

Det er vores måde at løfte en normal værdi op i den monadiske verden.
-->

---

### Monads - bind

```fsharp
// Option.bind
let bind f x =
    match x with
    | Some v -> f v
    | None   -> None

bind (fun v -> Some (v+1)) (Some 4)
// val it: int option = Some 5
bind (fun v -> Some (v+1)) (None)
// val it: int option = None
```

<!--
`bind` er hjertet i monaden. Den er nøglen til at kæde operationer sammen.

`bind` tager to argumenter:
1. En funktion `f`, der går fra en normal værdi `v` til en ny indpakket værdi (`f v`).
2. En indpakket værdi `x`.

`bind` pakker værdien ud af `x` (hvis der er en) og giver den til funktionen `f`. Funktionen `f` udfører sin logik og returnerer en ny indpakket værdi.

For `Option.bind`:
- Hvis input er `Some v`, pakker den `v` ud, kalder `f` med `v`, og returnerer resultatet.
- Hvis input er `None`, gør den ingenting og returnerer `None` med det samme. Dette er "short-circuiting" opførslen, der gør `Option`-monaden så god til at håndtere fejl.
-->

---

### Monads - the problem

```fsharp
// code that might fail
let divide x y =
    if y = 0 then None else Some(x / y)

// imperative style
let compute a b c =
    match divide a b with
    | Some result1 ->
        match divide result1 c with
        | Some result2 -> Some result2
        | None -> None
    | None -> None

compute 100 5 2  // Some 10
compute 100 0 2  // None
```

<!--
For at se hvorfor `bind` er så nyttigt, lad os se på et problem. Vi har en `divide` funktion, der kan fejle (returnerer `None` ved division med nul).

Vi vil lave en beregning, der involverer to divisioner efter hinanden. Den imperative stil tvinger os til at indlejre `match`-udtryk. Dette kaldes ofte "Pyramid of Doom". For hver ny operation, der kan fejle, får vi et nyt niveau af indrykning. Det er grimt, svært at læse og svært at vedligeholde.
-->

---

### Monads - the monadic solution

```fsharp
// code that might fail
let divide x y =
    if y = 0 then None else Some(x / y)

// declerative style
let compute a b c =
    divide a b
    |> Option.bind (fun result1 -> divide result1 c)

compute 100 5 2  // Some 10
compute 100 0 2  // None
```

<!--
Her er den monadiske løsning med `bind`.

Vi starter med den første division, `divide a b`. Resultatet af dette (`Some` eller `None`) bliver "pipet" ind i `Option.bind`.

`bind` håndterer `match`'et for os. Hvis `divide a b` var `None`, stopper `bind` og returnerer `None`. Hvis det var `Some result1`, pakker `bind` `result1` ud og kalder vores lambda-funktion med den. Lambda-funktionen udfører den næste operation, `divide result1 c`.

Resultatet er en flad, deklarativ pipeline. `bind` abstraherer alt det indlejrede `match`-logik væk og lader os fokusere på "happy path", velvidende at fejlhåndteringen sker automatisk.
I F# har vi `computation expressions` (`option { ... }`), der er syntaktisk sukker over `bind`, og gør dette endnu pænere.
-->

