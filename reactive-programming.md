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

---

### Why Reactive Programming?

- Async data is everywhere
  - UI events, network requests, timers etc.
- Event handling initially looks simple
  - Gets complex fast in bigger systems
- In F#, we want to handle this functionally idiomatic
  - No side effects and with pure functions
- Better composition and error handling than callbacks

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

## This counts clicks functionally without mutable state

### Complexity with event piping

**Problem**: Multiple event sources, filtering, throttling

```fsharp
// Without reactive: messy, stateful
let mutable lastClick = DateTime.MinValue
let clickHandler _ =
    let now = DateTime.Now
    if (now - lastClick).TotalMilliseconds > 300 then
        lastClick <- now
        // handle click
```

## Requires manual state management and timing logic

### Reactive Solution

```fsharp
// With reactive: declarative, composable
button.Click
|> Observable.map (fun _ -> DateTime.Now)
|> Observable.filter (fun time ->
    time - lastTime > TimeSpan.FromMilliseconds(300))
|> Observable.map (fun _ -> "Click!")
|> Observable.add (printfn "%s")
```

## Clean, functional, and self-documenting

### Complex Scenario: Autocomplete

```fsharp
textBox.TextChanged
|> Observable.map (fun _ -> textBox.Text)
|> Observable.filter (fun text ->
    text.Length > 2)
|> Observable.distinctUntilChanged
|> Observable.throttle (TimeSpan.FromMilliseconds(500))
|> Observable.map searchAPI
|> Observable.switch
|> Observable.add displayResults
```

---

### Benefits of Reactive Approach

- **Declarative**: Describe what, not how
- **Composable**: Chain operations like pipelines
- **Less state**: No mutable variables to track
- **Error handling**: Centralized with `Observable.catch`
- **Cancellation**: Built-in with `IDisposable`
- **Testable**: Pure functions, easy to mock

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

## Errors propagate through pipeline and can be handled gracefully

### When to Use Reactive Programming

**Good fit:**

- UI event handling
- Real-time data feeds
- Complex async workflows
- Multiple event sources to coordinate

**Not ideal:**

- Simple one-off async operations (use `async` instead)
- Synchronous sequential processing
- When imperative code is clearer

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

## Can combine them: `Observable.ofAsync` and `Async.AwaitObservable`

### Questions?
