local debug_utils = require "plenary.debug_utils"
local Path = require "plenary.path"

local M = {}

local QUERY_PATH = Path:new(vim.fn.fnamemodify(debug_utils.sourced_filepath(), ":p:h:h:h:h"), "query", "lua")

function M.get(name, lang)
  lang = lang or "lua"

  local filepath = QUERY_PATH / (name .. ".scm")

  return vim.treesitter.parse_query(lang, filepath:read())
end

--[[
print(vim.inspect(M.get('locals')))
--]]

return M
