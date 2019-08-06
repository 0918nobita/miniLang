build:
	make -C ./binary-utils
	make -C ./parser-combinator
	make -C ./compiler
	make -C ./swld

test:
	make -C ./test-suite test
