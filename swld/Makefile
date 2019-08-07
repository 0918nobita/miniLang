MLI_FILES := parser.mli

ML_FILES := parser.ml swld.ml

ifndef MAKE_DEPS
	MAKE_DEPS=true
endif

build:
ifeq ($(MAKE_DEPS),true)
	make -C ../parser-combinator
endif
	mkdir -p _build
	ocamlopt -I ../parser-combinator $(MLI_FILES)
	ocamlfind ocamlopt -linkpkg -package base -w +a -o _build/swld \
		-I ../parser-combinator \
		../parser-combinator/parser_combinator.cmx $(ML_FILES)
	rm -f *.cmx *.o

utop:
	make -C ../parser-combinator for-toplevel
	ocamlc -I ../parser-combinator $(MLI_FILES)
	ocamlfind ocamlc -linkpkg -package base -c -w +a \
		-I ../parser-combinator \
		../parser-combinator/parser_combinator.cmo $(ML_FILES)
	utop -require base \
		-I ../parser-combinator \
		../parser-combinator/parser_combinator.cmo

clean:
	rm -f *.cmi *.cmo *.cmx *.o
