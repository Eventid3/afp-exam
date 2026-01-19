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
<!-- Emne: Akka.NET - et framework til at bygge samtidige og distribuerede systemer vha. aktør-modellen. -->
---

### What is AKKA?

- AKKA.net is an actor framework
- Framework consists of
  - Actor
  - Messages
- Designed for building concurrent, distributed systems
<!--
- Akka.NET er et 'actor model' framework.
- Centrale byggeklodser: Aktører og Beskeder.
- Formål: Simplificere udviklingen af samtidige og distribuerede systemer. Abstraherer tråde, låse, netværk væk.
-->
---

### What is an actor?

- Actors are message receivers and/or senders
- Messages are immutable and strongly typed
  - Pairs well with functional paradigm and F#
- Exists within an actor system
- Actors within the system can send messages to each other
  - Fire and forget
  - Send and wait for response
<!--
- En aktør er en enhed, der modtager og sender beskeder.
- Egen, privat tilstand. Interaktion kun via beskeder (undgår race conditions).
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
- `PostStop`: Til oprydning, efter aktøren er stoppet.
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
```
<!--
- Trin 1: Opret et `ActorSystem` (en container for aktører).
- Trin 2: Definer aktørens opførsel (en funktion der tager en `mailbox`).
- Logik: Typisk en rekursiv `loop` med et `actor { ... }` computation expression.
- Trin 3: "Spawn" aktøren ind i systemet med et navn og en opførsels-funktion. `spawn` returnerer en `IActorRef`.
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
    | GetCount of AsyncReplyChannel<int>

type PersonMsg = {
    Name: string
    Age: int
}
```
<!--
- Beskeder bør være veldefinerede typer (Records, Discriminated Unions).
- DUs er ideelle til at definere en aktørs kommandoer.
- `AsyncReplyChannel`: Bruges til "ask"-mønsteret. En kanal til at sende svar tilbage til afsenderen.
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
        | GetCount channel ->
            channel.Reply(count)
            return! loop count
    }
    loop 0
```
<!--
- Tilstand (`count`) håndteres funktionelt som parameter i den rekursive `loop`. Tilstanden er 100% privat.
- I `actor`-blokken: Modtag besked, pattern match, og kald `loop` rekursivt med ny tilstand.
- `GetCount`: Sender svar tilbage via den medfølgende `channel`.
-->
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
<!--
- Kommunikation via `IActorRef` (en letvægts-reference/adresse).
- `Tell` (`<!`): Fire-and-forget. Asynkront, intet svar.
- `Ask` (`<?`): Request-response. Returnerer en `Async<T>`, der kan ventes på.
- Mailbox: Hver aktør har en kø. Beskeder behandles én ad gangen, hvilket garanterer trådsikkerhed for tilstanden.
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
- Aktører er organiseret i et træ-hierarki.
- Forældre-aktører overvåger (supervises) deres børn.
- Hvis et barn crasher (kaster exception), beslutter forælderen, hvad der skal ske (en "supervision strategy").
- Strategier: `Restart` (standard), `Stop`, `Escalate` (send opad), `Resume`.
-->
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
<!--
- Eksempel på en `supervisor` strategi.
- `Strategy.OneForOne`: Gælder kun for det barn, der fejlede.
- Logik: Match på exception type og returner en `Directive`.
- "Lad det crashe": Centralt princip. Fejl håndteres på et højere niveau, ikke defensivt i hver funktion.
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
- **Location Transparency:** Aktører refereres via sti (`/user/..`), uafhængigt af om de er lokale eller på en anden maskine.
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
- "Actor Selection": Find en aktør via dens sti, hvis man ikke har en `IActorRef`.
- Nyttigt til at kommunikere med aktører, man ikke selv har skabt.
- Stier kan være absolutte, relative eller bruge wildcards (`*`).
-->
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
<!--
- "Hello world" eksempel, der viser den grundlæggende skabelon:
- Definer besked -> Definer aktør-opførsel -> Opret system -> Spawn aktør -> Send besked.
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