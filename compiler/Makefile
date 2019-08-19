MLI_FILES := parser.mli wast.mli wasm.mli stack_func.mli ir.mli

ML_FILES := parser.ml wast.ml wasm.ml malloc_func.ml stack_func.ml ir.ml compiler.ml

ifndef MAKE_DEPS
	MAKE_DEPS=true
endif

build:
ifeq ($(MAKE_DEPS),true)
	make -C ../binary-utils
	make -C ../parser-combinator
endif
	mkdir -p _build
	ocamlopt -I ../parser-combinator $(MLI_FILES)
	ocamlfind ocamlopt \
		-o _build/psyche \
		-linkpkg -package base,stdio -w +a \
		-I ../binary-utils -I ../parser-combinator \
		../binary-utils/binary.cmx ../parser-combinator/parser_combinator.cmx \
		$(ML_FILES)
	rm -f *.cmx *.o

utop:
	make -C ../binary-utils for-toplevel
	make -C ../parser-combinator for-toplevel
	ocamlc -I ../parser-combinator $(MLI_FILES)
	ocamlfind ocamlc -linkpkg -package base,stdio -c -w +a \
		-I ../binary-utils -I ../parser-combinator \
		../binary-utils/binary.cmo ../parser-combinator/parser_combinator.cmo \
		$(ML_FILES)
	utop -require base -I ../binary-utils -I ../parser-combinator \
		../binary-utils/binary.cmo ../parser-combinator/parser_combinator.cmo

for-debugging:
	make -C ../binary-utils for-toplevel
	make -C ../parser-combinator for-toplevel
	mkdir -p _build
	ocamlc -I ../parser-combinator $(MLI_FILES)
	ocamlfind ocamlc -g -o _build/psyche -linkpkg -package base,stdio \
		-I ../binary-utils -I ../parser-combinator \
		../binary-utils/binary.cmo ../parser-combinator/parser_combinator.cmo \
		$(ML_FILES)
	rm -f *cmo

clean:
	rm -rf _build
	rm -f *.cmi *.cmo *.cmx *.o
