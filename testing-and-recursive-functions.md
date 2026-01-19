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
Rekursive funktioner er en fundamental del af funktionel programmering. I stedet for at bruge løkker, som vi kender det fra imperativ programmering, bruger vi rekursion til at iterere over datastrukturer.

I F# bruger vi `rec` nøgleordet til at definere en rekursiv funktion.

`match` nøgleordet er en kraftfuld måde at håndtere forskellige cases i en rekursiv funktion. Det er især nyttigt, når vi arbejder med datastrukturer som lister. `function` nøgleordet er en mere kompakt måde at skrive en funktion, der med det samme mønster-matcher på sit argument.
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
Her ser vi et klassisk eksempel på en rekursiv funktion: `length`.

Funktionen tager en liste som input og returnerer længden af listen.

Vi bruger `match` til at håndtere to cases:
1. Hvis listen er tom, returnerer vi 0. Dette er vores base case, som stopper rekursionen.
2. Hvis listen ikke er tom, består den af et hoved (head) og en hale (tail). Vi ignorerer hovedet med `_` og lægger 1 til resultatet af `length` kaldt på halen. Dette er vores rekursive kald.
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
Her ser vi den samme `length` funktion, men skrevet mere kompakt med `function` nøgleordet.

`function` er en sukker-syntaks, der kombinerer `fun` og `match`. I stedet for at navngive argumentet og derefter matche på det, kan vi matche direkte på det implicitte argument.

Funktionaliteten er præcis den samme som i det forrige eksempel, men koden er mere koncis.
-->

---

### Recursive functions - optimization

Tail recursion

- No new stack frame created
- Memory usage

<!--
En vigtig optimering for rekursive funktioner er tail recursion, eller halerekursion.

Normalt, når en funktion kalder sig selv, bliver der oprettet en ny stack frame for hvert kald. Det kan føre til et "stack overflow", hvis rekursionen er for dyb.

Ved halerekursion er det rekursive kald det absolut sidste, der sker i funktionen. Der er ingen yderligere operationer efter det rekursive kald, som f.eks. `1 + ...`.

Når en funktion er halerekursiv, kan compileren optimere den, så den ikke bruger ekstra plads på stacken for hvert rekursive kald. I stedet genbruger den den nuværende stack frame. Det gør funktionen lige så effektiv som en iterativ løkke. Vores `length` funktion er _ikke_ halerekursiv, fordi `1 +` operationen sker _efter_ det rekursive kald.
-->

---

### Property based testing

- Don't test specifics - test properties!
- FsCheck: generate random test cases
- Example property: `reverse (reverse xs) = xs`
- Nice for testing `rec` functions

<!--
Nu skal vi se på, hvordan vi kan teste vores rekursive funktioner. Traditionel testning involverer at skrive specifikke eksempler. Property-based testing er en anden tilgang.

I stedet for at teste for specifikke input og output, tester vi for generelle _egenskaber_ (properties), som vores funktioner skal overholde for _alle_ mulige inputs.

Vi bruger et bibliotek som FsCheck til at generere hundredvis af tilfældige test-cases for os. Vi definerer en egenskab, og FsCheck forsøger at finde et modeksempel, der falsificerer den.

Et klassisk eksempel er, at hvis man vender en liste to gange, får man den oprindelige liste tilbage. Denne egenskab skal gælde for _enhver_ liste.

Dette er en meget kraftfuld måde at teste rekursive funktioner på, da de ofte opererer på datastrukturer, hvor sådanne generelle egenskaber kan formuleres.
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
Her er et eksempel på, hvordan vi *ikke* skal gøre det, hvis vi vil være grundige. Dette er traditionel, eksempel-baseret testning.

Vi tester `length` funktionen i kombination med liste-konkatenering (`@`). Vi skriver et par manuelle eksempler.

Problemet er: hvor mange eksempler skal vi skrive for at være sikre på, at vores kode er korrekt? Vi kan nemt overse edge cases, som f.eks. tomme lister, lister med ét element, meget lange lister osv. Det er svært at dække alle muligheder.
-->

---

### Property based testing - the right way

```fsharp
[<Property>]
let ``length of append`` (xs: int list) (ys: int list) =
    length (xs @ ys) = length xs + length ys
```

<!--
Her er den rigtige måde at gøre det på med property-based testing.

Vi definerer en egenskab: for *enhver* liste `xs` og *enhver* liste `ys`, skal længden af deres konkatenering være lig med summen af deres individuelle længder.

FsCheck vil nu generere tilfældige lister `xs` og `ys` af forskellige længder og med forskelligt indhold og tjekke, om denne egenskab holder.

Hvis FsCheck finder et modeksempel, vil den rapportere det til os, og endda forsøge at "skrumpe" eksemplet til den simplest mulige version, der stadig fejler, hvilket gør det nemmere at debugge.
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
Her er et par flere eksempler på egenskaber for en hypotetisk `reverse` funktion.

Den første egenskab, `reverse twice is identity`, er en klassiker. Hvis vi vender en liste og derefter vender den igen, skal vi have den oprindelige liste tilbage.

Den anden egenskab, `reverse preserves length`, siger, at vending af en liste ikke ændrer dens længde.

Disse egenskaber fanger essensen af, hvad `reverse` funktionen skal gøre, uden at vi behøver at bekymre os om specifikke værdier i listen. Det er en meget mere abstrakt og kraftfuld måde at specificere og teste korrekthed på.
-->

