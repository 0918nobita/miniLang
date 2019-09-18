type Expr =
    | IntLiteral of value : int
    | Add of lhs : Expr * rhs : Expr

let rec showExpr = function
    | IntLiteral(v) ->
        string(v)
    | Add(lhs, rhs) ->
        "Add(" + (showExpr lhs) + ", " + (showExpr rhs) + ")"

[<EntryPoint>]
let main argv =
    Add(
        lhs = IntLiteral(value = 3),
        rhs = IntLiteral(value = 4)
    )
    |> showExpr
    |> printfn "%s"
    0
