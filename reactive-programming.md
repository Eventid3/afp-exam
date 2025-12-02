---
title: Reactive Programming
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
---

### What is Reactive Programming?

- Reactive programming is all about events
- Observer pattern
- Declarative programming paradigm

---

### Why Reactive Programming?

- Async data is everywhere
  - UI events, network requests, timers etc.
- Event handling initially looks simple
  - Gets complex fast in bigger systems
- In F#, we want to handle this functionally idiomatic
  - No side effects and with pure functions

---

### Events and observables

```f#
let someHandler _ = printfn "Handling event..."
let timer = new System.Timers.Timer(1000)
timer.Elapsed.Add someHandler
...
```

```f#
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

### Simple setup

---

### Complexity with event piping

---
