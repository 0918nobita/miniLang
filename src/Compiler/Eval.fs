module Eval

/// Expressed Value (式の値)
type ExpVal =
    | IntV of int
    | BoolV of bool

/// Denotated Value (変数が指示する値)
type DnVal = ExpVal

exception NotBoundException

open Syntax

module Env =
    type T<'a> = (Ident * 'a) list

    let empty: T<'a> = []
    let extend (x: Ident) (v: 'a) (env: T<'a>): T<'a> = (x, v) :: env

    let rec lookup (x: Ident) (env: T<'a>) =
        try
            List.find (fst >> ((=) x)) env |> snd
        with :? System.Collections.Generic.KeyNotFoundException ->
            raise NotBoundException

    let rec map (f: 'a -> 'b) (env: T<'a>): T<'b> =
        match env with
        | [] -> []
        | (ident, v) :: rest -> (ident, f v) :: (map f rest)

let initialEnv =
    Env.extend "i" (IntV 2) Env.empty
    |> Env.extend "v" (IntV 5)
    |> Env.extend "x" (IntV 1)

let rec applyPrim op arg1 arg2 =
    match op, arg1, arg2 with
    | Plus, IntV i1, IntV i2 -> IntV(i1 + i2)
    | Plus, _, _ -> failwith "TypeError (+)"
    | Mult, IntV i1, IntV i2 -> IntV(i1 * i2)
    | Mult, _, _ -> failwith "TypeError (*)"
    | Lt, IntV i1, IntV i2 -> BoolV(i1 < i2)
    | Lt, _, _ -> failwith "TypeError (<)"

let rec evalExpr env =
    function
    | Var x -> Env.lookup x env
    | ILit i -> IntV i
    | BLit b -> BoolV b
    | BinExpr(op, lhs, rhs) ->
        let arg1 = evalExpr env lhs
        let arg2 = evalExpr env rhs
        applyPrim op arg1 arg2
    | IfExpr(cond, thenClause, elseClause) ->
        let condVal = evalExpr env cond
        match condVal with
        | BoolV true -> evalExpr env thenClause
        | BoolV false -> evalExpr env elseClause
        | _ -> failwith "TypeError (if)"

let evalDecl env (Expr e) =
    let v = evalExpr env e
    ("-", env, v)
