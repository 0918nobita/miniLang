build:
	make -C ./compiler
	make -C ./swld

test:
	make -C ./test-suite test
