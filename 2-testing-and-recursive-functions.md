---
title: Testing and recursive functions
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 26px;
  }
---

# Testing & Recursive functions

---

### Recursive functions

- Used alot in functional programming
  - Preferred looping mechanic
- `rec` keyword
- `match` keyword
  - `function` keyword alternative

<!--
- Rekursion: Fundamental i FP, erstatter imperative løkker.
- foretrukken bla pga immutability (ingen mutable i variable)
- `rec` nøgleord: Definerer en funktion som rekursiv.
- `match`: Kraftfuld til pattern matching på f.eks. lister.
- `function`: Syntaktisk sukker for `fun` og `match`.
-->

---

### Recursive functions - example

```fsharp
let rec length lst =
      match lst with
      | [] -> 0
      | _ :: tail -> 1 + length tail

length [42;42;42;] // 3
```

<!--
- Eksempel: `length` funktion for en liste.
- Base case: Tom liste `[]` returnerer 0. Stopper rekursionen.
- Rekursivt kald: Listen deles i hoved (`_`) og hale (`tail`). Returnerer 1 + længden af halen.
-->

---

### Recursive functions - example

```fsharp
let rec length = function
  | [] -> 0
  | _ :: tail -> 1 + length tail

length [42;42;42;] // 3
```

<!--
- Alternativ `length` implementation.
- Bruger `function` keyword for mere kompakt kode.
- Matcher direkte på det implicitte argument.
- Funktionalitet er identisk med forrige eksempel.
-->

---

### Recursive functions - optimization

Tail recursion

- No new stack frame created
- Memory usage

```fsharp
let length list =
  let rec loop acc = function
    | [] -> acc
    | _ :: tail -> loop (acc + 1) tail
  loop 0 list
```

<!--
- Tail recursion (halerekursion) er en vigtig optimering.
- Undgår nye stack frames for hvert rekursivt kald, forhindrer "stack overflow".
- Betingelse: Det rekursive kald skal være den absolut sidste operation.
- Compileren genbruger den nuværende stack frame -> lige så effektiv som en løkke.
- OBS: Forrite `length` er IKKE halerekursiv pga. `1 + ...` operationen _efter_ kaldet.
- En inner function med accumulator kan give tail recursion - arbejdet er gjort i (acc+1)
  -->

---

### Property based testing

- Don't test specifics - test properties!
- FsCheck: generate random test cases
- Example property: `reverse (reverse xs) = xs`
- Nice for testing `rec` functions
<!--
- Test-strategi: Test generelle egenskaber (properties) i stedet for specifikke eksempler.
- Værktøj: FsCheck genererer automatisk hundredvis af tilfældige test cases.
- Formål: At finde modeksempler, der bryder en defineret egenskab.
- Eksempel: `reverse (reverse xs) = xs` skal gælde for _alle_ lister `xs`.
- Velegnet til rekursive funktioner, der opererer på datastrukturer.
  -->

---

### Property based testing - the wrong way

```fsharp
[<Test>]
let ``length of append - manual examples`` () =
    Assert.AreEqual(5, length ([1;2] @ [3;4;5]))
    Assert.AreEqual(3, length ([1] @ [2;3]))
    Assert.AreEqual(0, length ([] @ []))
    // ... how many cases do we need?
```

<!--
- Traditionel, eksempel-baseret testning.
- Udfordring: Hvor mange manuelle eksempler kræves for at dække alle tilfælde?
- Risiko: Man overser nemt edge cases (tomme lister, lange lister etc.).
- Ikke en skalerbar eller grundig metode.
-->

---

### Property based testing - the right way

```fsharp
[<Property>]
let ``length of append`` (xs: int list) (ys: int list) =
    length (xs @ ys) = length xs + length ys
```

<!--
- Den korrekte, property-baserede tilgang.
- Egenskab: For *enhver* to lister `xs` og `ys`, er længden af deres sammenføjning summen af deres længder.
- FsCheck genererer tilfældige lister for at verificere egenskaben.
- Hvis en fejl findes, "skrumper" FsCheck modeksemplet til den simpleste form for lettere debugging.
-->

---

### Property based testing - more examples

```fsharp
[<Property>]
let ``reverse twice is identity`` (xs: int list) =
    reverse (reverse xs) = xs

[<Property>]
let ``reverse preserves length`` (xs: int list) =
    length (reverse xs) = length xs
```

<!--
- Flere eksempler på egenskaber for en `reverse` funktion.
- `reverse twice is identity`: At vende en liste to gange giver den oprindelige liste.
- `reverse preserves length`: Længden af en liste ændres ikke ved vending.
- Fanger essensen af funktionens korrekthed på et abstrakt niveau, uafhængigt af specifikke data.
-->

---
