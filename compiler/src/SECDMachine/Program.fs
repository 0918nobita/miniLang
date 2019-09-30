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

// LDC A(= 12)
mem.[0] <- 2; mem.[1] <- 12
// LDC B(= 26)
mem.[2] <- 2; mem.[3] <- 26
// LDC 5
mem.[4] <- 2; mem.[5] <- 5
// LDC 7
mem.[6] <- 2; mem.[7] <- 7
// ARGS 3
mem.[8] <- 3; mem.[9] <- 3
// APP
mem.[10] <- 4
// STOP
mem.[11] <- 0

// func A
// env addr
mem.[12] <- 35
// LD 0, 0
mem.[13] <- 1; mem.[14] <- 0; mem.[15] <- 0
// LD 0, 1
mem.[16] <- 1; mem.[17] <- 0; mem.[18] <- 1
// LD 0, 2
mem.[19] <- 1; mem.[20] <- 0; mem.[21] <- 2
// ARGS 2
mem.[22] <- 3; mem.[23] <- 2
// APP
mem.[24] <- 4
// RTN
mem.[25] <- 5

// func B
// env addr
mem.[26] <- 36
// LD 0, 0
mem.[27] <- 1; mem.[28] <- 0; mem.[29] <- 0
// LD 0, 1
mem.[30] <- 1; mem.[31] <- 0; mem.[32] <- 1
// SUB
mem.[33] <- 10
// RTN
mem.[34] <- 5

mem.[35] <- 0
mem.[36] <- 0

let mutable f = 37

let write value =
    mem.[f] <- value
    f <- f + 1

let advance () =
    c <- c + 1
    mem.[c]

let getElemFromList addr index =
    let mutable i = 0
    let mutable focusedAddr = addr
    let mutable elem = 0
    let mutable breakNow = false
    while (not breakNow) do
        if i = index
            then
                elem <- mem.[focusedAddr]
                breakNow <- true
            else
                if mem.[focusedAddr + 1] <> 0
                    then focusedAddr <- mem.[focusedAddr + 1]
                    else failwith "線形リスト上の探索に失敗しました"
        i <- i + 1
    elem

let prependElemToList (register : byref<int>) head =
    let headAddr = f
    write head
    write register
    register <- headAddr

let executeLD () =
    printf "LD "

    let frameIndex = advance ()
    printf "%d, " frameIndex

    let localVarIndex = advance ()
    printfn "%d" localVarIndex

    let frameAddr = getElemFromList e frameIndex
    let localVar = mem.[frameAddr + localVarIndex]
    push localVar
    c <- c + 1

let executeLDC () =
    printf "LDC "
    let literal = advance ()
    printfn "%d" literal
    push literal
    c <- c + 1

let executeARGS () =
    printf "ARGS "
    let length = advance ()
    printfn "%d" length
    let argsAddr = f
    let args = Stack<int>()
    for _ in 1 .. length do
        args.Push <| pop ()
    for arg in args do
        write arg
    push argsAddr
    c <- c + 1

let executeAPP () =
    printfn "APP"
    c <- c + 1
    let args = pop ()
    let closure = pop ()

    let dump = f
    let size = getStackSize ()
    write size
    for _ in 1 .. size do
        write <| pop ()
    write e
    write c

    prependElemToList &d dump
    prependElemToList &e mem.[closure]
    prependElemToList &e args

    c <- closure + 1

let run () =
    let mutable breakNow = false
    while not breakNow do
        let opcode = mem.[c]
        match opcode with
        | 0 ->
            printfn "STOP"
            breakNow <- true
        | 1 ->
            executeLD ()
        | 2 ->
            executeLDC ()
        | 3 ->
            executeARGS ()
        | 4 ->
            executeAPP ()
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
            let lhs = pop ()
            let rhs = pop ()
            push (lhs + rhs)
            c <- c + 1
        | 10 ->
            printfn "SUB"
            let lhs = pop ()
            let rhs = pop ()
            push (lhs - rhs)
            c <- c + 1
        | 11 ->
            printfn "MUL"
            let lhs = pop ()
            let rhs = pop ()
            push (lhs * rhs)
            c <- c + 1
        | 12 ->
            printfn "DIV"
            let lhs = pop ()
            let rhs = pop ()
            push (lhs / rhs)
            c <- c + 1
        | _ ->
            failwith "unknown opcode"

[<EntryPoint>]
let main _ =
    run ()
    printfn "Result: %i" <| pop ()
    0
