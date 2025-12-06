---
title: Applicatives and Functions
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
---

# Applicatives and Functions

---

### Functions - first class citizens

- Functions can be both lower order and higher order
- Functions can have inner functions
- Can be chained together
  - Composition
  - Pipe operator

---

### Functions - lower order

```f#
let square x = x * x
let isEven x = x % 2 = 0

square 4        // 16
isEven 7        // false
```

---

### Functions - higher order

```f#
let applyTwice f a = f (f a)

let multiplyBy n = fun x -> x * n
let double = multiplyBy 2
double 5   // 10
```

---

### Functions - inner functions

```f#
let calculateDiscount price =
    let applyDiscount discount = price * (1.0 - discount)
    if price > 100.0 then applyDiscount 0.2
    else applyDiscount 0.1

calculateDiscount 150.0  // 120.0
```

---

### Functions - Composition

```f#
let addOne x = x + 1
let double x = x * 2

let addOneThenDouble = addOne >> double
addOneThenDouble 3  // 8
```

---

### Functions - Pipe

```f#
// Using |> operator (left to right)
let result =
    [1;2;3;4;5;6]
    |> List.filter (fun x -> x % 2 = 0)   // [2;4;6;]
    |> List.map (fun x -> x * 2)           // [4;8;12;]
    |> List.map (fun x -> string x) // ["4"; "8"; "12";]
```

---

### Applicatives

- Applies wrapped functions to wrapped values
- Needs two functions
  - Pure
  - Apply (<\*>)

---

### Applicatives - The problem

```f#
let add a b = a + b

let x = Some 3
let y = Some 5

// I can't do it captain, I don't have the power!
// let result = add x y
```

---

### Applicatives - The solution

```f#
let apply fOpt xOpt =
    match fOpt, xOpt with
    | Some f, Some x -> Some (f x)
    | _ -> None

let result =
    Some add
    |> apply <| x   // Some (add 3) = Some (fun y -> 3 + y)
    |> apply <| y   // Some 8
```

---

### Applicatives - comparison to functors and monads

- Applicatives sits in between functors and monads
- Functors apply normal functions to wrapped values
  - `Some 5 |> Option.map ((+) 1)  // Some 6`
- Applicatives apply wrapped functions to wrapped values
  - `Some ((+) 1) <*> Some 5  // Some 6`
- Monads apply a function that returns a wrapped value, to a wrapped value
  - `Some 5 |> Option.bind (fun x -> Some (x + 1))  // Some 6`

---
