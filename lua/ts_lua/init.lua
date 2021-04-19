R('plenary')

local plenary_debug = require('plenary.debug_utils')

local Path = require('plenary.path')
local Iter = require('plenary.iterators')

local ts_lua_dir = vim.fn.fnamemodify(plenary_debug.sourced_filepath(), ":h:h:h")

local M = {}

M.setup = function(opts)
  opts = opts or {}

  if opts.enable_grammar then
    local queries_dir = Path:new(ts_lua_dir) / "queries" / "lua"
    local queries = Iter.iter(vim.fn.glob(queries_dir:absolute() .. "/*", false, true))

    queries
      :map(function(v) return Path:new(v) end)
      :for_each(function(query) 
        print(query.stem)
        -- vim.treesitter.set_query("lua", query:head()
      end)

  end
end

M.setup { enable_grammar = true }

return M
