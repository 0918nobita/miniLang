open System.Collections.Generic

let mem = Array.init 100000 (fun _ -> 0)

let mutable pc = 0

let mutable sp = 99999

let push n =
    mem.[sp] <- n
    sp <- sp - 1

let pop () =
    sp <- sp + 1
    mem.[sp]

let env = Stack<Dictionary<string, int>>()

let run () =
    let mutable breakNow = false
    while not breakNow do
        let opcode = mem.[pc]
        match opcode with
        | 0 ->
            printfn "STOP"
            breakNow <- true
        | _ ->
            failwith "unknown opcode"

[<EntryPoint>]
let main _ =
    run ()
    0
