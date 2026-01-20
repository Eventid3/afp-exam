---
title: Functional Architecture
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 24px;
  }
---

# Functional Architecture

<!-- Emne: Funktionel arkitektur med fokus på "Ports and Adapters" (Hexagonal Architecture). -->

---

### What is Ports and Adapters?

**Architectural pattern for separating domain logic from external concerns**

```
Outside World <-> Adapter <-> Port <-> Domain Logic
```

- **Domain Logic**: Pure business rules (the hexagon core)
- **Ports**: Function types defining what domain needs
- **Adapters**: Concrete implementations of those types

<!--
- Mål: Adskil kerne-forretningslogik fra ydre systemer (UI, DB, API'er).
- **Domænelogik**: Hjertet af applikationen, ren forretningslogik.
- **Ports**: Domænets grænseflade til omverdenen. Specificerer, _hvad_ der er brug for (f.eks. "gem bruger"). I FP er dette ofte blot en funktionstype.
- **Adapters**: Konkrete implementationer af porte. Et "DB-adapter" implementerer "gem bruger"-porten.
  -->

---

### Why This Works Well in FP

**Ports = Function Types**

- Takes advantage of F# type system
- Function signatures ARE the contract

**Natural Separation**

- Pure functions in the core
- Impure I/O in adapters
- Clear boundary between them

**Testability**

- Just pass different functions

<!--
- **Porte som Funktionstyper**: I F# er en port en simpel `type`-alias for en funktion. Ingen `interface` nødvendig. Signaturen er kontrakten.
- **Naturlig Adskillelse**: Tydelig grænse mellem den rene domænekerne og de urene I/O-adaptere.
- **Simpel Testbarhed**: Test domænelogik ved at "injicere" falske adaptere (simple funktioner), f.eks. en in-memory liste.
-->

---

### Example: Todo Manager

**Domain Model (Pure)**

```fsharp
type Todo = {
    Id: string
    Description: string
    Completed: bool
}
```

<!--
- Eksempel: En simpel todo manager.
- Domænemodel: En ren `Todo` record, der kun indeholder data.
-->

---

### The Problem Without This Architecture

```fsharp
let completeTodo (todo: Todo) : Todo =
    let completed = { todo with Completed = true }

    // Domain logic mixed with I/O!
    let json = JsonSerializer.Serialize(completed)
    File.WriteAllText($"{todo.Id}.json", json)
    printfn "Todo %s completed!" todo.Id

    completed
```

**Issues:**

- Can't test without hitting file system
- Can't reuse logic with different storage
- Pure logic tangled with impure I/O

<!--
- Anti-pattern: Blanding af domænelogik og I/O.
- `completeTodo` både ændrer status OG skriver til filsystem og konsol.
- **Problemer**: - Umulig at enhedsteste isoleret. - Logik kan ikke genbruges med en anden type lager (f.eks. database). - Ren logik er viklet sammen med uren I/O.
  -->

---

### Defining Ports (Function Types)

```fsharp
// Output ports (domain -> outside)
type SaveTodo = Todo -> unit
type NotifyUser = string -> unit

// Input ports (outside -> domain)
type LoadTodos = unit -> Todo list
```

**These are just type aliases - the domain's interface**

<!--
- Løsning: Definer porte som funktionstyper.
- Domænet definerer de kontrakter, det har brug for, uden at specificere *hvordan*.
- `SaveTodo`: En funktion, der kan gemme en `Todo`.
- `NotifyUser`: En funktion, der kan vise en besked.
-->

---

### Implementing Adapters

```fsharp
// File system adapter
let fileAdapter: SaveTodo =
    fun todo ->
        let json = JsonSerializer.Serialize(todo)
        File.WriteAllText($"{todo.Id}.json", json)

// In-memory adapter (for testing)
let inMemoryAdapter: SaveTodo =
    fun todo ->
        memoryStore.Add(todo)
```

**Same port type, different implementations**

<!--
- Adaptere: Konkrete implementationer af portene.
- `fileAdapter`: Implementerer `SaveTodo` ved at skrive til en JSON-fil.
- `inMemoryAdapter`: Implementerer `SaveTodo` ved at gemme i en liste (ideel til test).
- Begge funktioner opfylder den samme `SaveTodo` typesignatur.
-->

---

### Domain Logic Uses Ports

```fsharp
let completeTodo (todo: Todo) =
    {todo with Completed = true}

let addAndCompleteTodo
    (save: SaveTodo)
    (notify: NotifyUser)
    (todo: Todo) : unit =

    let completed = completeTodo todo
    save completed
    notify $"Todo {todo.Id} completed!"
```

**Domain knows nothing about files, databases, or console**

<!--
- `completeTodo` er nu 100% ren. Den tager en todo og returnerer en ny. Let at teste.
- `addAndCompleteTodo` orkestrerer et workflow og tager sine afhængigheder (`save`, `notify`) som argumenter (dependency injection).
- Domænelogikken er helt uvidende om filer, databaser eller konsoller.
-->

---

### Connection: Type-Driven Development

**1. Design ports first (types)**

```fsharp
type SaveTodo = Todo -> unit
```

**2. Domain logic depends only on types**

```fsharp
let addTodo (save: SaveTodo) = ...
```

**3. Compiler ensures adapters match**

```fsharp
let fileAdapter: SaveTodo = ...  // must match!
```

**Types drive the architecture**

<!--
- Mønsteret er en form for Type-Driven Development.
- 1. Design arkitekturen ved at definere port-typerne.
- 2. Skriv domænelogik, der kun afhænger af disse typer.
- 3. Lad compileren validere, at adapterne overholder kontrakterne (typerne).
- Typerne *driver* arkitekturen.
-->

---

### Connection: Composition

**Small, focused functions compose naturally**

```fsharp
let save: SaveTodo = fileAdapter
let notify: NotifyUser = consoleAdapter

let workflow =
    createTodo
    >> validateTodo
    >> completeTodo
    >> (fun todo -> save todo; todo)
    >> (fun todo -> notify "Done!"; todo)
```

**Adapters are just functions - easy to compose**

<!--
- Komposition: Små, fokuserede funktioner (både domæne og adaptere) kan let sættes sammen.
- Eksempel: Et helt workflow kan bygges som en pipeline med `>>` operatoren.
- I/O-operationer (adapterne) kan indsættes direkte i pipelinen.
-->

---

### Other functional architetrues

**Onion Architecture**

- Alternative, inspired by Ports and Adapters
- Inner circles know nothing of the outer layers
- Programmer must avoid give all things on the same layer access to each other...
<!--
- Onion Architecture: Beslægtet mønster med samme mål.
- Princip: Afhængigheder peger altid indad mod kernen.
- De ydre lag (UI, Infra) kender domænet; domænet kender ikke de ydre lag.
- Kræver disciplin for at undgå unødvendige afhængigheder inden for samme lag.
  -->

---

### Summary

**Ports and Adapters in FP:**

- Ports = Function types (no ceremony)
- Adapters = Functions matching those types
- Domain = Pure logic depending only on ports

**Key Connections:**

- **Type-Driven**: Types define architecture
- **Composition**: Functions compose naturally
- **Reader Monad**: Elegant dependency injection

**Result: Testable, flexible, pure domain logic**

<!--
- **Kort fortalt**: Porte er funktionstyper, adaptere er funktioner, domænet er ren logik.
- **Fordele**:
    - Type-drevet arkitektur.
    - Let at komponere.
    - Elegant dependency injection (kan udvides med f.eks. Reader Monad).
- **Resultat**: Testbar, fleksibel kode med en ren kerne.
-->

---
