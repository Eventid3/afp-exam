---
title: Monoids and Model/type-based Programming
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 26px;
  }
---

# Monoids and Model/type-based Programming
<!-- Emne: Monoider og Type-baseret programmering. To koncepter, der giver sikker, robust og udtryksfuld kode. -->
---

### Monoids

- Simple construct with the following definition
  - A type with an associative binary operation
  - and an identity element
- Operation could be +, * or an append function
- Identity element could be 0, an empty string or an empty list
<!-- 
- Definition: En type med en binær, associativ operation og et identitetselement.
- Eksempler (operation): +, *, append.
- Eksempler (identitet): 0, 1, "", [].
- Identitetselementet ændrer ikke andre elementer ved operationen.
-->
---

### Monoids - laws

```fsharp
// associativity
(a ⊕ b) ⊕ c = a ⊕ (b ⊕ c)

// identity
i ⊕ a = a
a ⊕ i = a
```
<!--
- To love skal overholdes.
- **Associativitet**: Operationsrækkefølgen er ligegyldig. `(a+b)+c = a+(b+c)`. Vigtigt for parallelisering.
- **Identitet**: Kombination med identitetselementet `i` ændrer intet.
-->
---

### Monoids - example

```fsharp
let append = (@)
let empty = []

// Laws
([1] @ [2]) @ [3] = [1] @ ([2] @ [3])

[] @ [1; 2] = [1; 2]                    // left identity
[1; 2] @ [] = [1; 2]                    // right identity
```
<!--
- Eksempel: F# lister.
- Type: `list<'a>`.
- Operation: `append` (@).
- Identitet: `[]` (tom liste).
- Lovene for associativitet og identitet holder. Derfor danner lister en monoid.
-->
---

### Monoids in practice

```fsharp
// all returns list<User>
let results = [
    fetchFromDB()
    fetchFromCache()
    fetchFromAPI()
]

let allUsers = List.fold (@) [] results
```
- Monoids helps us to so safe combining
<!--
- Praktisk anvendelse: Sikker kombination af data.
- Eksempel: Samling af resultater (brugerlister) fra flere kilder (DB, cache, API).
- `List.fold` med monoidens operation (`@`) og identitet (`[]`) kombinerer sikkert resultaterne.
- Associativitet tillader parallelisering: resultater kan kombineres i vilkårlig rækkefølge.
-->
---

### Model/type-based programming

- What programming/rules can we handle in the type?
- Make illegal states not happen
- Encode domain rules in types
- Domain Driven Design
<!-- 
- Tilgang: Brug typesystemet til at modellere domænet præcist.
- Mål: Gør ulovlige tilstande umulige at repræsentere i typerne.
- Princip: Indkod forretningsregler direkte i typerne.
- Relateret til: Domain-Driven Design (DDD).
-->
---

### Email example

```fsharp
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
<!--
- Dårlig praksis: `type EmailAddress = string`. Tillader ugyldige værdier ("hej", ""). Kræver validering overalt.
- God praksis: Dedikeret `EmailAddress` type med privat konstruktør.
- `create` funktion: Eneste måde at skabe en `EmailAddress`. Indeholder validering.
- Garanti: En værdi af typen `EmailAddress` er *altid* gyldig. Reglen er indkodet i typen.
-->
---

### Descriminated Unions

```fsharp
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
<!--
- Discriminated Unions (DUs): Definerer en type, der kan være én ud af flere faste tilstande.
- Eksempel: `PaymentStatus`. En betaling kan kun være i én af disse tilstande.
- Tilstande kan have associerede data (f.eks. `PartiallyPaid` har `amountPaid`).
- Pattern matching: Compileren tvinger os til at håndtere alle tilstande, hvilket forhindrer fejl.
-->
---

### Single Case Unions

```fsharp
type CustomerId = CustomerId of int
type OrderId = OrderId of int
type ProductId = ProductId of int

let findCustomer (CustomerId id) = // ...
let findOrder (OrderId id) = // ...

// error!
findCustomer (OrderId 123)
```
<!--
- Teknik: Brug en DU med én case til at "wrappe" en primitiv type (f.eks. `int`).
- Formål: Giver semantisk betydning og typesikkerhed.
- `CustomerId` og `OrderId` er forskellige typer, selvom de begge indeholder en `int`.
- Forhindrer fejl: Compileren fanger forsøg på at blande forskellige ID-typer.
-->
---

### Active Patterns

```fsharp
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
<!--
- F# feature: Udvider pattern matching systemet.
- Formål: Giver os mulighed for at navngive klassifikationer af inputdata.
- Eksempel: `(|Even|Odd|)` klassificerer et heltal som lige eller ulige.
- Anvendelse: Kan bruges direkte i `match`-udtryk, som var de DU-cases.
- Gør koden mere læsbar og deklarativ.
-->
---

### Conclusion

- Monoids provide operations with guarantees
- Type-base programming enforces domain rules

- Together:
  - Safe data composition
  - Invalid states impossible
  - Readable domain models
  - Compiler enforced checks
<!-- 
- Monoids: Garanterer sikker og forudsigelig sammensætning af data.
- Type-baseret programmering: Håndhæver domæneregler i compileren, gør ugyldige tilstande umulige.
- Sammen: Sikker datakomposition, læsbare domænemodeller og færre fejl pga. kompileringstjek.
-->