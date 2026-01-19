---
title: Applicatives and Functions
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 26px;
  }
---

# Applicatives and Functions

---

### Functions - first class citizens

- Functions can be both lower order and higher order
- Functions can have inner functions
- Can be chained together
  - Composition
  - Pipe operator
  <!--
  I F#, og i de fleste funktionelle sprog, er funktioner "first-class citizens". Det betyder, at de kan behandles ligesom enhver anden værdi, f.eks. et heltal eller en streng.

De kan gemmes i variable, sendes som argumenter til andre funktioner (hvilket giver os højere-ordens funktioner), og returneres som resultater fra andre funktioner.

Vi kan definere funktioner inde i andre funktioner, og vi kan koble dem sammen elegant ved hjælp af komposition og pipe-operatoren. Lad os se på et par eksempler.
-->

---

### Functions - lower order

```fsharp
let square x = x * x
let isEven x = x % 2 = 0

square 4        // 16
isEven 7        // false
```

<!--
Her er de mest basale funktioner. De kaldes "lower-order" fordi de kun opererer på simple data, ikke på andre funktioner.

`square` tager et tal og returnerer dets kvadrat. `isEven` tager et tal og returnerer en boolean. Simpelt og ligetil. Det er de byggeklodser, vi bruger til at bygge mere komplekse funktioner.
-->

---

### Functions - higher order

```fsharp
let applyTwice f a = f (f a)

let multiplyBy n = fun x -> x * n
let double = multiplyBy 2
double 5   // 10
```

<!--
Her bliver det mere interessant. En højere-ordens funktion er en funktion, der enten tager en anden funktion som argument, eller returnerer en funktion som resultat.

`applyTwice` er et eksempel på det første. Den tager en funktion `f` og en værdi `a`, og anvender `f` to gange på `a`.

`multiplyBy` er et eksempel på det andet. Den tager et tal `n` og returnerer en *ny funktion*. Denne nye funktion tager et tal `x` og ganger det med det `n`, som `multiplyBy` "huskede". Dette kaldes en closure.

Ved at kalde `multiplyBy 2` skaber vi en ny funktion, `double`, som er specialiseret til at gange med 2. Dette er en kraftfuld teknik til at skabe genbrugelig og konfigurerbar kode.
-->

---

### Functions - inner functions

```fsharp
let calculateDiscount price =
    let applyDiscount discount = price * (1.0 - discount)
    if price > 100.0 then applyDiscount 0.2
    else applyDiscount 0.1

calculateDiscount 150.0  // 120.0
```

<!--
Vi kan definere funktioner inde i andre funktioner for at opdele logik og undgå at "forurene" det ydre scope med hjælpefunktioner, der kun bruges lokalt.

Her er `applyDiscount` en indre funktion. Bemærk, at den har adgang til `price`-parameteren fra den ydre funktion. Dette er igen et eksempel på en closure. Den "fanger" variabler fra sit omkringliggende miljø.

Dette gør koden mere modulær og læsbar.
-->

---

### Functions - Composition

```fsharp
let addOne x = x + 1
let double x = x * 2

let addOneThenDouble = addOne >> double
addOneThenDouble 3  // 8
```

<!--
Funktionskomposition er en af de mest elegante måder at bygge nye funktioner på. `>>` operatoren lader os koble to funktioner sammen til en ny funktion.

`addOne >> double` skaber en ny funktion, `addOneThenDouble`. Når denne funktion kaldes med et input (f.eks. 3), bliver inputtet først sendt gennem `addOne` (3+1=4), og resultatet af det bliver *automatisk* sendt videre som input til `double` (4*2=8).

Det er en meget deklarativ måde at udtrykke en sekvens af datatransformationer på.
-->

---

### Functions - Pipe

```fsharp
// Using |> operator (left to right)
let result =
    [1;2;3;4;5;6]
    |> List.filter (fun x -> x % 2 = 0)   // [2;4;6;]
    |> List.map (fun x -> x * 2)           // [4;8;12;]
    |> List.map (fun x -> string x) // ["4"; "8"; "12";]
```

<!--
Pipe-operatoren `|>` er en anden måde at opnå en sekvens af operationer på. I stedet for at bygge en ny, navngiven funktion, lader den os sende en værdi gennem en pipeline af funktioner.

Værdien på venstre side af `|>` bliver sendt som det *sidste* argument til funktionen på højre side.

Dette er ekstremt læsbart, da det læses fra top til bund, og det undgår en masse parenteser og indlejrede funktionskald. Man starter med data og transformerer dem trin for trin. Mange foretrækker pipe-operatoren frem for komposition, når de arbejder med en konkret datastrøm.
-->

---

### Applicatives

- Applies wrapped functions to wrapped values
- Needs two functions
  - Pure
  - Apply (<\*>)
  <!--
  Nu til Applicatives, eller mere formelt, Applicative Functors.

En applicative er et designmønster, der, ligesom funktorer og monader, arbejder med "indpakkede" værdier (f.eks. `Option`, `List`, `Async`).

Det unikke ved applicatives er, at de lader os anvende en _indpakket funktion_ på en _indpakket værdi_.

For at en type kan være en applicative, skal den have to funktioner:

1. `pure` (svarer til `return` i monader): Tager en normal værdi og pakker den ind. For `Option` er det `Some`.
2. `apply` (ofte skrevet som en operator `<*>`): Tager en indpakket funktion og en indpakket værdi, og returnerer en ny indpakket værdi.
   -->

---

### Applicatives - The problem

```fsharp
let add a b = a + b

let x = Some 3
let y = Some 5

// I can't do it captain, I don't have the power!
// let result = add x y
```

<!--
For at forstå, hvorfor vi har brug for applicatives, lad os se på et problem.

Vi har en simpel `add` funktion, der tager to heltal. Men hvad nu hvis vores heltal er pakket ind i en `Option`? Vi kan ikke bare kalde `add x y`. F# compileren vil brokke sig, fordi `add` forventer `int`, ikke `int option`.

Vi kunne bruge `Option.map`, men `map` virker kun på funktioner, der tager ét argument. `add` tager to. Hvordan får vi løftet en funktion med flere argumenter ind i `Option`-konteksten?
-->

---

### Applicatives - The solution

```fsharp
let apply fOpt xOpt =
    match fOpt, xOpt with
    | Some f, Some x -> Some (f x)
    | _ -> None

let result =
    Some add
    |> apply <| x   // Some (add 3) = Some (fun y -> 3 + y)
    |> apply <| y   // Some 8
```

<!--
Dette er løsningen med applicative-mønsteret. Her har vi implementeret `apply` manuelt for `Option`.

Først løfter vi `add`-funktionen ind i `Option`-konteksten med `Some`, så vi har `Some add`.

Derefter bruger vi `apply` (her med `|>` og `<|` for at gøre det klart, hvad der sker).
1. `Some add |> apply <| Some 3`: `apply` pakker `add` og `3` ud. Den anvender `3` som det *første* argument til `add`. På grund af currying er resultatet en ny funktion `fun y -> 3 + y`. `apply` pakker denne nye funktion ind igen, så vi har `Some (fun y -> 3 + y)`.
2. Dette resultat pipes videre: `Some (fun y -> 3 + y) |> apply <| Some 5`: `apply` pakker funktionen og `5` ud, anvender `5` på funktionen, får `8`, og pakker det ind igen.

Slutresultatet er `Some 8`. Vi har succesfuldt anvendt en 2-arguments funktion på to `Option` værdier. Hvis enten `x` eller `y` havde været `None`, ville `apply` have kortsluttet og returneret `None`.
-->

---

### Applicatives - comparison to functors and monads

- Applicatives sits in between functors and monads
- Functors apply normal functions to wrapped values
  - `Some 5 |> Option.map ((+) 1)  // Some 6`
- Applicatives apply wrapped functions to wrapped values
  - `Some ((+) 1) <*> Some 5  // Some 6`
- Monads apply a function that returns a wrapped value, to a wrapped value
  - `Some 5 |> Option.bind (fun x -> Some (x + 1))  // Some 6`
  <!--
  For at sætte det hele i perspektiv:

- **Funktor (`map`):** Du har en _normal_ funktion (`(+) 1`) og en indpakket værdi (`Some 5`). `map` anvender funktionen på værdien inde i pakken.

- **Applicative (`<*>`):** Du har en _indpakket_ funktion (`Some ((+) 1)`) og en indpakket værdi (`Some 5`). `apply` anvender den indpakkede funktion på den indpakkede værdi. Dette er mere kraftfuldt end `map`, da det lader os arbejde med funktioner med flere argumenter.

- **Monade (`bind`):** Du har en _normal_ funktion, der _returnerer en indpakket værdi_ (`fun x -> Some (x + 1)`), og en indpakket værdi (`Some 5`). `bind` lader dig kæde operationer sammen, hvor hver operation kan fejle eller have en kontekst. Dette er det mest kraftfulde af de tre, da resultatet af en beregning kan påvirke, _hvilken_ beregning der kommer bagefter.

Alle monader er applicatives, og alle applicatives er funktorer. De er lag af stigende abstraktion og kraft.
-->

---

