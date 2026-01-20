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

## <!-- Emne: Funktorer og Monader - designmønstre til at arbejde med "indpakkede" værdier (f.eks. List, Option). -->

---

### Functors

- A design pattern that alters nested values
- The structure is kept
- Typically called a 'map' function:

```fsharp
List.map: ('a -> 'b) -> list<'a> -> list<'b>
```

<!--
- Funktor: En type, der understøtter en `map`-operation.
- `map`: Anvender en funktion på værdier *indeni* en struktur (kontekst).
- Strukturen bevares: En liste med 5 elementer forbliver en liste med 5 elementer.
- Eksempler: `List.map`, `Option.map`, `Array.map`.
-->

---

### Functor laws

- Using the identity function should results in the same data

```fsharp
List.map (fun i -> i) [1; 2; 3;]
// [1; 2; 3;]
```

<!--
- En "rigtig" funktor skal overholde to love.
- **Identitetsloven**: `map` med identitetsfunktionen (`fun x -> x`) må ikke ændre data.
- Garanti: `map` gør *kun* det at anvende den givne funktion.
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
- **Kompositionsloven**: At `map`'e med `f` og derefter `g` er det samme som at `map`'e med `f >> g`.
- Garanti: Sikrer, at `map`-operationer kan optimeres ved at blive slået sammen.
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
- Monade: Et mere kraftfuldt designmønster for indpakkede værdier.
- Formål: At sekventere/kæde beregninger sammen på en elegant, funktionel måde.
- `bind`: Tager en funktion `a -> M<b>` (en funktion der selv returnerer en indpakket værdi).
- Skal implementere to funktioner: `return` (løfter en værdi) og `bind` (kæder operationer).
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
- `return` (også kaldet `pure`): Tager en normal værdi og pakker den ind i monade-konteksten.
- Løfter en værdi op i den monadiske verden.
- For `Option`-monaden er `return` lig med `Some`-konstruktøren.
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
- `bind`: Hjertet i monaden, kæder operationer sammen.
- Input: En funktion `f` og en indpakket værdi `x`.
- Logik: Pakker værdi ud af `x` (hvis den findes) og giver den til `f`.
- `Option.bind` eksempel:
    - Ved `Some v`: Kalder `f` med `v`.
    - Ved `None`: Returnerer `None` direkte (short-circuit). Perfekt til fejlhåndtering.
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
- Problem: At kæde flere operationer, der kan fejle (returnere `Option`), sammen.
- Imperativ stil: Fører til indlejrede `match`-udtryk.
- "Pyramid of Doom": Koden bliver grim, svær at læse og vedligeholde.
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
- Løsning: Brug `bind` til at skabe en flad, deklarativ pipeline.
- `bind` abstraherer `match`-logikken væk.
- Den håndterer automatisk "short-circuit" ved `None`.
- Lader os fokusere på "happy path".
- F# `computation expressions` (f.eks. `option { ... }`) er syntaktisk sukker for dette mønster.
-->

---
