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
- "First-class citizens": Funktioner kan behandles som enhver anden værdi (int, string etc.).
- Kan gemmes i variable, sendes som argumenter, og returneres fra andre funktioner.
- Kan kædes sammen med komposition (`>>`) og pipe (`|>`).
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
- Lower-order: Basale funktioner, der opererer på simple data (ikke på andre funktioner).
- Fundamentale byggeklodser.
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
- Higher-order: Funktioner, der tager funktioner som input eller returnerer en funktion.
- `applyTwice`: Tager funktion `f` som argument.
- `multiplyBy`: Returnerer en ny funktion. Dette kaldes en 'closure' - den husker værdien `n`.
- Giver genbrugelig og konfigurerbar kode.
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
- Indre funktioner: Defineres inde i andre funktioner for at opdele logik.
- Forurener ikke det ydre scope.
- `applyDiscount` er en 'closure', da den "fanger" `price` fra den ydre funktion.
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
- Funktionskomposition (`>>`): Kobler to funktioner sammen til én ny funktion.
- `f >> g`: Output fra `f` bliver automatisk input til `g`.
- Deklarativ måde at udtrykke en sekvens af transformationer.
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
- Pipe-operator (`|>`): Sender en værdi gennem en pipeline af funktioner.
- Værdien til venstre bliver det *sidste* argument til funktionen til højre.
- Meget læsbart (top-til-bund). Undgår indlejrede kald.
- God til at transformere en konkret datastrøm.
-->

---

### Applicatives

- Applies wrapped functions to wrapped values
- Needs two functions
  - Pure
  - Apply (<\*>)

<!--
- Applicative Functor: Designmønster for "indpakkede" værdier (`Option`, `List` etc.).
- Unik egenskab: Anvender en _indpakket funktion_ på en _indpakket værdi_.
- Krav: Skal have to funktioner: 1. `pure`: Pakker en normal værdi ind (for `Option` er det `Some`). 2. `apply` (ofte `<*>`): Tager indpakket funktion og indpakket værdi, returnerer ny indpakket værdi.
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
- Problem: Hvordan anvender man en normal funktion med flere argumenter (f.eks. `add`) på indpakkede værdier (`Option`)?
- `add x y` fejler, da den forventer `int`, ikke `int option`.
- `Option.map` virker kun med funktioner, der tager ét argument.
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
- Løsning: `apply`-funktionen.
- Trin 1: Løft `add` funktionen ind i konteksten: `Some add`.
- Trin 2: `apply` den første værdi (`Some 3`). Pga. currying returneres en indpakket funktion: `Some (fun y -> 3 + y)`.
- Trin 3: `apply` den anden værdi (`Some 5`). Resultatet er `Some 8`.
- Hvis en værdi var `None`, ville `apply` kortslutte og returnere `None`.
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
- **Funktor (`map`):** (Normal funktion) -> (Indpakket værdi) -> (Indpakket værdi)
- **Applicative (`<*>`):** (Indpakket funktion) -> (Indpakket værdi) -> (Indpakket værdi). Mere kraftfuld end `map`.
- **Monade (`bind`):** (Funktion, der returnerer indpakket værdi) -> (Indpakket værdi) -> (Indpakket værdi). Mest kraftfuld, tillader dynamisk kædning.
- Hierarki: Alle monader er applicatives, alle applicatives er funktorer.
-->

---
