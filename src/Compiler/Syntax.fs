module Syntax

type Ident = string

type BinOp =
    | Plus
    | Mult
    | Lt

type Expr =
    | Var of Ident
    | ILit of int
    | BLit of bool
    | BinExpr of op: BinOp * lhs: Expr * rhs: Expr
    | IfExpr of cond: Expr * _then: Expr * _else: Expr

type Program = Expr of Expr

type TyVar = int

type Ty =
    | TyInt
    | TyBool
    | TyVar of TyVar
    | TyFun of Ty * Ty
    | TyList of Ty
