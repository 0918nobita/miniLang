open System.Collections.Generic

let mem = Array.init 100000 (fun _ -> 0)

let mutable c = 0

let mutable sp = 99999

let push n =
    printfn "  (Push %d)" n
    mem.[sp] <- n
    sp <- sp - 1

let pop () =
    sp <- sp + 1
    printfn "  (Pop %d)" mem.[sp]
    mem.[sp]

let env : int list list = []

let run () =
    let mutable breakNow = false
    while not breakNow do
        let opcode = mem.[c]
        match opcode with
        | 0 ->
            printfn "STOP"
            breakNow <- true
        | 1 ->
            printf "LD "
            c <- c + 1
            let i = mem.[c]
            printf "%d, " i
            c <- c + 1
            let j = mem.[c]
            printfn "%d" j
            push env.[i].[j]
            c <- c + 1
        | 2 ->
            printf "LDC "
            c <- c + 1
            let n = mem.[c]
            printfn "%d" n
            push n
            c <- c + 1
        | 3 ->
            printf "ARGS "
            c <- c + 1
            let length = mem.[c]
            printfn "%d" length
            let headAddr = f
            for _ in 1 .. length do
                mem.[f] <- pop ()
                f <- f + 1
            push headAddr
            c <- c + 1
        | 8 ->
            printfn "DROP"
            ignore <| pop ()
            c <- c + 1
        | 9 ->
            printfn "ADD"
            let rhs = pop ()
            let lhs = pop ()
            push (lhs + rhs)
            c <- c + 1
        | 10 ->
            printfn "MUL"
            let rhs = pop ()
            let lhs = pop ()
            push (lhs * rhs)
            c <- c + 1
        | _ ->
            failwith "unknown opcode"

[<EntryPoint>]
let main _ =
    run ()
    0
