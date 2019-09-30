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
// LDC 3
mem.[2] <- 2; mem.[3] <- 3
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
// LDC 7
mem.[12] <- 2; mem.[13] <- 7
// MUL
mem.[14] <- 10
// RTN
mem.[15] <- 5

// クロージャの持つ環境 (線形リスト、ここでは nil)
mem.[16] <- 0

let mutable f = 17

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
    let localVar = getElemFromList frameAddr localVarIndex
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
    for _ in 1 .. length do
        write <| pop ()
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
            let rhs = pop ()
            let lhs = pop ()
            push (lhs + rhs)
            c <- c + 1
        | 10 ->
            printfn "SUB"
            let rhs = pop ()
            let lhs = pop ()
            push (lhs - rhs)
            c <- c + 1
        | 11 ->
            printfn "MUL"
            let rhs = pop ()
            let lhs = pop ()
            push (lhs * rhs)
            c <- c + 1
        | 12 ->
            printfn "DIV"
            let rhs = pop ()
            let lhs = pop ()
            push (lhs / rhs)
            c <- c + 1
        | _ ->
            failwith "unknown opcode"

[<EntryPoint>]
let main _ =
    run ()
    printfn "\n%A\n" mem
    printfn "Result: %d" <| pop ()
    0
