open Location;

module MakeParsec = (S: {type errorType;}) => {
  type success('a) = {
    ast: 'a,
    currentLoc: location,
    rest: string,
  };

  type failure = {
    range: (location, location),
    cause: option(S.errorType),
  };

  type parser('a) = ((location, string)) => result(success('a), failure);

  let map = (f: 'a => 'b, parse: parser('a)): parser('b) =>
    input =>
      switch (parse(input)) {
      | Ok(success) => Ok({...success, ast: f(success.ast)})
      | _ as result => result
      };

  let token = (tok: string): parser((location, string)) =>
    ((loc, target)) =>
      if (Js.String.startsWith(tok, target)) {
        let lines = Js.String.split(tok, "\n");
        let len = String.length(tok);
        Ok({
          ast: (loc, tok),
          currentLoc:
            append_loc(
              loc,
              {
                line: Array.length(lines) - 1,
                chr: String.length(Array_ex.last(lines)),
              },
            ),
          rest: String.sub(target, len, String.length(target) - len),
        });
      } else {
        Error({range: (loc, loc), cause: None});
      };

  module ParserMonad =
    Monad.MakeMonad({
      type t('a) = parser('a);

      let bind = (m, f, input) =>
        switch (m(input)) {
        | Ok({ast, currentLoc, rest}) => f(ast, (currentLoc, rest))
        | Error(_) as result => result
        };

      let empty = ((loc, _)) => Error({range: (loc, loc), cause: None});

      let singleton = (ast, (loc, target)) =>
        Ok({ast, currentLoc: loc, rest: target});
    });

  module Operators = {
    let (<*>) =
        (precede: parser('a => 'b), succeed: parser('a)): parser('b) =>
      input =>
        switch (precede(input)) {
        | Ok({ast: f, currentLoc: precedeLoc, rest}) =>
          map(f, succeed, (precedeLoc, rest))
        | Error(failure) => Error(failure)
        };

    let (<|>) = (p: parser('a), q: parser('a)): parser('a) =>
      input => Result.orElseWith(p(input), () => q(input));
  };
};
