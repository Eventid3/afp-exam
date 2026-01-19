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
Så, hvad er reaktiv programmering?

Kort sagt handler det om at programmere med asynkrone datastrømme, eller "events". Tænk på det som en udvidelse af Observer-mønsteret.

Det er et deklarativt paradigme, hvilket betyder, at vi beskriver _hvad_ vi vil opnå, ikke _hvordan_ vi opnår det.

Kernen er, at vi behandler strømme af hændelser som "first-class citizens" - ligesom vi behandler lister eller andre datastrukturer. Det betyder, at vi kan komponere, transformere og manipulere disse strømme af data, der ankommer over tid.
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
Hvorfor er dette vigtigt? Asynkrone data er overalt i moderne applikationer. Bruger-interaktioner i en UI, netværkskald, notifikationer fra databaser – alt dette er strømme af hændelser.

Traditionel hændelseshåndtering med callbacks kan virke simpel i starten, men det bliver hurtigt meget komplekst og uoverskueligt i større systemer – fænomenet kendt som "callback hell".

I F# stræber vi efter at skrive ren, funktionel kode uden side-effekter. Reaktiv programmering giver os værktøjerne til at håndtere asynkrone strømme på en måde, der passer perfekt med den funktionelle tankegang. Det giver os bedre komposition, bedre fejlhåndtering og mere læsbar kode end traditionelle callbacks.
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
På venstre side ser vi den klassiske .NET-måde at håndtere events på. Vi har en `Elapsed` hændelse på en timer, og vi tilføjer en 'handler' til den med `Add`. Dette er imperativt og baseret på side-effekter.

På højre side ser vi starten på en mere reaktiv tilgang. Vi opretter en funktion, der returnerer en `observable` fra timerens `Elapsed`-hændelse. En 'observable' er den centrale abstraktion i reaktiv programmering. Den repræsenterer en strøm af fremtidige hændelser.
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
Kernen i reaktiv programmering i .NET er disse to interfaces.

`IObservable<'T>` repræsenterer den "observerbare" strøm af værdier. Det er den, der producerer data. Den har kun én metode: `Subscribe`.

`IObserver<'T>` repræsenterer "observatøren", der lytter til strømmen. Man giver en observatør til `Subscribe`-metoden. Observatøren har tre metoder:
- `OnNext` bliver kaldt for hver ny værdi i strømmen.
- `OnError` bliver kaldt, hvis der sker en fejl.
- `OnCompleted` bliver kaldt, når strømmen er slut og ikke vil producere flere værdier.

Dette er en "push"-baseret model. Produceren (observable) skubber data ud til forbrugeren (observer), når data er klar. Det er modsat "pull"-modellen i f.eks. `IEnumerable`, hvor forbrugeren aktivt trækker data ud.
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
Her er et helt simpelt eksempel.

Først opretter vi en observable direkte fra timerens `Elapsed` hændelse. F# har indbygget understøttelse for at konvertere .NET events til observables.

Derefter kalder vi `Subscribe` på vores observable med en simpel funktion. Denne funktion vil blive eksekveret for hver 'tick' fra timeren.

`Subscribe` returnerer et `IDisposable` objekt. Dette er vores abonnement. Når vi ikke længere vil lytte til strømmen, kalder vi `Dispose` på dette objekt. Dette er en central del af reaktiv programmering, da det giver en klar og ressource-sikker måde at afmelde sig fra hændelser.
-->

---

### Observable Module in F #

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
Det er her, det for alvor bliver funktionelt og kraftfuldt. F# har et `Observable`-modul, der indeholder en lang række funktioner, der minder meget om dem, vi kender fra `List`, `Seq` og `Array`.

Vi kan bruge funktioner som `filter`, `map`, `merge` og `take` til at transformere og kombinere observables.

Det betyder, at vi kan tænke på en strøm af hændelser over tid, præcis som vi tænker på en liste af værdier. Vi kan bygge en 'pipeline' af operationer, der behandler hændelserne, efterhånden som de ankommer.
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

## This counts clicks functionally without mutable state

<!--
Lad os se på et praktisk eksempel: at tælle antallet af museklik på en knap.

Uden reaktiv programmering ville vi typisk have en `mutable` tæller-variabel, som vi inkrementerer i en event handler. Det er en kilde til side-effekter og tilstands-kompleksitet.

Med reaktiv programmering kan vi gøre det helt funktionelt:
1. Vi tager `button.Click` hændelsen, som er en observable.
2. Vi `map`'er hvert klik til tallet `1`. Nu har vi en strøm af 1-taller.
3. Vi bruger `scan`. `scan` er som `fold`, men den returnerer hver mellemliggende akkumuleret værdi. Vi starter med 0 og lægger `1` til for hvert klik. Dette giver os en strøm af `1, 2, 3, 4, ...`.
4. Til sidst bruger vi `add` (en F#-specifik version af subscribe) til at printe den seneste tælling.

Resultatet er en deklarativ pipeline, der er nem at læse og helt fri for mutabel tilstand.
-->

---

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

<!--
Forestil dig et lidt mere komplekst scenarie. Vi vil kun håndtere et klik, hvis der er gået mindst 300 millisekunder siden det sidste klik (også kendt som "throttling").

Den imperative løsning kræver, at vi manuelt holder styr på tilstanden – hvornår var det sidste klik? Vi skal have en `mutable` variabel og en masse `if/else` logik. Det bliver hurtigt grimt og fejlbehæftet, især hvis vi har flere af den slags regler.
-->

---

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

<!--
Den reaktive løsning er igen en smuk, deklarativ pipeline. Vi kan bruge `throttle` operatoren (ikke vist her, men findes i `Observable`-modulet) til at løse dette elegant.

Koden her viser en lidt mere manuel, men stadig funktionel, tilgang. Pointen er, at logikken er indeholdt i en serie af rene funktioner, der transformerer strømmen.

Den korrekte og endnu simplere reaktive løsning ville være:
`button.Click |> Observable.throttle (TimeSpan.FromMilliseconds(300)) |> Observable.add (fun _ -> printfn "Clicked!")`

Koden er selv-dokumenterende. Den siger præcis, hvad den gør: "Tag klik-hændelserne, begræns dem til én hver 300ms, og reager så."
-->

---

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

<!--
Her ser vi, hvor reaktiv programmering virkelig skinner: i komplekse asynkrone scenarier som en autocomplete søgeboks.

Lad os bryde pipelinen ned:
1.  Vi lytter til `TextChanged` hændelsen.
2.  Vi `map`'er hver hændelse til den aktuelle tekst i boksen.
3.  Vi `filter`'er, så vi kun fortsætter, hvis teksten er længere end 2 tegn.
4.  `distinctUntilChanged` sikrer, at vi ikke sender den samme søgning to gange i træk.
5.  `throttle` (eller `debounce`) er kritisk her. Den venter på en pause i skrivningen (f.eks. 500ms), før den sender en værdi videre. Dette forhindrer, at vi sender et API-kald for hvert eneste tastetryk.
6.  Vi `map`'er den stabile tekst til et asynkront `searchAPI` kald. Dette giver os en strøm af `Async<Result>`-objekter.
7.  `switch` er magisk. Hvis en ny søgning starter, før den forrige er færdig, vil `switch` annullere den forrige og kun give os resultatet fra den seneste søgning. Dette forhindrer race conditions, hvor gamle resultater overskriver nye.
8.  Til sidst `add`'er vi en funktion, der viser resultaterne i UI'en.

Prøv at forestille jer at implementere alt dette manuelt med `Timers`, `mutable` flag og callbacks. Det ville være et mareridt. Med reaktive extensions er det en overskuelig og robust pipeline.
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
For at opsummere, er her de primære fordele:
- **Deklarativt:** Vi beskriver vores intentioner, hvilket gør koden lettere at læse og forstå.
- **Komponerbart:** Vi kan bygge komplekse systemer ved at sætte simple byggeklodser (operatorer) sammen.
- **Mindre tilstand:** Vi undgår mutabel tilstand, hvilket reducerer kompleksitet og en hel klasse af fejl.
- **Fejlhåndtering:** Fejl er bare en type besked i strømmen (`OnError`), som kan håndteres centralt med `catch`-operatorer, i stedet for `try-catch` blokke overalt.
- **Annullering:** `IDisposable`-abonnementet giver en standardiseret og robust måde at håndtere oprydning og annullering på.
- **Testbarhed:** Da vores logik er i rene funktioner, er det meget nemmere at enhedsteste vores transformations-pipelines.
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
Et vigtigt teoretisk koncept er forskellen på "kolde" og "varme" observables.

En **kold** observable starter først sit arbejde, når nogen abonnerer. Hver abonnent får sin egen private sekvens af værdier. Et eksempel er en observable, der laver et HTTP-kald. Kaldet bliver først lavet, når du kalder `Subscribe`, og hver ny abonnent vil udløse et nyt HTTP-kald.

En **varm** observable producerer værdier, uanset om der er nogen abonnenter eller ej. Tænk på musebevægelser. De sker, uanset om dit program lytter eller ej. Alle abonnenter deler den samme strøm af værdier og vil kun modtage de værdier, der bliver produceret, *efter* de har abonneret.

I eksemplet er `Observable.interval` kold, fordi den skaber en ny timer for hver abonnent. `timer.Elapsed` er varm, fordi den kommer fra en enkelt, delt timer, der kører uafhængigt.
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
Her er en hurtig oversigt over nogle af de mest almindelige og nyttige operatorer, hvoraf vi har set flere:

- `throttle` (eller `debounce`) er perfekt til input fra brugere, hvor vi vil vente på en pause.
- `distinctUntilChanged` er god til at undgå unødvendigt arbejde, når værdien ikke har ændret sig.
- `scan` er den reaktive version af `fold`, der lader os bygge tilstand op over tid på en funktionel måde.
- `merge` lader os kombinere flere strømme til én. F.eks. kan vi merge fejl-events fra forskellige kilder.
- `switch` er essentiel, når vi arbejder med operationer, der returnerer observables (som asynkrone kald), for at undgå race conditions.
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

## Errors propagate through pipeline and can be handled gracefully

<!--
Fejlhåndtering er en af de store styrker. I en reaktiv pipeline vil en exception i en operator (som `riskyOperation` her) ikke crashe programmet. I stedet stopper den normale strøm af værdier, og en `OnError` notifikation bliver sendt ned gennem pipelinen.

Vi kan bruge `catch`-operatoren til at fange denne fejl. `catch` tager en funktion, der modtager exceptionen og skal returnere en *ny* observable.

Her logger vi fejlen og returnerer `Observable.empty`, som er en observable, der bare med det samme sender en `OnCompleted` besked. Dette stopper pipelinen på en kontrolleret måde. Vi kunne også have returneret en default-værdi, f.eks. `Observable.Return(defaultValue)`, eller skiftet til en anden "fallback" observable.
-->

---

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
<!--
Hvornår skal man så bruge det?

Det er en rigtig god løsning til:

- Håndtering af UI hændelser, som vi har set.
- Realtids data-feeds, f.eks. fra WebSockets eller finansielle data.
- Komplekse asynkrone arbejdsgange, hvor hændelser skal koordineres, filtreres og transformeres.
- Når man skal orkestrere flere forskellige hændelseskilder.

Det er måske overkill for:

- Simple, enkeltstående asynkrone operationer. Her er F#'s `async` workflows ofte simplere og mere direkte.
- Ren synkron, sekventiel databehandling. Her er `Seq` eller `List` modulerne det rigtige værktøj.
- I situationer, hvor en simpel, imperativ løsning vitterligt er nemmere at læse og vedligeholde. Det er et værktøj, ikke en religion.
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

## Can combine them: `Observable.ofAsync` and `Async.AwaitObservable`

<!--
Til sidst, en hurtig sammenligning med `async` workflows, som vi også bruger meget i F#.

De løser begge asynkrone problemer, men de har forskellige use cases.

Et `async` workflow repræsenterer en operation, der vil producere en *enkelt* værdi i fremtiden. Det er en asynkron version af `T`.

En `observable` repræsenterer en strøm af *mange* værdier over tid. Det er en asynkron version af `IEnumerable<T>`.

Det gode er, at de spiller rigtig godt sammen. Man kan nemt konvertere mellem dem. `Observable.ofAsync` kan starte et async workflow og returnere en observable, der udsender den ene værdi, når den er klar. `Async.AwaitObservable` kan vente på den næste værdi fra en observable. Dette giver os det bedste fra begge verdener.
-->

---

### Questions?

<!--
Det var en hurtig tur gennem reaktiv programmering i F#.

Er der nogen spørgsmål?
-->

