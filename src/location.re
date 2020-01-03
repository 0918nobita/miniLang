type location = {
  line: int,
  chr: int,
};

let bof = {line: 0, chr: 0};

let string_of_location = (loc: location) =>
  string_of_int(loc.line + 1) ++ ":" ++ string_of_int(loc.chr + 1);

let append_loc = (lhs: location, rhs: location) => {
  line: lhs.line + rhs.line,
  chr:
    if (rhs.line >= 1) {
      rhs.chr;
    } else {
      lhs.chr + rhs.chr;
    },
};
