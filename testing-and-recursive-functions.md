---
title: Testing and recursive functions
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
---

# Testing & Recursive functions

---

### Recursive functions

- Used alot in functional programming
  - Preferred looping mechanic
- `rec` keyword
- `match` keyword
  - `function` keyword alternative

---

### Recursive functions - example

```f#
let rec length lst =
      match lst with
      | [] -> 0
      | _ :: tail -> 1 + length tail

length [42;42;42;] // 3
```

---

### Recursive functions - example

```f#
let rec length = function
  | [] -> 0
  | _ :: tail -> 1 + length tail

length [42;42;42;] // 3
```

---

### Recursive functions - optimization

Tail recursion

- No new stack frame created
- Memory usage

---

### Property based testing

- Don't test specifics - test properties!
- FsCheck: generate random test cases
- Example property: `reverse (reverse xs) = xs`
- Nice for testing `rec` functions

---

### Property based testing - the wrong way

```f#
[<Test>]
let ``length of append - manual examples`` () =
    Assert.AreEqual(5, length ([1;2] @ [3;4;5]))
    Assert.AreEqual(3, length ([1] @ [2;3]))
    Assert.AreEqual(0, length ([] @ []))
    // ... how many cases do we need?
```

---

### Property based testing - the right way

```f#
[<Property>]
let ``length of append`` (xs: int list) (ys: int list) =
    length (xs @ ys) = length xs + length ys
```

---

### Property based testing - more examples

```f#
[<Property>]
let ``reverse twice is identity`` (xs: int list) =
    reverse (reverse xs) = xs

[<Property>]
let ``reverse preserves length`` (xs: int list) =
    length (reverse xs) = length xs
```
