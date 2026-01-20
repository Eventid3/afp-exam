---
title: Persistent Data Structures
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 26px;
  }
---

# Persistent Data Structures

---

# The What

- Data structures that are immutable
  - Operations does not change the structure
  - Instead it copies the data to a new version
- Data can be shared between versions

<!--
- Definition: En datastruktur, der bevarer sin gamle version ved ændringer. Den er immutable.
- Operationer: I stedet for at mutere, skabes en ny version med ændringen.
- Effektivitet: "Structural sharing" gør det effektivt ved at genbruge uændrede dele af den gamle struktur.
-->

---

# The Why

- Immutable structures are thread safe
- Aligns well with idiomatic F#
  - No side effects
- Downside: Uses more memory
  - Can be helped by reusing parts of the old structure

<!--
- Trådsikkerhed: Data er uforanderlige, så ingen låse er nødvendige for samtidige læsninger.
- Funktionel stil: Passer perfekt med rene funktioner uden side-effekter.
- Ulempe: Potentielt højere hukommelsesforbrug.
- Løsning: Structural sharing minimerer hukommelsespresset.
-->

---

# BST

```fsharp
type BST<'a> =
  | Empty
  | Node of BST<'a> * 'a * BST<'a>
module BST =
  val insert<'a>   : 'a   -> BST<'a> -> BST<'a>
```

![height:400px](img/bst1.png)

<!--
- Eksempel: Binært søgetræ (BST) er en klassisk persistent datastruktur.
- Definition: Rekursiv type, enten `Empty` eller en `Node` med værdi og to sub-træer.
- Operation: `insert` ændrer ikke det oprindelige træ, men returnerer et nyt.
-->

---

### BST

![BST example](./img/bst2.png)

<!--
- Visualisering af `insert 11`.
- Princip: Kun stien ned til ændringen kopieres. Resten af træet genbruges.
- Grå noder: Genbrugt fra det oprindelige træ.
- Sorte noder: Nye kopier, der danner den nye version af træet.
- Resultat: To separate træ-rødder, der deler fælles data (structural sharing).
-->

---

### Set

```fsharp
type Set<'a>
```

- Elements are unique
- Immutable
- Can only hold elements which can be ordered
  - Internally has a tree structure

<!--
- `Set`: F#'s indbyggede, persistente mængde-datastruktur.
- Egenskaber: Unikke, sorterede elementer. Immutable.
- Implementation: Baseret på et balanceret binært søgetræ (f.eks. AVL-træ) for effektivitet.
-->

---

### Set creation

```fsharp
let s1 = set [1;2;3;4;5]
let s1' = Set.add 6 s1
let s1'' = Set.remove 3 s1
```

- Functions are kept pure and side effect free

<!--
- `Set.add` og `Set.remove` muterer ikke det oprindelige set.
- Hver operation returnerer en _ny_ instans af settet med ændringen.
- `s1` forbliver uændret.
- Alle funktioner er rene og uden side-effekter.
-->

---

### Other set functions

```fsharp
let first = set [1; 2]
let second = set [3; 4]
let third = set [1; 4]

Set.union first second
// val it : Set<string> = set [1; 2; 3; 4;]
Set.intersect first third
// val it : Set<string> = set [1]
Set.difference first third
// val it : Set<string> = set [2]
```

- All the functions from list also work: map, filter, fold and foldBack
<!--
- Klassiske mængdeoperationer: `union`, `intersect`, `difference`.
- Højere-ordens funktioner: Understøtter `map`, `filter`, `fold` ligesom lister.
  -->

---

### Map

```fsharp
type Map<'a,'b>
```

- Key/value pairs
- Keys are unique
- Immutable
- Keys also required to be sortable
  - Internally a tree structure

<!--
- `Map`: Persistent key-value store (dictionary).
- Egenskaber: Unikke, sorterbare nøgler. Immutable.
- Implementation: Også baseret på et balanceret søgetræ for effektiv (logaritmisk) adgang.
-->

---

### Map functions

```fsharp
let m1 = Map.ofList [("k1", 1); ("k2", 2); ("k3", 3), ("k4", 4)]
let m2 = Map.add "k5" 5 m1
let m3 = Map.remove "k1" m1
```

<!--
- Ligner `Set`: `Map.add` og `Map.remove` returnerer nye maps.
- `m1` forbliver uændret.
- `Map.add` opdaterer værdien, hvis nøglen allerede eksisterer (i den nye map).
-->

---

### Sequence

- Lazy evaluated
- Possibly infinite
- Can be initiated with a `int -> 'a` function

```fsharp
let x = Seq.initInfinite (fun i -> i)
```

<!--
- `Seq`: F#'s "dovent evalueret" (lazy) sekvens, svarer til .NET `IEnumerable<T>`.
- Egenskab: Elementer beregnes kun, når der anmodes om dem.
- Muliggør repræsentation af uendelige datastrukturer.
- `Seq.initInfinite`: Skaber en uendelig sekvens. Ingen værdier er beregnet endnu.
-->

---

### Sequence

```fsharp
let e5 = Seq.item 5 x
```

- Only evaluates the 5th element
- Will evaluate at each call.
<!--
- Adgang: `Seq.item 5` trigger beregningen af elementerne 0 til 5.
- Genberegning: Standard-sekvenser genberegner værdierne ved _hver_ iteration.
  -->

---

### Sequence caching

```fsharp
let cachedX = Seq.cache x
let e5 = Seq.item 5 cachedX
```

- Evaluates and caches all elements from 0-5

<!--
- `Seq.cache`: Optimerer dyre beregninger ved at gemme (cache) allerede beregnede værdier.
- Første adgang: Beregner og cacher værdierne.
- Efterfølgende adgang: Returnerer værdier direkte fra cachen.
- Kombinerer fordelene ved lazy evaluation og effektiv gen-adgang.
-->

---
