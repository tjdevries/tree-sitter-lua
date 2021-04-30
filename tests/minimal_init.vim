
set rtp+=.
set rtp+=../plenary.nvim

runtime! plugin/plenary.vim
<<<<<<< HEAD

lua << EOF
-- Add ONLY our queries to the test setup.
local read_query = function(filename)
  return table.concat(vim.fn.readfile(vim.fn.expand(filename)), "\n")
end

for _, file in ipairs(vim.fn.glob("./queries/lua/*.scm", false, true)) do
  vim.treesitter.set_query("lua", vim.fn.fnamemodify(file, ":t:r"), read_query(file))
end
EOF
=======
runtime! plugin/ts_lua.vim
>>>>>>> use function_body instead of body:
