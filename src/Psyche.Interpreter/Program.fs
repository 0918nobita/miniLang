open ParserCombinator

type Symbol = string

type TypeSig =
    | IntType
    | BoolType
    | FuncType of TypeSig * TypeSig

type Ast =
    | BoolLiteral of bool
    | IntLiteral of int
    | Add of Ast * Ast
    | Sub of Ast * Ast
    | Mov of Ast * Ast
    | Div of Ast * Ast
    | Variable of int
    | Let of Ast * Ast
    | Lambda of TypeSig * Ast
    | App of Ast * Ast

exception ParamTypeMismatchException of expected : TypeSig * actual : TypeSig

exception CannotCallException of TypeSig

let rec typeOfAst = function
    | (_, BoolLiteral _) -> BoolType
    | (_, IntLiteral _) -> IntType
    | (env, Add (lhs, rhs))
    | (env, Sub (lhs, rhs))
    | (env, Mov (lhs, rhs))
    | (env, Div (lhs , rhs)) ->
        let typeOfLhs = typeOfAst (env, lhs)
        if typeOfLhs <> IntType
            then raise <| ParamTypeMismatchException (IntType, typeOfLhs)
        let typeOfRhs = typeOfAst (env, rhs)
        if typeOfRhs <> IntType
            then raise <| ParamTypeMismatchException (IntType, typeOfRhs)
        IntType
    | (env : list<TypeSig>, Variable index) ->
        env.[index]
    | (env, Let (expr1, expr2)) ->
        let typeOfExpr1 = typeOfAst (env, expr1)
        typeOfAst (typeOfExpr1 :: env, expr2)
    | (env, Lambda (paramType, expr)) ->
        FuncType (IntType, typeOfAst (paramType :: env, expr))
    | (env, App (func, param)) ->
        let typeOfFunc = typeOfAst (env, func)
        let typeOfParam = typeOfAst (env, param)
        match typeOfFunc with
        | FuncType (p, r) ->
            if p = typeOfParam
                then r
                else raise <| ParamTypeMismatchException (p, typeOfParam)
        | _ ->
            raise <| CannotCallException typeOfFunc

try
    // (λ . 3 + #0) 4
    let ast =
        App (
            Lambda (IntType, Add (IntLiteral 3, Variable 0)),
            IntLiteral 4)
    printfn "%A" (typeOfAst ([], ast))  // => IntType
with
| ParamTypeMismatchException (expected, actual) ->
    printfn "(Param type mismatch) Expected: %A, Actual: %A" expected actual
    exit 1
| CannotCallException expr ->
    printfn "(Cannot call) %A" expr
    exit 1

type MaybeBuilder () =
    member this.Bind (x, f) =
        match x with
            | Some(x) -> f x
            | _ -> None
    member this.Delay (f) = f ()
    member this.Return (x) = Some x

type IntStringBuilder () =
    member this.Bind (m : string, f) =
        let (b, i) = System.Int32.TryParse (m)
        match b with
        | true -> f i
        | false -> failwith "変換に失敗"
    member this.Return (x) = x

type MParsecBuilder () =
    member this.Bind (p, f) =
        {
            parse = fun input ->
                match parse p input with
                | Some { ast = ast; currentLoc = loc; rest = rest } ->
                    parse (f ast) (loc, rest)
                | None -> None
            error = None
        }
    member this.Return (ast) =
        {
            parse = fun (loc, rest) -> Some { ast = ast; currentLoc = loc; rest = rest }
            error = None
        }

[<EntryPoint>]
let main argv =
    (*
    if Array.isEmpty argv then exit(1)

    let maybe = MaybeBuilder()
    maybe {
        let x = 11
        let! y = Some 22
        let! z = Some 33
        return x + y + z
    }
    |> printfn "%A" // => 66

    let intstring = IntStringBuilder()
    intstring {
        let! a = "3"
        let! b = "4"
        return a + b
    } |> printfn "%A" // => 7

    // "ac" または "bc" を受理して、１文字目と "!" を結合した文字列を返すパーサ
    let parser = MParsecBuilder()
    parser {
        let! (_, first) = token "a" <|> token "b"
        do! drop <| token "c"
        return first + "!"
    }
    |> (fun p -> parse p (bof, argv.[0]))
    |> printfn "%A"
    *)
    0
