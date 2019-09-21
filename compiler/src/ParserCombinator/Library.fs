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

exception ParserException of Location * (Location -> unit)

let parse (p : Parser<'a>) (loc : Location, src : string) =
    let result = p.parse (loc, src)
    match (result, p.error) with
    | (Some _, _) -> result
    | (None, None) -> None
    | (None, Some f) -> raise (ParserException (loc, f))

let fmap (f : 'a -> 'b) (p : Parser<'a>) =
    {
        parse = fun input ->
            input
            |> parse p
            |> Option.map (fun result ->
                {
                    ast = f result.ast
                    currentLoc = result.currentLoc
                    rest = result.rest
                })
        error = None
    }

let (<*>) precede succeed =
    {
        parse = fun input ->
            match parse precede input with
            | Some { ast = f ; currentLoc = precedeLoc; rest = rest } ->
                parse (fmap f succeed) (precedeLoc, rest)
            | None -> None
        error = None
    }

let (<|>) p q =
    {
        parse = fun input ->
            match parse p input with
            | Some _ as result -> result
            | None -> parse q input
        error = None
    }

let (|=) p f =
    {
        parse = fun input ->
            match parse p input with
            | Some { ast = ast; currentLoc = loc; rest = rest } ->
                parse (f ast) (loc, rest)
            | None -> None
        error = None
    }

let (|.) m f = m |= fun _ -> f

let token (tok : string) =
    {
        parse = fun (loc, src) ->
            if src.StartsWith tok
                then
                    let lines = tok.Split [|'\n'|]
                    let length = String.length tok
                    Some {
                        ast = (loc, tok)
                        currentLoc =
                            loc + {
                                line = Array.length lines - 1
                                chr = String.length <| Array.last lines
                            }
                        rest = src.Substring (length, (String.length src - length))
                    }
                else None
        error = None
    }

let succeed ast =
    {
        parse = fun (loc, rest) -> Some { ast = ast; currentLoc = loc; rest = rest }
        error = None
    }

let option defaultAst p = p <|> succeed defaultAst

let (<~>) p q =
    p |= fun r -> q |= fun rs -> succeed (r :: rs)

let rec many p =
    option [] (p |= fun r -> many p |= fun rs -> succeed (r :: rs))

let some p = p <~> many p

let drop p = p |. succeed ()

let expect p errorHandler =
    {
        parse = parse p
        error = Some errorHandler
    }

let mzero =
    {
        parse = fun _ -> None
        error = None
    }

let item =
    {
        parse = function
            | (_, "") -> None
            | (loc, src) ->
                let c = src.[0]
                Some {
                    ast = (loc, c)
                    currentLoc =
                        loc +
                        (if c = '\n'
                            then { line = 1; chr = 0 }
                            else { line = 0; chr  = 1 })
                    rest = src.Substring (1, (String.length src - 1))
                }
        error = None
    }
