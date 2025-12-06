---
title: Monoids and Model/type-based Programming
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
---

# Monoids and Model/type-based Programming

---

### Monoids

- Simple construct with the following definition
  - A type with an associative binary operation
  - and an identity element
- Operation could be +, \* or an append function
- Identity element could be 0, an empty string or an empty list

---

### Monoids - laws

```f#
// associativity
(a ⊕ b) ⊕ c = a ⊕ (b ⊕ c)

// identity
i ⊕ a = a
a ⊕ i = a
```

---

### Monoids - example

```f#
let append = (@)
let empty = []

// Laws
([1] @ [2]) @ [3] = [1] @ ([2] @ [3])

[] @ [1; 2] = [1; 2]                    // left identity
[1; 2] @ [] = [1; 2]                    // right identity
```

---

### Monoids in practice

```f#
// all returns list<User>
let results = [
    fetchFromDB()
    fetchFromCache()
    fetchFromAPI()
]

let allUsers = List.fold (@) [] results
```

Monoids helps us to so safe combining

---

### Model/type-based programming

- What programming/rules can we handle in the type?
- Make illegal states not happen
- Encode domain rules in types
- Domain Driven Design

---

### Email example

```f#
// bad
type EmailAddress = string

// good
type EmailAddress = private EmailAddress of string
module EmailAddress =
    let create (s: string) =
        if s.Contains("@") && s.Length > 3
        then Some (EmailAddress s)
        else None
```

---

### Descriminated Unions

```f#
type PaymentStatus =
    | Unpaid
    | PartiallyPaid of amountPaid: decimal
    | FullyPaid of paidDate: DateTime
    | Refunded of refundDate: DateTime * reason: string

// Pattern matching ensures all cases are handled
let getStatus payment =
    match payment with
    | Unpaid -> "Awaiting payment"
    | PartiallyPaid amt -> $"Paid {amt}"
    | FullyPaid date -> $"Completed on {date}"
    | Refunded (date, reason) -> $"Refunded: {reason}"
```

---

### Single Case Unions

```f#
type CustomerId = CustomerId of int
type OrderId = OrderId of int
type ProductId = ProductId of int

let findCustomer (CustomerId id) = // ...
let findOrder (OrderId id) = // ...

// error!
findCustomer (OrderId 123)
```

---

### Active Patterns

```f#
let (|Even|Odd|) (num: int) =
    if (num % 2 = 0) then
        Even
    else Odd
// val (|Even|Odd|) : num: int -> Choice<unit,unit>

match 3 with
| Even -> printfn "3 is even"
| Odd -> printfn "3 is odd"
// outputs: 3 is odd
```

Source: AFP slides

---

### Conclusion

- Monoids provide operations with guarantees
- Type-base programming enforces domain rules

- Together:
  - Safe data composition
  - Invalid states impossible
  - Readable domain models
  - Compiler enforced checks
