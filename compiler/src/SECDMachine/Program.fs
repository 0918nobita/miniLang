open System.Collections.Generic

let mem = Array.init 100000 (fun _ -> 0)

let mutable pc = 0

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
        let opcode = mem.[pc]
        match opcode with
        | 0 ->
            printfn "STOP"
            breakNow <- true
        | 1 ->
            printf "LD "
            pc <- pc + 1
            let i = mem.[pc]
            printf "%d, " i
            pc <- pc + 1
            let j = mem.[pc]
            printfn "%d" j
            push env.[i].[j]
            pc <- pc + 1
        | 2 ->
            printf "LDC "
            pc <- pc + 1
            let n = mem.[pc]
            printfn "%d" n
            push n
            pc <- pc + 1
        | 9 ->
            printfn "DROP"
            ignore <| pop ()
            pc <- pc + 1
        | _ ->
            failwith "unknown opcode"

[<EntryPoint>]
let main _ =
    run ()
    0
