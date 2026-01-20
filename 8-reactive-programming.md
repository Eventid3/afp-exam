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
- Kernen i RP: Programmering med asynkrone datastrømme (events).
- Bygger på: Observer-mønsteret.
- Paradigme: Deklarativt (beskriv _hvad_, ikke _hvordan_).
- Princip: Behandler hændelses-strømme som værdier (lister, etc.), der kan komponeres og transformeres.
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
- Problem: Asynkrone data er overalt (UI, netværk).
- Udfordring: Traditionel event-håndtering (callbacks) bliver hurtigt kompleks ("callback hell").
- Mål i F#: Håndter asynkroni funktionelt, uden side-effekter.
- Fordele: Bedre komposition, fejlhåndtering og læsbarhed end callbacks.
-->

---

### Events and observables

```fsharp
let someHandler _ = printfn "Handling event..."
let timer = new System.Timers.Timer(1000)
timer.Elapsed.Add someHandler
// ...
```

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
```

<!--
- Traditionel .NET: Imperativ, side-effekt baseret event-håndtering med `event.Add`.
- Reaktiv tilgang: Abstraherer hændelser til en 'observable'.
- Observable: Repræsenterer en strøm af fremtidige hændelser.
-->

---

### IObservable<'T> Interface

- Core abstraction in reactive programming
- Represents a stream of values over time
- Push-based (vs pull-based like IEnumerable)
- Subscribe with an observer to receive notifications

```fsharp
type IObservable<'T> =
    abstract Subscribe: IObserver<'T> -> IDisposable

type IObserver<'T> =
    abstract OnNext: 'T -> unit
    abstract OnError: exn -> unit
    abstract OnCompleted: unit -> unit
```

<!--
- `IObservable<'T>`: Produceren. Repræsenterer strømmen. Har kun `Subscribe` metode.
- `IObserver<'T>`: Forbrugeren. Lytter til strømmen. Har tre metoder:
    - `OnNext`: For hver ny værdi.
    - `OnError`: Ved fejl.
    - `OnCompleted`: Når strømmen slutter.
- Model: "Push"-baseret. Producer skubber data til forbruger. Modsat "pull" i `IEnumerable`.
-->

---

### Simple setup

```fsharp
// Create observable from event
let timer = new System.Timers.Timer(1000.0)
let observable = timer.Elapsed

// Subscribe to observable
let subscription =
    observable.Subscribe(fun _ ->
        printfn "Tick!")

timer.Start()

// Clean up
subscription.Dispose()
timer.Stop()
```

<!--
- Oprettelse: Konverter .NET event til observable.
- Abonnement: Kald `Subscribe` med en funktion (en simpel observer).
- Oprydning: `Subscribe` returnerer et `IDisposable` (abonnementet). Kald `Dispose()` for at afmelde og stoppe med at lytte.
-->

---

### Observable Module in F

- F# provides Observable module for functional operations
- Transform streams like collections

```fsharp
open System

// Filter events
Observable.filter (fun x -> x % 2 = 0)

// Map/transform events
Observable.map (fun x -> x * 2)

// Combine streams
Observable.merge observable1 observable2

// Take first N events
Observable.take 5
```

<!--
- `Observable` modul: Tilbyder funktionelle operatorer til at manipulere strømme.
- Velkendte funktioner: `filter`, `map`, `merge`, `take` etc., ligesom på lister.
- Gør det muligt at bygge deklarative pipelines for hændelser.
-->

---

### Practical Example: Mouse Clicks

```fsharp
let clicks = button.Click // IEvent<_>

clicks
|> Observable.map (fun _ -> 1)
|> Observable.scan (+) 0
|> Observable.add (fun count ->
    printfn "Clicked %d times" count)
```

- This counts clicks functionally without mutable state

<!--
- Udfordring: Tæl klik uden mutabel tilstand.
- Pipeline:
  1. `map` hvert klik til `1`.
  2. `scan` (akkumuler) summen. `scan` er som `fold`, men udsender hver mellemværdi.
  3. `add` (subscribe) for at udføre side-effekt (print).
- Resultat: Ren, funktionel og deklarativ løsning.
  -->

---

### Complexity with event piping

- Problem: Multiple event sources, filtering, throttling

```fsharp
// Without reactive: messy, stateful
let mutable lastClick = DateTime.MinValue
let clickHandler _ =
    let now = DateTime.Now
    if (now - lastClick).TotalMilliseconds > 300 then
        lastClick <- now
        // handle click
```

- Requires manual state management and timing logic

<!--
- Komplekst scenarie: "Throttling" (ignorer klik, der kommer for hurtigt).
- Imperativ løsning: Kræver manuel, mutabel tilstand (`lastClick`) og if/else logik.
- Bliver hurtigt komplekst og fejlbehæftet.
  -->

---

### Reactive Solution

```fsharp
// With reactive: declarative, composable
button.Click
|> Observable.throttle (TimeSpan.FromMilliseconds(300))
|> Observable.add (printfn "Clicked!")
```

- Clean, functional, and self-documenting

<!--
- Reaktiv løsning: Brug `throttle` operatoren.
- Pipelinen er simpel, deklarativ og selv-dokumenterende.
- "Tag klik, begræns dem til max én hver 300ms, og reager så".
-->

---

### Complex Scenario: Autocomplete

```fsharp
textBox.TextChanged
|> Observable.map (fun _ -> textBox.Text)
|> Observable.filter (fun text -> text.Length > 2)
|> Observable.distinctUntilChanged
|> Observable.throttle (TimeSpan.FromMilliseconds(500))
|> Observable.map searchAPI
|> Observable.switch
|> Observable.add displayResults
```

<!--
- Autocomplete er et perfekt eksempel på styrken i RP.
- Pipeline-forklaring:
    1. `map` til tekst.
    2. `filter` på længde.
    3. `distinctUntilChanged` for at undgå unødige kald.
    4. `throttle` for at vente på pause i skrivning.
    5. `map` til asynkront `searchAPI` kald.
    6. `switch`: Annullerer forrige kald, hvis et nyt kommer. Undgår race conditions.
    7. `add` for at vise resultater.
- Umuligt at implementere elegant manuelt.
-->

---

### Benefits of Reactive Approach

- **Declarative**: Describe what, not how
- **Composable**: Chain operations like pipelines
- **Less state**: No mutable variables to track
- **Error handling**: Centralized with `Observable.catch`
- **Cancellation**: Built-in with `IDisposable`
- **Testable**: Pure functions, easy to mock

<!--
- **Deklarativt:** Lettere at læse og forstå intentionen.
- **Komponerbart:** Byg komplekse systemer af simple operatorer.
- **Mindre tilstand:** Undgå mutabilitet og de fejl, det medfører.
- **Fejlhåndtering:** Centraliseret med `catch`. Fejl er blot en besked i strømmen.
- **Annullering:** Indbygget, robust oprydning via `IDisposable`.
- **Testbarhed:** Rene funktioner i pipelinen er lette at enhedsteste.
-->

---

### Hot vs Cold Observables

**Cold Observable**: Produces values on subscription

- Each subscriber gets own sequence
- Example: HTTP request observable

**Hot Observable**: Produces values regardless of subscribers

- All subscribers share same sequence
- Example: Mouse moves, timer events

```fsharp
// Cold: new timer per subscriber
let cold = Observable.interval 1000
// Hot: shared timer
let timer = new Timer(1000.0)
let hot = timer.Elapsed
```

<!--
- **Kold Observable**: Starter først ved abonnement. Hver abonnent får sin egen private sekvens (f.eks. et HTTP-kald).
- **Varm Observable**: Producerer værdier uafhængigt af abonnenter. Abonnenter deler den samme strøm (f.eks. muse-events).
- Eksempel: `Observable.interval` er kold (ny timer pr. abonnent), `timer.Elapsed` er varm (deler én timer).
-->

---

### Common Operators

```fsharp
// Debounce: Wait for pause in events
Observable.throttle (TimeSpan.FromMilliseconds(300))
// Distinct: Skip duplicate consecutive values
Observable.distinctUntilChanged
// Scan: Accumulate like fold
Observable.scan (+) 0
// Combine: Merge multiple streams
Observable.merge stream1 stream2
// Switch: Cancel previous, take latest
Observable.switch
```

<!--
- `throttle`: Vent på pause i hændelser (godt til brugerinput).
- `distinctUntilChanged`: Undgå unødvendigt arbejde.
- `scan`: Akkumuler tilstand funktionelt (reaktiv `fold`).
- `merge`: Kombiner flere strømme til én.
- `switch`: Essentiel til asynkrone opgaver for at undgå race conditions.
-->

---

### Error Handling

```fsharp
observable
|> Observable.map riskyOperation
|> Observable.catch (fun ex ->
    printfn "Error: %s" ex.Message
    Observable.empty)
|> Observable.add processResult
```

- Errors propagate through pipeline and can be handled gracefully

<!--
- Fejl (exceptions) i en pipeline crasher ikke programmet.
- De bliver til en `OnError` notifikation, der sendes ned gennem pipelinen.
- `catch`-operatoren fanger fejlen og lader os reagere, f.eks. ved at returnere en tom strøm (`Observable.empty`) eller en default-værdi.
-->

---

### Reactive vs Async

Both handle asynchrony, but different use cases:
**Async**: Single future value

```fsharp
let! result = downloadAsync url
```

**Reactive**: Stream of values over time

```fsharp
clicks |> Observable.add handler
```

- Can combine them: `Observable.ofAsync` and `Async.AwaitObservable`

<!--
- `async`: Repræsenterer en _enkelt_ fremtidig værdi (en asynkron `T`).
- `observable`: Repræsenterer en _strøm_ af mange værdier over tid (en asynkron `IEnumerable<T>`).
- De kan kombineres: Konverter mellem `async` og `observable` for at bruge det bedste værktøj til opgaven.
-->

---
