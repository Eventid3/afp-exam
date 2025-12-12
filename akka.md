---
title: AKKA
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 30px;
  }
---

# AKKA

---

### What is AKKA?

- AKKA.net is an actor framework
- Framework consists of
  - Actor
  - Messages
- Designed for building concurrent, distributed systems

---

### What is an actor?

- Actors are message receivers and/or senders
- Messages are immutable and strongly typed
  - Pairs well with functional paradigm and F#
- Exists within an actor system
- Actors within the system can send messages to each other
  - Fire and forget
  - Send and wait for response

---

### Actor Lifecycle

- **PreStart**: Called before actor starts processing messages
- **Receive**: Active state, processing messages
- **PostStop**: Called after actor stops
- **PreRestart**: Called before restart (on failure)
- **PostRestart**: Called after restart

```fsharp
override x.PreStart() =
    printfn "Actor starting"

override x.PostStop() =
    printfn "Actor stopped"
```

---

### Creation of actor system and actor

```fsharp
// Create actor system
let system = ActorSystem.Create("MySystem")

// Define actor
let greeterActor (mailbox: Actor<string>) =
    let rec loop() = actor {
        let! msg = mailbox.Receive()
        printfn "Hello, %s!" msg
        return! loop()
    }
    loop()

// Spawn actor
let greeter =
    spawn system "greeter" greeterActor
```

---

### Messages

- Tuples
- Records
- Discriminated Unions
- Normally handled by pattern matching

```fsharp
type CounterMsg =
    | Increment
    | Decrement
    | GetCount of AsyncReplyChannel<int>

type PersonMsg = {
    Name: string
    Age: int
}
```

---

### Message Handling Example

```fsharp
let counterActor (mailbox: Actor<CounterMsg>) =
    let rec loop count = actor {
        let! msg = mailbox.Receive()
        match msg with
        | Increment -> return! loop (count + 1)
        | Decrement -> return! loop (count - 1)
        | GetCount channel ->
            channel.Reply(count)
            return! loop count
    }
    loop 0
```

---

### Actor communication

- **IActorRef**: Reference to an actor for sending messages
- **Tell (<!)**: Fire and forget messaging
- **Ask (<?)**: Request-response pattern
- Each actor has a mailbox that queues incoming messages
- Messages processed sequentially per actor
- Parent-child actors can communicate directly

```fsharp
// Fire and forget
greeter <! "Hello World"

// Request-response
let! response = greeter <? GetValue
```

---

### Actor Hierarchy

- Actors form a tree structure
- Every actor has a parent (except root)
- Supervision: parents monitor children
- If child fails, parent decides strategy:
  - **Restart**: Reset actor state
  - **Stop**: Terminate actor
  - **Escalate**: Pass failure to grandparent
  - **Resume**: Continue with current state

---

### Supervision Example

```fsharp
let supervisor (mailbox: Actor<'a>) =
    let strategy = Strategy.OneForOne(fun ex ->
        match ex with
        | :? DivideByZeroException ->
            Directive.Restart
        | _ -> Directive.Escalate
    )
    mailbox.Context.SetSupervisorStrategy(strategy)
    // ... actor logic
```

---

### Actor Hierarchy Benefits

- **Fault isolation**: Failures contained to subtrees
- **Resilience**: Failed actors can be restarted
- **Clear responsibility**: Each level handles specific concerns
- **Location transparency**: Actors referenced by path, not location

```
/user
  /supervisor
    /worker1
    /worker2
```

---

### Actor Selection

- Find actors by path instead of direct reference
- Useful for dynamic actor discovery

```fsharp
// Absolute path
let actor =
    system.ActorSelection("/user/greeter")

// Relative path from parent
let child =
    mailbox.Context.ActorSelection("./child")

// Wildcard selection
let workers =
    system.ActorSelection("/user/supervisor/*")
```

---

### Complete Example

```fsharp
type WorkerMsg = Process of string

let workerActor (mailbox: Actor<WorkerMsg>) =
    let rec loop() = actor {
        let! Process data = mailbox.Receive()
        printfn "Processing: %s" data
        return! loop()
    }
    loop()

let system = ActorSystem.Create("Demo")
let worker = spawn system "worker" workerActor
worker <! Process "task1"
```

---

### Key Benefits of AKKA

- Concurrency without locks or shared state
- Built-in fault tolerance through supervision
- Location transparency (local/remote actors)
- Scales easily to distributed systems
- Functional programming friendly

---
