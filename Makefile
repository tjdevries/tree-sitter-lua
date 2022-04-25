ts := tree-sitter

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
	cc -o ./build/parser.so -I./src src/parser.c src/scanner.c -shared -Os -lstdc++ -fPIC

gen_howto:
	nvim --headless --noplugin -u tests/minimal_init.vim -c "luafile ./scratch/gen_howto.lua" -c 'qa'

lualint:
	luacheck lua/docgen

dist:
	mkdir -p parser
	cc -o ./parser/lua.so -I./src src/parser.c src/scanner.c -shared -Os -lstdc++ -fPIC

wasm: build_parser
	${ts} build-wasm

web: wasm
	${ts} web-ui
