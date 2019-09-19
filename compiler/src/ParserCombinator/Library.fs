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

type Result<'a> =
    { ast : 'a; currentLoc : Location; rest : string }

type Parser<'a> =
    {
        parse : Location * string -> 'a Result List
        error : (Location -> unit) option
    }

let pureParser ast =
    {
        parse = fun (loc, rest) -> [{ ast = ast; currentLoc = loc; rest = rest }]
        error = None
    }
