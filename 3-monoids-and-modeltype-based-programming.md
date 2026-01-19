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

---

### Monoids

- Simple construct with the following definition
  - A type with an associative binary operation
  - and an identity element
- Operation could be +, \* or an append function
- Identity element could be 0, an empty string or an empty list
<!-- 
En monoid er en simpel, men meget kraftfuld matematisk struktur. Bare rolig, det er mere simpelt end det lyder.

En monoid består af tre ting:

1. En type, f.eks. heltal, strenge eller lister.
2. En binær operation, der tager to værdier af den type og returnerer en ny værdi af samme type. Denne operation skal være _associativ_.
3. Et identitetselement for den operation.

Eksempler på operationer kan være addition for tal, konkatenering for strenge, eller 'append' for lister.

Identitetselementet er en speciel værdi, der ikke ændrer den anden værdi, når operationen anvendes. For addition er det 0, for streng-konkatenering er det den tomme streng, og for lister er det den tomme liste.
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
For at noget kan kaldes en monoid, skal det overholde to simple love. Lad os bruge symbolet '⊕' for den binære operation og 'i' for identitetselementet.

1.  **Associativitet:** Rækkefølgen, vi udfører operationerne i, er ligegyldig, så længe elementernes orden bevares. `(a ⊕ b) ⊕ c` er det samme som `a ⊕ (b ⊕ c)`. Dette er ekstremt vigtigt for parallelisering og distribueret beregning, da vi kan opdele en stor opgave i mindre bidder og kombinere resultaterne i vilkårlig rækkefølge.

2.  **Identitet:** Hvis vi kombinerer et element med identitetselementet, får vi det oprindelige element tilbage. Dette gælder både, når identiteten er på venstre og højre side af operationen.
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
Lad os se på et konkret eksempel: Lister i F#.

Typen er `list<'a>`.
Operationen er 'append', repræsenteret ved `@`-operatoren.
Identitetselementet er den tomme liste `[]`.

Vi kan se, at lovene holder:
- Associativitet: At sætte `[1]` og `[2]` sammen først, og derefter tilføje `[3]`, giver samme resultat som at sætte `[2]` og `[3]` sammen først, og derefter tilføje `[1]` foran.
- Identitet: At tilføje en tom liste til `[1; 2]` (enten før eller efter) ændrer ikke på listen.

Så, `(list<'a>, @, [])` danner en monoid.
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

Monoids helps us to so safe combining

<!--
Hvorfor er det nyttigt i praksis? Fordi monoider giver os en sikker måde at kombinere ting på.

Forestil dig, at vi henter brugerdata fra flere forskellige kilder: en database, en cache og et eksternt API. Hver af disse operationer returnerer en liste af brugere.

Fordi lister med append-operationen danner en monoid, kan vi trygt kombinere disse lister til én stor liste. Vi kan bruge `List.fold` med append-operationen (`@`) og den tomme liste (`[]`) som startværdi.

Associativiteten betyder, at vi kunne have hentet dataene parallelt og kombineret resultaterne i den rækkefølge, de blev færdige, uden at bekymre os om det endelige resultat ville ændre sig. Det garanterer en sikker og forudsigelig måde at sammensætte data på.
-->

---

### Model/type-based programming

- What programming/rules can we handle in the type?
- Make illegal states not happen
- Encode domain rules in types
- Domain Driven Design
<!-- 
Lad os nu skifte spor til model- eller type-baseret programmering. Dette er en tilgang, hvor vi bruger typesystemet til at modellere vores domæne så præcist som muligt.

Hovedidéen er at gøre ulovlige tilstande umulige at repræsentere i vores kode. I stedet for at have valideringslogik spredt ud over hele systemet, indkoder vi forretningsregler direkte i vores typer.

Dette er tæt beslægtet med principper fra Domain-Driven Design (DDD), hvor målet er at skabe en model, der afspejler domænet meget nøjagtigt.
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
Her er et klassisk eksempel. Hvordan repræsenterer vi en e-mailadresse?

Den dårlige måde er at bruge en `string`. En streng kan indeholde hvad som helst: "hej", "123", eller en tom streng. Ingen af disse er gyldige e-mailadresser. Det betyder, at *enhver* funktion, der tager en `EmailAddress` (som er en string), er nødt til at validere den igen og igen.

Den gode måde er at skabe en dedikeret `EmailAddress` type. Vi gør konstruktøren `private`, så den eneste måde at skabe en `EmailAddress` på er via vores `create` funktion.

Denne funktion indeholder vores valideringslogik. Den returnerer en `EmailAddress` pakket ind i en `Some`, hvis strengen er gyldig, og `None` hvis den ikke er. Når vi først har en værdi af typen `EmailAddress`, kan vi være 100% sikre på, at den er gyldig. Vi har indkodet reglen i typen.
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
Discriminated Unions (DUs) er et ekstremt kraftfuldt værktøj i type-baseret programmering. De lader os definere en type, der kan være én ud af flere forskellige, veldefinerede tilstande.

Her modellerer vi status for en betaling. En betaling kan ikke være "delvist betalt" og "refunderet" på samme tid. En `PaymentStatus` *skal* være én af disse fire tilstande.

Hver tilstand kan have associerede data. `PartiallyPaid` har et beløb, `FullyPaid` har en dato, og `Refunded` har både en dato og en årsag. `Unpaid` har ingen data.

Når vi bruger pattern matching, tvinger compileren os til at håndtere alle mulige tilstande. Dette eliminerer en hel klasse af bugs, hvor vi glemmer at håndtere en bestemt tilstand.
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
En anden nyttig teknik er "single-case unions". Her bruger vi en DU med kun én case til at pakke en primitiv type som `int` eller `string`.

Hvorfor? For at give den semantisk betydning og typesikkerhed. Et `CustomerId`, `OrderId` og `ProductId` kan alle internt være repræsenteret af et heltal, men de er ikke det samme. De er forskellige koncepter i vores domæne.

Ved at pakke dem ind i deres egne typer, forhindrer vi fejl, hvor vi ved et uheld bruger et `OrderId` i en funktion, der forventer et `CustomerId`. Compileren vil fange denne fejl for os. Vi kan ikke længere blande æbler og pærer, selvom de begge er "frugt" (eller `int` i dette tilfælde).
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
Active Patterns er en F#-feature, der lader os udvide pattern matching systemet. De giver os mulighed for at navngive "partitioner" af inputdata.

Her definerer vi et aktivt mønster `(|Even|Odd|)`, der tager et heltal og klassificerer det som enten `Even` (lige) eller `Odd` (ulige).

Nu kan vi bruge `Even` og `Odd` direkte i vores `match` udtryk, som om de var indbyggede cases i en Discriminated Union.

Dette gør koden meget læsbar og deklarativ. Vi beskriver, *hvad* vi leder efter (et lige eller ulige tal), i stedet for *hvordan* vi tjekker det (med modulo-operationen). Det er en måde at knytte navne til egenskaber ved vores data.
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
  Lad os samle op.

Monoider giver os en ramme for at kombinere data på en sikker og forudsigelig måde, med garantier som associativitet. Det er fundamentet for sikker komposition.

Type-baseret programmering lader os bruge compileren til at håndhæve vores forretningsregler og gøre ugyldige data-tilstande umulige at repræsentere.

Når vi bruger dem sammen, opnår vi en række fordele:

- Vi kan sikkert sammensætte vores veldefinerede typer.
- Vores domænemodeller bliver mere læsbare og selv-dokumenterende.
- Compileren bliver en aktiv partner i at sikre, at vores program er korrekt, hvilket fanger fejl tidligt i udviklingsprocessen.

Tak.
-->

