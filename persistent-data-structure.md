---
title: Persistent Data Structures
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
---

# The what

- Data structures that are immutable
  - Operations does not change the structure
  - Instead it copies the data to a new version
- Data can be shared between versions

---

# The Why

- Immutable structures are thread safe
- Aligns well with idiomatic F#
  - No side effects
- Downside: Uses more memory
  - Can be helped by reusing parts of the old structure

---

# BST

```f#
type BST<'a> =
  | Empty
  | Node of BST<'a> * 'a * BST<'a>
module BST =
  val insert<'a>   : 'a   -> BST<'a> -> BST<'a>
```

![BST example](./img/bst1.png)

---

# BST

![BST example](./img/bst2.png)

---

# Set

- Elements are unique
- Immutable
- Can only hold elements which can be
  - Internally has a tree structure

---

# Set creation

```f#
let s1 = set [1;2;3;4;5]
let s1' = Set.add 6 s1
let s1'' = Set.remove 3 s1
```

Functions are kept pure and side effect free

# Other set methods

```f#
let first = set ["a"; "b"]
let second = set ["c"; "d"]
let third = set ["a"; "d"]

Set.union first second
// val it : Set<string> = set ["a"; "b"; "c"; "d"]
Set.intersect first third
// val it : Set<string> = set ["a"]
Set.difference first third
// val it : Set<string> = set ["b"]
```

---

# Map

---
