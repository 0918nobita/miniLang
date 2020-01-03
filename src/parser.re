module ParserCombinator =
  Parsec.MakeParsec({
    type errorType = unit;
  });

let miniParser =
  ParserCombinator.(
    {
      ParserMonad.(token("a") >>= (((_, s)) => return(s ++ "!")));
    }
  );
