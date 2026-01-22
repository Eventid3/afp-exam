---
title: Reactive Programming
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 26px;
  }
---

# Reactive Programming

---

### What is Reactive Programming?

- Reactive programming is all about events
- Observer pattern
- Declarative programming paradigm
- Treating event streams as first-class values
- Composing and transforming data over time

<!--
- Kernen i RP: Programmering med asynchronous data streams (events).
- Bygger på: Observer pattern.
- Paradigme: Declarative (beskriv _hvad_, ikke _hvordan_).
- Princip: Behandler event streams som værdier (lister, etc.), der kan komponeres og transformeres.
-->

---

### Why Reactive Programming?

- Async data is everywhere
  - UI events, network requests, timers etc.
- Event handling initially looks simple
  - Gets complex fast in bigger systems
- In F#, we want to handle this functionally idiomatic
  - No side effects and with pure functions
- Better composition and error handling than callbacks

<!--
- Problem: Asynchronous data er overalt (UI, netværk).
- Udfordring: Traditionel event-håndtering (callbacks) bliver hurtigt kompleks ("callback hell").
- Mål i F#: Håndter asynchrony funktionelt, uden side effects.
- Fordele: Bedre komposition, fejlhåndtering og læsbarhed end callbacks.
-->

---

### Events and observables - Traditional

```fsharp
let someHandler _ = printfn "Handling event..."
let timer = new System.Timers.Timer(1000)
timer.Elapsed.Add someHandler
timer.Start()
// ...
```

<!--
- Traditionel .NET: Imperative, side effect baseret event-håndtering med `event.Add`.
- Registrer callback til event
-->

---

### Events and observables - Reactive

```fsharp
let createTimerAndObservable tickrate =
    let timer = new System.Timers.Timer(float tickrate)
    timer.AutoReset <- true
    let observable = timer.Elapsed
    let task =
        async {
            timer.Start()
            do! Async.Sleep 5000
            timer.Stop()
        }
    task, observable

//...
let timer, eventStream = createTimerAndObservable 1000
timerEventStream |> Observable.subscribe (fun _ -> printfn "tick %A" DateTime.Now)
Async.RunSynchronously timer
```

<!--
- Reaktiv tilgang: Abstraherer events til en 'observable'.
- Observable: Repræsenterer en stream af fremtidige events.
- Forskel: I stedet for at registrere - subscribe til
-->

---

### Observable Module in F

- F# provides Observable module for functional operations
- Transform streams like collections

```fsharp
Observable.map (fun x -> x * 2)
Observable.filter (fun x -> x % 2 = 0)
Observable.merge observable1 observable2
Observable.scan collector state source
```

<!--
- `Observable` module: Tilbyder functional operators til at manipulere streams.
- Velkendte funktioner: `filter`, `map`, `merge`, `take` etc., ligesom på lister.
- Gør det muligt at bygge declarative pipelines for events.
-->

---

### Practical Example: Counter

**Event Piping**

```fsharp
let createTimerAndObservable tickrate =
    let timer = new System.Timers.Timer(float tickrate)
    timer.AutoReset <- true
    let observable =
        timer.Elapsed |> Observable.map (fun _ -> 1) |> Observable.scan (+) 0
    let task = async { timer.Start() }

    task, observable

let counterPrinter i = printfn "Recieved number: %i" i
let timer, eventStream = createTimerAndObservable 1000

eventStream
|> Observable.filter (fun i -> i % 2 = 0)
|> Observable.subscribe counterPrinter

Async.RunSynchronously timer
```

<!--
Udfordring: Counter uden mutable state
- Bruger event piping
- Timer-tick observable convertes med map til et int-event
- Scan accumulater int event's
- Subscriber kan pipe eventStreamen videre, hvis den vil
  -->

---

### Complex Scenario: Merging observables

```fsharp
let createTimerAndObservable tickrate =
    let timer = new System.Timers.Timer(float tickrate)
    timer.AutoReset <- true

    let observable =
        timer.Elapsed |> Observable.map (fun _ -> 1) |> Observable.scan (+) 0

    let task = async { timer.Start() }

    task, observable

let counterPrinter i = printfn "Recieved number: %A" i
let timerS, eventStreamS = createTimerAndObservable 1000
let timerDS, eventStreamDS = createTimerAndObservable 100

eventStreamDS
|> Observable.map (fun i -> float i / 10.0)
|> Observable.filter (fun i -> i % 1.0 <> 0.0)
|> Observable.merge (eventStreamS |> Observable.map (fun i -> float i))
|> Observable.subscribe counterPrinter

Async.RunSynchronously timerS
Async.RunSynchronously timerDS

System.Console.ReadLine()
```

---

### Benefits of Reactive Approach

- **Declarative**: Describe what, not how
- **Composable**: Chain operations like pipelines
- **Less state**: No mutable variables to track
- **RxNET**: More features
  - Error handling: `Observable.catch`
  - `Observable.Create`
    - OnNext, OnError, OnCompleted

<!--
- **Declarative:** Lettere at læse og forstå intentionen.
- **Composable:** Byg komplekse systemer af simple operators.
- **Mindre state:** Undgå mutability og de fejl, det medfører.
- **RxNET**: Giver adgang til flere features, bl.a. error handling
-->

---
