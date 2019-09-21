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
