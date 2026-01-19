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

### Functors

- A design pattern that alters nested values
- The structure is kept
- Typically called a 'map' function:

```f#
List.map: ('a -> 'b) -> list<'a> -> list<'b>
```

---

### Functor laws

- Using the identity function should results in the same data

```f#
List.map (fun i -> i) [1; 2; 3;]
// [1; 2; 3;]
```

---

### Functor laws

- A sequence of mapper functions should give the same result as function composition

```f#
let f x = x * 2
let g x = x + 1
[1;2;3;] |> List.map f |> List.map g
// val it: int list = [3; 5; 7]
[1;2;3;] |> List.map (f >> g)
// val it: int list = [3; 5; 7]
```

---

### Monads

- Functional design pattern
- Applies a function to a wrapped value, and returns a wrapped value
- Exists to avoid imperative style programming
- Must implement return and bind functions

```f#
val return': 'a -> M<'a>
val bind: ('a -> M<'b>) -> M<'a> -> M<'b>
```

---

### Monads - return

Return is just implemented as a type constructor
The Option type is a monad

```f#
let x = Some 1
let y = None
```

---

### Monads - bind

```f#
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

---

### Monads - the problem

```f#
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

---

### Monads - the monadic solution

```f#
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

---
