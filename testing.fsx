// let createTimerAndObservable tickrate =
//     let timer = new System.Timers.Timer(float tickrate)
//     timer.AutoReset <- true
//
//     let observable =
//         timer.Elapsed |> Observable.map (fun _ -> 1) |> Observable.scan (+) 0
//
//     let task = async { timer.Start() }
//
//     task, observable
//
// let counterPrinter i = printfn "Recieved number: %A" i
// let timerS, eventStreamS = createTimerAndObservable 1000
// let timerDS, eventStreamDS = createTimerAndObservable 100
//
// eventStreamDS
// |> Observable.map (fun i -> float i / 10.0)
// |> Observable.filter (fun i -> i % 1.0 <> 0.0)
// |> Observable.merge (eventStreamS |> Observable.map (fun i -> float i))
// |> Observable.subscribe counterPrinter
//
// Async.RunSynchronously timerS
// Async.RunSynchronously timerDS
//
// System.Console.ReadLine()

let x = Some 3
let y = Some 5

let add a b = a + b

let apply fOpt xOpt =
    match fOpt, xOpt with
    | Some f, Some x -> Some(f x)
    | _ -> None

let (<*>) = apply

let result = Some add <*> x <*> y // Some 8

printfn "result: %i" result.Value
