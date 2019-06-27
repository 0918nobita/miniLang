type 'a parser = MParser of (string -> ('a * string) list)

let parse (MParser p) = p

let substr str start len =
  let str_len = String.length str in
    if str_len >= start + len then Some (String.sub str start len) else None

let token tok =
  let length = String.length tok in
    MParser (fun src ->
        match substr src 0 length with
          | Some cut when cut = tok ->
              [(cut, String.sub src length (String.length src - length))]
          | _ ->
              [] )

(* Function Composition *)
let ( <.> ) f g x = f @@ g x

let concatMap f = List.(concat <.> map f)


(* Functor *)

let fmap f p =
  MParser (fun src ->
    List.map (fun (a, str) -> (f a str)) @@ (parse p) src)


(* Applicative *)

(** Sequential application *)
let ( <*> ) precede succeed =
  MParser
    (fun src -> parse precede src
                |> concatMap (fun (f, str) ->
                    parse succeed str
                    |> List.map (fun (ast, str') -> (f ast, str'))))

let ( <$> ) = fmap


(* Monad *)

(**
  Sequentially compose two actions,
  passing any value produced by the first as a argumet to the second.
*)
let ( >>= ) p f =
  MParser
    (fun src -> parse p src
                |> concatMap (fun (a, str) -> parse (f a) str))

(**
  Sequentially compose two actions, discarding any value produced by the first,
  like sequencing operators (such as the semicolon) in imperative languages
*)
let ( >> ) m f = m >>= fun _ -> f


(*
  Alternative - A monoid on applicative functors
  MonadPlus - Monads that also support choice and failure
*)

(** The identity of '<|>' *)
let empty = MParser (fun _ -> [])

(** An associative binary operation *)
let ( <|> ) p q = MParser (fun src -> parse p src @ parse q src)


let mparser =
  token "a"
  >>= fun cut ->
  MParser (fun src ->
      let result = parse (token "b") src in
        List.map (fun (a, str) -> (cut ^ a, str)) result)
