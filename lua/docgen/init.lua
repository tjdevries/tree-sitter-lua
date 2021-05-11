local call_transformer = require('docgen.transformers')
local log = require('docgen.log')
local utils = require('docgen.utils')

local read = utils.read

---@brief [[
--- Public API for all associated docgen procedures.
---
--- Supported tags:
---     - @brief:
---         - Usage:
--- <pre>
--- ---@brief [[
--- --- You can put things you want to say about the project here.
--- --- It gets put at the top of the help file.
--- ---@brief ]]

---@brief ]]

---@tag docgen

-- Load up our build parser.
vim.treesitter.require_language("lua", "./build/parser.so", true)

local docgen = {}

docgen.debug = false

function docgen._get_query_text(query_name)

  return read(vim.api.nvim_get_runtime_file(
    string.format('query/lua/%s.scm', query_name), false
  )[1])
end

--- Get the query for a tree sitter query, loaded from query directory.
---@param query_name string: The name of the query file (without .scm)
function docgen.get_ts_query(query_name)
  return vim.treesitter.parse_query("lua", docgen._get_query_text(query_name))
end

--- Get the string parser for some contents
function docgen.get_parser(contents)
  return vim.treesitter.get_string_parser(contents, "lua")
end

--- Run {cb} on each node from contents and query
---@param contents string: Contents to pass to string parser
---@param query_name string: Name of the query to search for
---@param cb function: Function to call on captures with (id, node)
function docgen.foreach_node(contents, query_name, cb)
  local parser = docgen.get_parser(contents)
  local query = docgen.get_ts_query(query_name)

  local tree = parser:parse()[1]

  for id, node in query:iter_captures(tree:root(), contents, 0, -1) do
    log.debug(id, node:type())

    cb(id, node)
  end
end

function docgen.transform_nodes(contents, query_name, toplevel_types, return_module)
  local t = {}
  docgen.foreach_node(contents, query_name, function(id, node)
    if toplevel_types[node:type()] then
      local ok, result = pcall(call_transformer, t, contents, node, return_module)
      if not ok then
        print("ERROR:", id, node, result)
      end
    end
  end)

  return t
end

local function find_return_module(contents)
  local parser = docgen.get_parser(contents)
  -- Its better to just have one query here. That way i know as soon as i found the
  -- module return statement i am done. Its bad for performance that i am parsing the
  -- file twice now but its no performance critical thing, so nvm
  local query = vim.treesitter.parse_query("lua", "(module_return_statement (identifier) @exported)")

  local tree = parser:parse()[1]

  for _, node in query:iter_captures(tree:root(), contents, 0, -1) do
    return require'vim.treesitter.query'.get_node_text(node, contents)
  end
end

function docgen.get_nodes(contents)
  local query_name = 'documentation'
  local toplevel_types = {
    variable_declaration = true,
    function_statement = true,
    documentation_brief = true,
    documentation_tag = true,
    documentation_config = true,
    documentation_class = true
  }

  -- Can be nil here. That way it still works if the file only has a brief.
  -- I do the nil check in the transformer _function
  local return_module = find_return_module(contents)

  return docgen.transform_nodes(contents, query_name, toplevel_types, return_module)
end

function docgen.write(input_file, output_file_handle)
  log.trace("Transforming:", input_file)
  local contents = read(input_file)
  local resulting_nodes = docgen.get_nodes(contents)

  if docgen.debug then print("Resulting Nodes:", vim.inspect(resulting_nodes)) end

  local result = require('docgen.help').format(resulting_nodes)
  output_file_handle:write(result)
end

function docgen.test()
  local input_dir = "./lua/docgen/"
  local input_files = vim.fn.globpath(input_dir, "**/*.lua", false, true)

  -- Always put init.lua first, then you can do other stuff.
  table.sort(input_files, function(a, b)
    if string.find(a, "init.lua") then
      return true
    elseif string.find(b, "init.lua") then
      return false
    else
      return a < b
    end
  end)

  local output_file = "./scratch/docgen_output.txt"
  local output_file_handle = io.open(output_file, "w")

  for _, input_file in ipairs(input_files) do
    docgen.write(input_file, output_file_handle)
  end

  output_file_handle:write(" vim:tw=78:ts=8:ft=help:norl:")
  output_file_handle:close()
  vim.cmd [[checktime]]
end

--[[
 ["M.example"] = {
     name = "M.example",
    description = "--- Example function",
    parameters = {
      a = {
        description = { "This is a number" },
        name = "a",
        type = "number"
      },
      b = {
        description = { "Also a number" },
        name = "b",
        type = "number"
      }
    }
  }
--]]


return docgen
