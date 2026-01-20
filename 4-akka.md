---
title: AKKA
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 26px;
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

<!--
- Akka.NET er et 'actor model' framework.
- Centrale byggeklodser: actorer og Beskeder.
- Formål: Simplificere udviklingen af concurrent og distributed systemer. Abstraherer threads, locks, netværk væk.
  -->

---

### What is an actor?

- Actors are message receivers and/or senders
- Messages are immutable and strongly typed
  - Pairs well with functional paradigm and F#
- Exists within an actor system
- Actors within the system can send messages to each other
  - Fire and forget | Tell (`<!`):

  ```fsharp
  greeter <! "Hello World"
  ```

  - Send and wait for response | Ask `(<?)`:

  ```fsharp
  let response = target <? msg |> Async.RunSynchronously
  ```

<!--
- En actor er en enhed, der modtager og sender beskeder.
- Har sin egen mailbox, handler 1 besked ad gangen - threadsafe
- Beskeder er typisk immutable. Passer godt til F#.
- Lever i et 'Actor System'.
- Kommunikation: "Fire-and-forget" (`Tell`) eller request-response (`Ask`).
  -->

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

<!--
- Veldefineret livscyklus med hooks, man kan override:
- `PreStart`: Til initialisering, før første besked.
- `PostStop`: Til oprydning, efter actoren er stoppet.
- `PreRestart`/`PostRestart`: Bruges ifm. fejlhåndtering og genstart.
-->

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

let greeter2 = spawn system "greeter" (actorOf (fun msg -> printfn "Hello, %s!" msg))
```

<!--
- Trin 1: Opret et `ActorSystem` (en container for actorer).
- Trin 2: Definer actorens opførsel (en funktion der tager en `mailbox`).
- Logik: Typisk en rekursiv `loop` med et `actor { ... }` computation expression.
- Note: () er for at loop bliver en funktion
- Note: let! modtager async fra mailbox og binder til msg
- Trin 3: "Spawn" actoren ind i systemet med et navn og en opførsels-funktion. `spawn` returnerer en `IActorRef`.
- Note, actorOf wrapper selv functionen
-->

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
    | GetCount

type PersonMsg = {
    Name: string
    Age: int
}
```

<!--
- Beskeder bør være veldefinerede typer (Records, Discriminated Unions).
- DUs er ideelle til at definere en actors kommandoer.
-->

---

### Message Handling Example

```fsharp
let counterActor (mailbox: Actor<CounterMsg>) =
    let rec loop count = actor {
        let! msg = mailbox.Receive()
        match msg with
        | Increment -> return! loop (count + 1)
        | Decrement -> return! loop (count - 1)
        | GetCount ->
            mailbox.Context.Sender <! count
            return! loop count
    }
    loop 0
```

<!--
- (`count`) håndteres funktionelt som parameter i den rekursive `loop`. Tilstanden er 100% privat.
- I `actor`-blokken: Modtag besked, pattern match, og kald `loop` rekursivt med ny tilstand.
- `GetCount`: Sender svar tilbage via den mailbox sender.
-->

---

### Actor communication

- **IActorRef**: Reference to an actor for sending messages
- **mailbox**: Communication to Sender, Children or Parent

```fsharp
let inputActor (target: IActorRef) (mailbox: Actor<string>) msg =
    match msg with
    | "i" -> target <! Increment
    | "d" -> target <! Decrement
    | _ ->
        let response: int = target <? GetCount |> Async.RunSynchronously
        printfn "Current count: %i" response
```

<!--
- Kommunikation via `IActorRef` (en letvægts-reference/adresse).
- mailbox - adgang til hierakiet og senderen
-->

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

<!--
- actorer er organiseret i et træ-hierarki.
- Forældre-actorer overvåger (supervises) deres børn.
- Hvis et barn crasher (kaster exception), beslutter forælderen, hvad der skal ske (en "supervision strategy").
- Strategier: `Restart` (standard), `Stop`, `Escalate` (send opad), `Resume`.
-->

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

<!--
- **Fejlisolering:** Fejl i ét sub-træ påvirker ikke resten af systemet.
- **Robusthed:** Systemet kan "helbrede" sig selv ved at genstarte dele.
- **Ansvarsfordeling:** Hierarkiet kan afspejle systemets ansvarsområder.
- **Location Transparency:** actorer refereres via sti (`/user/..`), uafhængigt af om de er lokale eller på en anden maskine.
-->

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

<!--
- "Actor Selection": Find en actor via dens sti, hvis man ikke har en `IActorRef`.
- Nyttigt til at kommunikere med actorer, man ikke selv har skabt.
- Stier kan være absolutte, relative eller bruge wildcards (`*`).
-->

---

### Key Benefits of AKKA

- Concurrency without locks or shared state
- Built-in fault tolerance through supervision
- Location transparency (local/remote actors)
- Scales easily to distributed systems
- Functional programming friendly

<!--
- Samtidighed uden låse/delt tilstand.
- Indbygget fejl-tolerance via supervision.
- Location transparency (nem skalering til distribueret system).
- Passer perfekt til FP-paradigmet (immutable beskeder etc.).
  -->

---
