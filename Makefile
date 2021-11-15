ts := ./node_modules/tree-sitter-cli/tree-sitter

$(ts):
	npm ci

generate: | $(ts)
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
	mkdir -p build parser
	cc -o ./build/parser.so -I./src src/parser.c src/scanner.cc -shared -Os -lstdc++ -fPIC
	cp ./build/parser.so ./parser/lua.so

gen_howto:
	nvim --headless --noplugin -u tests/minimal_init.vim -c "luafile ./scratch/gen_howto.lua" -c 'qa'

lualint:
	luacheck lua/docgen

wasm: build_parser
	${ts} build-wasm

web: wasm
	${ts} web-ui
