local plenary_debug = require "plenary.debug_utils"

-- local Path = require "plenary.path"
-- local Iter = require "plenary.iterators"

local ts_lua_dir = vim.fn.fnamemodify(plenary_debug.sourced_filepath(), ":h:h:h")

local M = {}

M.plugin_dir = ts_lua_dir

return M
