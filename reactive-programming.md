---
title: Reactive Programming
author: Esben Inglev
theme: uncover
date: Jan 2026
---

# What is Reactive Programming

- Reactive programming is all about event
- Event handling initially looks simple
  - Gets complex fast in bigger systems
- In F#, we want to handle this functionally idiomatic
  - No side effects and with pure functions

---

# Event Stream

- Example of event stream:

```f#
let createTimer timerInterval handler =
  let timer = new System.Timers.Timer(float timerInterval)
  timer.AutoReset <- true

  timer.Elapsed.Add eventHandler

  async {
    timer.Start()
    do! Async.Sleep 5000 // a max runtime of the
    timer.Stop()
  }

```

---

# Another Page

Bllablalba

## Sub Heading
