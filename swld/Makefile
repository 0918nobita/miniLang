ifndef MAKE_DEPS
	MAKE_DEPS=true
endif

build:
ifeq ($(MAKE_DEPS),true)
	make -C ../parser-combinator
endif
	mkdir -p _build
	ocamlfind ocamlopt -linkpkg -package base -w +a -o _build/swld \
		-I ../parser-combinator ../parser-combinator/parser_combinator.cmx swld.ml
	rm -f *.cmx *.o

utop:
	make -C ../parser-combinator for-toplevel
	ocamlfind ocamlc -linkpkg -package base -c -w +a \
		-I ../parser-combinator ../parser-combinator/parser_combinator.cmo swld.ml
	utop -require base -I ../parser-combinator ../parser-combinator/parser_combinator.cmo

clean:
	rm -f *.cmi *.cmo *.cmx *.o
