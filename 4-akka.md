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
Akka.NET er et framework, der implementerer aktør-modellen (actor model).

De to helt centrale byggeklodser i denne model er _aktører_ og _beskeder_.

Hele formålet med Akka.NET er at gøre det nemmere at bygge systemer, der er samtidige (kan gøre mange ting på én gang) og distribuerede (kan køre på tværs af flere maskiner), uden at vi selv skal bøvle med de lav-niveau detaljer som tråde, låse og netværkskommunikation.
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
  Hvad er en aktør så? En aktør er en fundamental enhed, der kan modtage og sende beskeder.

En aktør har sin egen private tilstand, som ingen andre kan tilgå direkte. Den eneste måde at interagere med en aktør på er ved at sende den en besked. Dette er nøglen til at undgå 'race conditions' og behovet for låse.

Beskeder er typisk immutable, hvilket passer perfekt med F# og den funktionelle stil.

Alle aktører lever inde i et "Actor System". Aktører kan sende beskeder til hinanden, enten som "fire-and-forget", hvor man ikke forventer et svar, eller som "ask", hvor man venter på et svar.
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
En aktør har en veldefineret livscyklus med metoder, vi kan "override" for at køre kode på bestemte tidspunkter.

- `PreStart` kaldes én gang, når aktøren bliver skabt, *før* den begynder at modtage beskeder. Det er et godt sted at initialisere ressourcer.
- `Receive` er ikke en metode, men den tilstand, hvor aktøren modtager og behandler beskeder.
- `PostStop` kaldes, når aktøren bliver stoppet. Her kan man rydde op.
- `PreRestart` og `PostRestart` er relateret til fejlhåndtering, som vi kommer til senere. De giver os mulighed for at gemme og genoprette tilstand, når en aktør genstarter efter en fejl.
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
Her ser vi, hvordan man kommer i gang.

1.  Først skal vi have et `ActorSystem`. Det er containeren for alle vores aktører. Vi giver det et navn.
2.  Så definerer vi selve aktørens opførsel. I Akka.NET.FSharp gøres dette typisk med en funktion, der tager en `mailbox` som argument. Mailboxen er her, beskederne ankommer. Vi bruger en rekursiv `loop` og et `actor { ... }` computation expression til at modtage og behandle beskeder én ad gangen.
3.  Til sidst "spawner" vi aktøren ind i systemet med `spawn`. Vi giver den et navn ("greeter") og den funktion, der definerer dens opførsel. `spawn` returnerer en reference til aktøren (`IActorRef`), som vi kan bruge til at sende beskeder til den.
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
Beskeder kan være næsten enhver F# type. Det er god praksis at bruge veldefinerede typer som Records eller Discriminated Unions (DUs).

DUs er især velegnede til at definere de forskellige typer af kommandoer, en aktør kan modtage. Som her med `CounterMsg`.

Bemærk `GetCount`-casen. Den indeholder en `AsyncReplyChannel`. Dette er en del af "ask"-mønsteret. Det er en midlertidig kanal, som afsenderen lytter på, og som `GetCount`-modtageren kan bruge til at sende et svar tilbage.
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
Her er et komplet eksempel på en `counterActor`, der bruger `CounterMsg` DU'en.

Aktøren holder sin tilstand – `count` – som en parameter i sin rekursive `loop`-funktion. Dette er en standard funktionel måde at håndtere tilstand på. Tilstanden er fuldstændig privat for aktøren.

I `actor`-blokken modtager vi en besked og pattern-matcher på den.
- Ved `Increment` og `Decrement` kalder vi `loop` rekursivt med den nye, opdaterede tælling.
- Ved `GetCount` bruger vi den medfølgende `channel` til at sende den nuværende `count` tilbage til afsenderen. Derefter fortsætter vi løkken med den uændrede `count`.
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
Hvordan kommunikerer aktører?

Vi bruger en `IActorRef`, som er en letvægtsreference eller "adresse" til en aktør.

Der er to primære måder at sende på:
- `Tell`, med operatoren `<!`. Dette er "fire-and-forget". Vi sender beskeden og fortsætter med det samme. Vi får ikke noget svar og ved ikke, om beskeden blev modtaget.
- `Ask`, med operatoren `<?`. Dette er for request-response. `Ask` returnerer en `Async<T>`, som vi kan `await`'e for at få et svar. Bag kulisserne skaber den den `AsyncReplyChannel`, vi så før.

Hver aktør har en mailbox, hvor indkommende beskeder bliver lagt i kø. En aktør behandler altid kun én besked ad gangen. Dette garanterer, at dens interne tilstand aldrig bliver korrumperet af samtidige adgange.
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
  Et af de mest kraftfulde koncepter i Akka er aktør-hierarkiet. Aktører er ikke bare en flad liste; de er organiseret i et træ-lignende hierarki.

Hver aktør har en forælder (undtagen rod-aktørerne øverst oppe). Denne forælder har et særligt ansvar: at _overvåge_ (supervise) sine børn.

Hvis en barn-aktør crasher (kaster en exception), bliver forælderen notificeret. Forælderen kan så beslutte, hvad der skal ske, baseret på en "supervision strategy":

- **Restart:** Genstart barnet (skaber en ny instans). Dette er standard.
- **Stop:** Stop barnet permanent.
- **Escalate:** Giv fejlen videre opad til sin egen forælder (bedsteforælderen).
- **Resume:** Ignorer fejlen og lad barnet fortsætte (risikabelt!).
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
Her er et eksempel på, hvordan en forælder-aktør kan definere sin overvågningsstrategi.

`Strategy.OneForOne` betyder, at strategien kun gælder for det ene barn, der fejlede. (Alternativet er `OneForAll`, hvor alle søskende også bliver påvirket).

Vi giver en funktion, der tager exceptionen som input og returnerer en `Directive`. Her siger vi:
- Hvis fejlen er en `DivideByZeroException`, så genstart barnet.
- For alle andre fejl, eskaler problemet til min egen forælder.

Dette "lad det crashe"-princip er centralt i Akka. I stedet for at skrive defensiv kode overalt, lader vi fejl ske og håndterer dem på et højere niveau i hierarkiet.
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
Dette hierarki giver en række fordele:

- **Fejlisolering:** En fejl i én del af systemet (et sub-træ) påvirker ikke resten af systemet.
- **Robusthed (Resilience):** Systemet kan "helbrede" sig selv ved at genstarte fejlede dele.
- **Klart ansvar:** Forskellige niveauer i hierarkiet kan have forskellige ansvarsområder. En supervisor styrer workers, en anden håndterer database-forbindelser osv.
- **Location Transparency:** Aktører refereres via deres sti i hierarkiet (f.eks. `/user/supervisor/worker1`). Denne sti er den samme, uanset om aktøren kører på den samme maskine eller en anden maskine i et netværk. Det gør det nemt at distribuere systemet.
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
Hvis man ikke har en direkte `IActorRef` til en aktør, kan man finde den ved hjælp af dens sti. Dette kaldes "Actor Selection".

Det er nyttigt, hvis man skal kommunikere med en aktør, man ikke selv har skabt, eller hvis aktører bliver skabt dynamisk.

Vi kan bruge absolutte stier, der starter fra roden (`/user` er roden for alle bruger-definerede aktører).

Vi kan bruge relative stier fra en eksisterende aktørs `Context`.

Vi kan endda bruge wildcards (`*`) til at sende en besked til flere aktører på én gang, f.eks. alle workers under en supervisor.
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
Her er et helt simpelt, men komplet, "hello world" eksempel.

Vi definerer en `WorkerMsg`, en `workerActor` der kan modtage den, opretter et `ActorSystem`, spawner vores worker, og sender den en besked med `Tell` (`<!`).

Dette viser den grundlæggende skabelon for at arbejde med aktører i Akka.NET.FSharp.
-->

---

### Key Benefits of AKKA

- Concurrency without locks or shared state
- Built-in fault tolerance through supervision
- Location transparency (local/remote actors)
- Scales easily to distributed systems
- Functional programming friendly
<!--
For at opsummere, så giver Akka.NET os:

- En model for samtidighed, der er baseret på beskeder i stedet for delt tilstand og låse, hvilket er meget simplere at ræsonnere over.
- Indbygget fejl-tolerance via overvågnings-hierarkiet.
- "Location transparency", som gør det nemt at skalere fra en enkelt proces til et distribueret cluster.
- Og en model, der passer utroligt godt sammen med den funktionelle tankegang i F# med immutable beskeder og tilstandshåndtering via funktionsparametre.

Tak.
-->

---

