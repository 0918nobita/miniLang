let orElseWith = (result: result('a, 'b), other: unit => result('a, 'c)) =>
  switch (result) {
  | Ok(_) as r => r
  | Error(_) => other()
  };
