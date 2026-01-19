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
<!--
Ports and Adapters er et arkitekturmønster, hvis primære mål er at adskille vores kerne-forretningslogik (domænelogikken) fra alt det ydre "støj" – såsom databaser, UI, filsystemet, eksterne API'er osv.

- **Domænelogik:** Dette er hjertet af vores applikation. Det indeholder de rene forretningsregler og ved intet om den ydre verden.
- **Ports:** Dette er de "huller" eller grænseflader, som domænelogikken definerer. En port specificerer, _hvad_ domænet har brug for, f.eks. "jeg har brug for at kunne gemme en bruger". I FP er en port typisk bare en funktionstype.
- **Adapters:** Dette er de konkrete implementationer af portene. Et "database-adapter" implementerer "gem bruger"-porten ved at tale med en database. Et "filsystem-adapter" implementerer den ved at skrive til en fil.

Domænet er isoleret og taler kun til porte. Adaptere "plugges" ind i portene udefra.
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
Hvorfor er dette mønster så perfekt til funktionel programmering?

For det første, i F# kan en "port" være så simpel som en `type` alias for en funktion. `type SaveUser = User -> unit`. Der er ingen grund til at opfinde `interface` eller abstrakte klasser. Funktionens signatur _er_ kontrakten.

Dette skaber en meget naturlig adskillelse mellem ren og uren kode. Vores domænekerne kan bestå af 100% rene funktioner. Alt det urene I/O-kode (side-effekter) bor ude i adapterne.

Testbarheden bliver ekstremt simpel. Når vi skal teste vores domænelogik, giver vi den bare en "falsk" adapter – en simpel funktion, der f.eks. gemmer data i en in-memory liste i stedet for en database. Vi "injicerer" vores afhængigheder som simple funktionsargumenter.
-->

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

<!--
Lad os tage et simpelt eksempel: en task manager.

Vores domænemodel er en simpel `Task` record. Dette er en ren datastruktur, der repræsenterer en opgave i vores system. Den indeholder ingen logik om, hvordan den gemmes eller vises.
-->

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
<!--
Her ser vi, hvordan man *ikke* skal gøre det. Funktionen `completeTask` gør to ting:

1. Den udfører en ren forretningsregel: at sætte `Completed` til `true`.
2. Den udfører en masse uren I/O: den serialiserer til JSON, skriver til filsystemet, og printer til konsollen.

Denne funktion er nu umulig at enhedsteste uden at der bliver oprettet en fil på harddisken. Forretningslogikken er uløseligt viklet sammen med en specifik implementation af persistens (JSON-filer). Vi kan ikke genbruge logikken til at gemme i en database i stedet for.
-->

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

<!--
Her er den rigtige måde at starte på. Vi definerer vores porte som funktionstyper.

Domænet siger: "Jeg har brug for nogen, der kan opfylde disse kontrakter":
- `SaveTask`: En funktion, der kan tage en `Task` og gemme den.
- `NotifyUser`: En funktion, der kan tage en streng og vise den til en bruger.
- `LoadTasks`: En funktion, der kan give mig en liste af alle tasks.

Disse er domænets grænseflade til omverdenen. Bemærk, at de intet siger om *hvordan* disse ting skal ske.
-->

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

<!--
Nu, uden for domænet, kan vi skrive vores adaptere.

Her har vi to forskellige adaptere, der begge implementerer `SaveTask`-porten:
1. `fileAdapter` gemmer tasken som en JSON-fil.
2. `inMemoryAdapter` gemmer tasken i en simpel liste i hukommelsen.

Begge funktioner overholder den samme `Task -> unit` signatur. Compileren sikrer, at vores adaptere passer til de porte, de er designet til.
-->

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

<!--
Nu ser vores domænelogik sådan her ud.

`completeTask` er nu en 100% ren funktion. Den tager en task, og returnerer en ny, opdateret task. Intet andet. Den kan enhedstestes trivielt.

En anden domænefunktion, `addAndCompleteTask`, orkestrerer en workflow. Bemærk, at den tager `SaveTask` og `NotifyUser` som argumenter. Den er afhængig af *portene*, ikke af konkrete implementationer. Dette kaldes dependency injection.

Denne funktion er også ren. Den kalder bare de funktioner, den får givet. Den aner intet om, hvorvidt `save` skriver til en fil eller en database.
-->

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

<!--
Dette mønster er en form for Type-Driven Development (TDD).

1. Vi starter med at designe vores arkitektur ved at definere typerne for vores porte.
2. Vores domænelogik bliver skrevet, så den kun afhænger af disse typer (funktionssignaturer).
3. Compileren bliver vores arkitektur-vogter. Den sikrer, at de adaptere, vi skriver, rent faktisk overholder de kontrakter, som portene definerer.

Typerne er ikke bare databærere; de er fundamentet for hele applikationens struktur.
-->

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

<!--
Fordi vores domæne er bygget af små, fokuserede funktioner, og vores afhængigheder (adaptere) også bare er funktioner, kan vi let komponere det hele sammen.

Her sammensætter vi et helt workflow ved hjælp af `>>` kompositions-operatoren. Vi kan indsætte vores I/O-operationer (adapterne `save` og `notify`) direkte i pipelinen.

Den funktionelle tilgang med komposition gør det meget naturligt at bygge komplekse arbejdsgange ud af simple byggeklodser.
-->

---

### Other functional architetrues

**Onion Architecture**

- Alternative, inspired by Ports and Adapters
- Inner circles know nothing of the outer layers
- Programmer must avoid give all things on the same layer access to each other...
<!--
Ports and Adapters er ikke det eneste mønster. Onion Architecture er meget beslægtet og bygger på de samme principper om at adskille domænet fra ydre afhængigheder.

Ideen er, at afhængigheder altid peger indad mod kernen. De ydre lag (f.eks. UI og infrastruktur) kender til domænet, men domænet kender intet til de ydre lag.

Udfordringen i begge arkitekturer er at være disciplineret. Selvom to moduler er i samme "lag", bør de ikke nødvendigvis have adgang til hinanden. Hvert modul skal have veldefinerede grænseflader.
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
For at opsummere Ports and Adapters i en funktionel kontekst:

- Porte er bare funktionstyper. Simpelt og elegant.
- Adaptere er funktioner, der matcher disse typer.
- Domænekernen er ren logik, der afhænger af portene via dependency injection.

Dette knytter an til centrale funktionelle koncepter:
- Det er type-drevet.
- Det er komponerbart.
- Man kan endda bruge mere avancerede mønstre som Reader-monaden til at håndtere dependency injection endnu mere elegant.

Resultatet er en arkitektur, der er ekstremt testbar, fleksibel (vi kan udskifte adaptere uden at ændre domænet), og hvor vores kerneforretningslogik forbliver ren og let at ræsonnere over.

Tak.
-->

