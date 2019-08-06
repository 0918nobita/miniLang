build:
	mkdir -p _build
	ocamlopt -w +a -o _build/swld swld.ml
	rm -f *.cmx *.o

utop:
	make -C ../parser-combinator for-toplevel
	ocamlfind ocamlc -linkpkg -package base -c -w +a \
		-I ../parser-combinator ../parser-combinator/parser_combinator.cmo swld.ml
	utop -require base -I ../parser-combinator ../parser-combinator/parser_combinator.cmo

clean:
	rm -f *.cmi *.cmo *.cmx *.o
