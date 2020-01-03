let result = Parser.miniParser((Location.bof, "abc"));

Js.log(result); // Ok({ ast: "a!", currentLoc: { line: 0, chr: 1 }, rest: "bc" })
