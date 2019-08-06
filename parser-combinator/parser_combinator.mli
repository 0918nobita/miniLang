type location = { line : int; chr : int }

val string_of_loc : location -> string

val plus_loc : location -> location -> location

type 'a result = { ast : 'a; loc : location; rest : string }

type 'a parser = Parser of (location * string -> 'a result list)

val parse : 'a parser -> location * string -> 'a result list

val token : string -> (location * string) parser

val ( <$> ) : ('a -> 'b) -> 'a parser -> 'b parser

val ( <*> ) : ('a -> 'b) parser -> 'a parser -> 'b parser

val return : 'a -> 'a parser

val ( >>= ) : 'a parser -> ('a -> 'b parser) -> 'b parser

val ( >> ) : 'a parser -> 'b parser -> 'b parser

val ( <|> ) : 'a parser -> 'a parser -> 'a parser

val satisfy : (location * char -> bool) -> (location * char) parser

val char : char -> (location * char) parser

val oneOf : string -> (location * char) parser

val option : 'a -> 'a parser -> 'a parser

val many : 'a parser -> 'a list parser

val some : 'a parser -> 'a list parser

val drop : 'a parser -> unit parser
