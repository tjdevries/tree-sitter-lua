
let s:source_file = expand("<sfile>")

if get(g:, 'ts_lua_skip_queries', v:false)
  finish
endif

for file in glob(fnamemodify(s:source_file, ":h:h") . "/queries/lua/*", v:false, v:true) 
  call v:lua.vim.treesitter.set_query("lua", fnamemodify(file, ":t:r"), join(readfile(file), "\n"))
endfor
