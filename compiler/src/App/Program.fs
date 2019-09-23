open ParserCombinator

type Expr =
    | IntLiteral of value : int
    | Add of lhs : Expr * rhs : Expr

let rec showExpr =
    function
    | IntLiteral(v) ->
        string (v)
    | Add(lhs, rhs) ->
        "Add(" + (showExpr lhs) + ", " + (showExpr rhs) + ")"

type ZeroBuilder() =
    member __.Zero() =
        printfn "computation expressions!"

let zero = ZeroBuilder()

// ビルダー式に関係のない式のみを記述した場合には、
// Zero メソッドの呼び出しが挿入される
zero { () }
zero { printfn "Hello" }
zero { printf "Hello "; printfn "F#" }

// builder-expr { cexpr } は
//   let b = builder-expr in
//   b.Run(<@ b.Delay(fun () -> cexpr) @>)
// のように展開される

open FSharp.Quotations

type SampleBuilder() =
    member __.Zero() = ()
    member __.Quote() = ()
    member __.Run(expr: Expr<_>) =
        printfn "%A" expr

let s = SampleBuilder()

s { printfn "HELLO" }

type OptionBuilder() =
    member __.Return(x) = Some x
    member __.ReturnFrom(x: _ option) = x
    member __.Bind(x, f) =
        Option.bind f x

let opt = OptionBuilder()

printfn "%A" <| opt { return 0 }  // opt.Return(0)
printfn "%A" <| opt { return! Some 27 }  // opt.ReturnFrom(Some 27)

printfn "%A" <| opt { let! a = Some 1 in return a }
// opt.Bind(Some 1, fun a -> option.Return(a))

[<EntryPoint>]
let main argv =
    if Array.isEmpty argv
        then -1
        else
            let simpleParser =
                some <| oneOf "1234"

            try
                let result = parse simpleParser (bof, argv.[0])

                match result with
                | Some { ast = _; currentLoc = loc; rest = rest } ->
                    printfn "Success!"
                    printfn "currentLoc: %s" <| loc.ToString ()
                    printfn "rest: \"%s\"" rest
                    0
                | None ->
                    printfn "Failed..."
                    -1
            with
            | ParserException (loc, f) ->
                f loc
                -1
