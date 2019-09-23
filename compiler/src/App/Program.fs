open ParserCombinator

type Expr =
    | IntLiteral of loc : Location * value : int
    | Add of loc : Location * lhs : Expr * rhs : Expr
    | Sub of loc : Location * lhs : Expr * rhs : Expr

[<EntryPoint>]
let main argv =
    printfn "%A" <| IntLiteral(bof, 8)
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
