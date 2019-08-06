build:
	ocamlopt parser_combinator.mli
	ocamlfind ocamlopt -linkpkg -package base -c -w +a parser_combinator.ml

for-toplevel:
	ocamlc parser_combinator.mli
	ocamlfind ocamlc -linkpkg -package base -c -w +a parser_combinator.ml

clean:
	rm -f *.cmi *.cmo *.cmx *.o
