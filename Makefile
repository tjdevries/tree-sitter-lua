ts := "./node_modules/tree-sitter-cli/tree-sitter"

ifeq (, ${ts})
	ts := $(shell which tree-sitter 2> /dev/null)
endif

ifeq (, ${ts})
	ts := $(shell which tree-sitter-cli 2> /dev/null)
endif

generate:
	${ts} generate

test: generate
	make test_ts
	make test_docgen

test_ts: generate
	nvim --headless -c "luafile ./lua/tests_to_corpus.lua" -c "qa!"
	${ts} test

test_docgen: generate
	nvim \
		--headless \
		--noplugin \
		-u tests/minimal_init.vim \
		-c "PlenaryBustedDirectory lua/tests/ {minimal_init = 'tests/minimal_init.vim'}"

build_parser: generate
	mkdir -p build
	cc -o ./build/parser.so -I./src src/parser.c src/scanner.cc -shared -Os -lstdc++ -fPIC

gen_howto:
	nvim --headless --noplugin -u tests/minimal_init.vim -c "luafile ./scratch/gen_howto.lua" -c 'qa'

wasm: build_parser
	${ts} build-wasm

web: wasm
	${ts} web-ui
