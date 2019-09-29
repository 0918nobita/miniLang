open System.Collections.Generic

let mem = Array.init 100000 (fun _ -> 0)

let mutable c = 0

let mutable e = 0

let mutable d = 0

let mutable sp = 99999

let push n =
    printfn "  (Push %d)" n
    mem.[sp] <- n
    sp <- sp - 1

let pop () =
    sp <- sp + 1
    printfn "  (Pop %d)" mem.[sp]
    mem.[sp]

let getStackSize () =
    99999 - sp

let clearStack () =
    sp <- 99999

// LDC 8
mem.[0] <- 2; mem.[1] <- 8
// LDC 2
mem.[2] <- 2; mem.[3] <- 2
// ARGS 1
mem.[4] <- 3; mem.[5] <- 1
// APP
mem.[6] <- 4
// STOP
mem.[7] <- 0

// env addr
mem.[8] <- 17
// LD 0, 0
mem.[9] <- 1; mem.[10] <- 0; mem.[11] <- 0
// LDC 1
mem.[12] <- 2; mem.[13] <- 1
// ADD
mem.[14] <- 9
// RTN
mem.[15] <- 5

// クロージャの持つ環境 (線形リスト、ここでは nil)
mem.[16] <- 0

let mutable f = 17

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
            let frame = mem.[e + i]
            push mem.[frame + j]
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
        | 4 ->
            printfn "APP"
            c <- c + 1
            let args = pop ()
            let closure = pop ()
            let dump = f
            let size = getStackSize ()
            mem.[f] <- size
            f <- f + 1

            for _ in 1 .. size do
                mem.[f] <- pop ()
                f <- f + 1

            mem.[f] <- e
            f <- f + 1
            mem.[f] <- c
            f <- f + 1
            let d' = f
            mem.[f] <- dump
            f <- f + 1
            mem.[f] <- d
            f <- f + 1
            d <- d'
            let e' = f
            mem.[f] <- mem.[closure]
            f <- f + 1
            mem.[f] <- e
            f <- f + 1
            e <- e'
            let e'' = f
            mem.[f] <- args
            f <- f + 1
            mem.[f] <- e'
            f <- f + 1
            e <- e''
            c <- closure + 1
        | 5 ->
            printfn "RTN"
            let dump = mem.[d]
            d <- mem.[d + 1]
            let rv = pop ()
            clearStack ()
            let mutable i = 0

            while i < mem.[dump] do
                push mem.[dump + i + 1]
                i <- i + 1

            push rv
            e <- mem.[dump + i + 1]
            c <- mem.[dump + i + 2]
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
    printfn "\n%A\n" mem
    printfn "Result: %d" <| pop ()
    0
