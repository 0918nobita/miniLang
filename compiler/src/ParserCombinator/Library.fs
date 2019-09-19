module ParserCombinator

type Location =
    { line : int; chr : int }
    override m.ToString () =
        string(m.line + 1) + ":" + string(m.chr + 1)
    static member (+) (lhs : Location, rhs : Location) =
        {
            line = lhs.line + rhs.line
            chr = if rhs.line >= 1 then rhs.chr else lhs.chr + rhs.chr
        }

let bof = { line = 0; chr = 0 }

type Success<'a> =
    { ast : 'a; currentLoc : Location; rest : string }

type Parser<'a> =
    {
        parse : Location * string -> 'a Success option
        error : (Location -> unit) option
    }

let parse (p : Parser<'a>) (loc : Location) (src : string) =
    let result = p.parse (loc, src)
    match (result, p.error) with
    | (Some _, _) -> result
    | (None, None) -> None
    | (None, Some f) -> f (loc); failwith "SyntaxError"

let succeed ast =
    {
        parse = fun (loc, rest) -> Some { ast = ast; currentLoc = loc; rest = rest }
        error = None
    }
