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

---

### What is Ports and Adapters?

**Architectural pattern for separating domain logic from external concerns**

```
Outside World <-> Adapter <-> Port <-> Domain Logic
```

- **Domain Logic**: Pure business rules (the hexagon core)
- **Ports**: Function types defining what domain needs
- **Adapters**: Concrete implementations of those types

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

---

### Example: Task Manager

**Domain Model (Pure)**

```fsharp
type Task = {
    Id: string
    Description: string
    Completed: bool
}

```

---

### The Problem Without This Architecture

```fsharp
let completeTask (task: Task) : Task =
    let completed = { task with Completed = true }

    // Domain logic mixed with I/O!
    let json = JsonSerializer.Serialize(completed)
    File.WriteAllText($"{task.Id}.json", json)
    printfn "Task %s completed!" task.Id

    completed
```

**Issues:**

- Can't test without hitting file system
- Can't reuse logic with different storage
- Pure logic tangled with impure I/O

---

### Defining Ports (Function Types)

```fsharp
// Output ports (domain -> outside)
type SaveTask = Task -> unit
type NotifyUser = string -> unit

// Input ports (outside -> domain)
type LoadTasks = unit -> Task list
```

**These are just type aliases - the domain's interface**

---

### Implementing Adapters

```fsharp
// File system adapter
let fileAdapter: SaveTask =
    fun task ->
        let json = JsonSerializer.Serialize(task)
        File.WriteAllText($"{task.Id}.json", json)

// In-memory adapter (for testing)
let inMemoryAdapter: SaveTask =
    fun task ->
        memoryStore.Add(task)
```

**Same port type, different implementations**

---

### Domain Logic Uses Ports

```fsharp
let completeTask (task: Task) =
    {task with Completed = true}

let addAndCompleteTask
    (save: SaveTask)
    (notify: NotifyUser)
    (task: Task) : unit =

    let completed = completeTask task
    save completed
    notify $"Task {task.Id} completed!"
```

**Domain knows nothing about files, databases, or console**

---

### Connection: Type-Driven Development

**1. Design ports first (types)**

```fsharp
type SaveTask = Task -> unit
```

**2. Domain logic depends only on types**

```fsharp
let addTask (save: SaveTask) = ...
```

**3. Compiler ensures adapters match**

```fsharp
let fileAdapter: SaveTask = ...  // must match!
```

**Types drive the architecture**

---

### Connection: Composition

**Small, focused functions compose naturally**

```fsharp
let save: SaveTask = fileAdapter
let notify: NotifyUser = consoleAdapter

let workflow =
    createTask
    >> validateTask
    >> completeTask
    >> (fun task -> save task; task)
    >> (fun task -> notify "Done!"; task)
```

**Adapters are just functions - easy to compose**

---

### Other functional architetrues

**Onion Architecture**

- Alternative, inspired by Ports and Adapters
- Inner circles know nothing of the outer layers
- Programmer must avoid give all things on the same layer access to each other...

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
