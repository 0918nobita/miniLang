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
    match parse (token "ab") (bof, argv.[0]) with
    | Some { ast = _; currentLoc = loc; rest = rest } ->
        printfn "Success!"
        printfn "currentLoc: %s" <| loc.ToString ()
        printfn "rest: \"%s\"" rest
    | None ->
        printfn "Failed..."
    0
