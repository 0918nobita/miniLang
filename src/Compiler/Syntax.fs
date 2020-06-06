module Syntax

type Ident = string

type BinOp =
    | Plus
    | Mult
    | Lt

type Exp =
    | Var of Ident
    | ILit of int
    | BLit of bool
    | BinExp of op: BinOp * lhs: Exp * rhs: Exp
    | IfExp of cond: Exp * _then: Exp * _else: Exp

type Program = Exp of Exp

type TyVar = int

type Ty =
    | TyInt
    | TyBool
    | TyVar of TyVar
    | TyFun of Ty * Ty
    | TyList of Ty
