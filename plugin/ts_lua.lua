if vim.g.ts_lua_skip_queries then
  return
end

local root = require("ts_lua").plugin_dir
vim.treesitter.language.add("lua", {
  path = root .. "/parser/lua.so",
})

for _, file in ipairs(vim.fn.glob(root .. "/queries/lua/*", false, true)) do
  vim.treesitter.query.set("lua", vim.fn.fnamemodify(file, ":t:r"), table.concat(vim.fn.readfile(file), "\n"))
end
