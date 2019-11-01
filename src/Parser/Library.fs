module Parser

open ParserCombinator

/// パーサのサンプル
let miniParser = (token "a" <|> token "b") |= (fun (_, x) -> succeed (x + "!"))
