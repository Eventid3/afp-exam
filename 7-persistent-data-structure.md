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
Hvad er en persistent datastruktur?

Det er en datastruktur, der altid bevarer (persisterer) sin tidligere version, når den bliver modificeret. Med andre ord er den _immutable_ eller uforanderlig.

Når vi udfører en operation, som f.eks. at tilføje et element, ændrer vi ikke på den oprindelige struktur. I stedet skabes der en ny version af strukturen, der indeholder ændringen.

Det smarte er, at vi ikke behøver at kopiere hele datastrukturen hver gang. Den nye version kan genbruge store dele af den gamle version. Dette kaldes "structural sharing" og er nøglen til at gøre dem effektive.
-->

---

# The Why

- Immutable structures are thread safe
- Aligns well with idiomatic F#
  - No side effects
- Downside: Uses more memory
  - Can be helped by reusing parts of the old structure
  <!--
  Hvorfor er dette en god idé?

Først og fremmest: Trådsikkerhed. Fordi data aldrig ændres, kan flere tråde læse fra den samme datastruktur samtidigt uden risiko for race conditions. Der er ikke behov for låse.

Det passer perfekt med den funktionelle programmeringsstil, hvor vi stræber efter rene funktioner uden side-effekter. En funktion, der tager en persistent datastruktur og returnerer en ny, er per definition en ren funktion.

Ulempen kan være et højere hukommelsesforbrug, da vi skaber nye objekter i stedet for at ændre de eksisterende. Men som nævnt hjælper "structural sharing" med at minimere dette problem betydeligt.
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

![height:200px](img/bst1.png)

<!--
Et klassisk eksempel på en persistent datastruktur er et binært søgetræ (BST).

Vi kan definere det rekursivt i F# som enten `Empty` eller en `Node`, der har en værdi og to sub-træer (venstre og højre).

En `insert`-funktion vil ikke ændre det eksisterende træ. Den vil returnere et *nyt* træ, der indeholder det nye element.

Billedet viser et simpelt træ. Lad os se, hvad der sker, når vi indsætter et element.
-->

---

### BST

![BST example](./img/bst2.png)

<!--
Her ser vi, hvad der sker, når vi indsætter værdien '7' i træet.

Vi ændrer ikke de eksisterende noder. I stedet skaber vi en ny sti af noder fra roden ned til det sted, hvor '7' skal indsættes.

De grå noder er fra det oprindelige træ. De genbruges fuldstændigt. Kun de sorte noder (`8` og `6`) er nye kopier, der peger på de nye eller gamle noder. Den nye node `7` bliver tilføjet.

Resultatet er to separate træer, der deler en stor del af deres data (noderne 1, 3, 4 og 13). Dette er structural sharing i praksis.
-->

---

### Set

```fsharp
type Set<'a,'b>
```

<!-- Mistake in slide, should be type Set<'a> -->

- Elements are unique
- Immutable
- Can only hold elements which can be ordered
  - Internally has a tree structure
  <!--
  Lad os kigge på F#'s indbyggede `Set`. Et Set er en samling af unikke elementer.

Det er en fuldt ud persistent (immutable) datastruktur.

For at et `Set` kan fungere effektivt, kræver det, at elementerne kan sammenlignes og sorteres. Det er fordi `Set` internt er implementeret som en form for balanceret binært søgetræ (typisk et AVL-træ), meget lig det BST vi lige så. Dette giver hurtig adgang, indsættelse og sletning.
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
Her ser vi, hvordan vi arbejder med `Set`.

Vi kan oprette et `Set` fra en liste med `set`-funktionen.

Når vi kalder `Set.add 6 s1`, ændrer vi _ikke_ `s1`. I stedet returnerer `Set.add` et helt nyt set, `s1'`, som indeholder `6`. `s1` er stadig `[1;2;3;4;5]`.

Det samme gælder `Set.remove`. `s1''` er et nyt set uden `3`, mens `s1` er uændret.

Alle disse funktioner er rene og har ingen side-effekter, hvilket er kernen i funktionel programmering.
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

- All the functions from list also work: map, filter, fold and foldBack
```

<!--
`Set` understøtter alle de klassiske mængdeoperationer:

-   `union` giver foreningsmængden (alle elementer fra begge sets).
-   `intersect` giver snitmængden (kun de elementer, der findes i begge sets).
-   `difference` giver differensmængden (elementer fra det første set, som ikke er i det andet).

Og ligesom lister, understøtter `Set` også de velkendte højere-ordens funktioner som `map`, `filter` og `fold`, hvilket gør dem meget alsidige til databehandling.
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
  Den næste vigtige datastruktur er `Map`. En `Map` er en samling af nøgle-værdi par, også kendt som en dictionary eller en associativ tabel.

Ligesom `Set`, er `Map` i F# en persistent datastruktur. Nøglerne i en map skal være unikke.

Og ligesom `Set` kræver `Map`, at nøglerne kan sammenlignes, fordi den internt også er implementeret som et balanceret søgetræ. Dette sikrer, at opslag, indsættelse og sletning af nøgler er meget effektivt (logaritmisk tid).
-->

---

### Map functions

```fsharp
let m1 = Map.ofList [("k1", 1); ("k2", 2); ("k3", 3), ("k4", 4)]
let m2 = Map.add "k5" 5 m1
let m3 = Map.remove "k1" m1
```

<!--
At arbejde med `Map` ligner meget at arbejde med `Set`.

Vi kan oprette en `Map` fra en liste af tupler.

`Map.add` returnerer en ny map med den tilføjede nøgle-værdi par. Hvis nøglen allerede eksisterer, bliver den gamle værdi overskrevet i den nye map.

`Map.remove` returnerer en ny map uden den specificerede nøgle.

Igen, den oprindelige map `m1` forbliver fuldstændig uændret gennem disse operationer.
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
Til sidst har vi `Seq`, eller sekvenser. En sekvens er F#'s version af `IEnumerable<T>` fra .NET.

Den afgørende egenskab ved sekvenser er, at de er *lazy evaluated* eller "dovent evalueret". Det betyder, at elementerne i en sekvens kun bliver beregnet, når der er brug for dem.

Dette gør det muligt at repræsentere potentielt *uendelige* datastrukturer. Her opretter vi en uendelig sekvens af heltal: 0, 1, 2, 3, ... ved hjælp af `Seq.initInfinite`. Funktionen `fun i -> i` bliver kaldt for at generere hvert element. Indtil videre er ingen værdier blevet beregnet.
-->

---

### Sequence

```fsharp
let e5 = Seq.item 5 x
```

Only evaluates the 5th element
Will evaluate at each call.

<!--
Når vi så beder om et specifikt element, f.eks. det 5. element (med `Seq.item 5`), vil sekvensen evaluere de nødvendige elementer. I de fleste simple implementationer vil den kalde vores `init`-funktion for index 0, 1, 2, 3, 4 og til sidst 5, og så returnere resultatet.

En vigtig detalje ved almindelige sekvenser er, at de som udgangspunkt genberegner værdierne *hver* gang, du itererer over dem. Hvis du kalder `Seq.item 5 x` igen, vil den lave beregningen forfra.
-->

---

### Sequence caching

```fsharp
let cachedX = Seq.cache x
let e5 = Seq.item 5 cachedX
```

Evaluates and caches all elements from 0-5

<!--
Hvis beregningen af elementerne er dyr, og vi har brug for at tilgå dem flere gange, kan denne genberegning være ineffektiv.

Her kommer `Seq.cache` til undsætning. `Seq.cache` tager en sekvens og returnerer en ny sekvens, der husker (cacher) de værdier, der allerede er blevet beregnet.

Første gang vi kalder `Seq.item 5 cachedX`, bliver elementerne 0 til 5 beregnet og gemt. Næste gang vi beder om `Seq.item 3`, vil den blive returneret øjeblikkeligt fra cachen uden genberegning. Dette giver os "lazy evaluation" første gang, og effektiv adgang efterfølgende.
-->

