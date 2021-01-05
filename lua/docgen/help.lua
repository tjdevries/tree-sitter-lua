local log = require('docgen.log')
local utils = require('docgen.utils')

---@brief [[
--- All help formatting related utilties. Used to transform output from |docgen| into vim style documentation.
--- Other documentation styles are possible, but have not yet been implemented.
---@brief ]]

---@tag docgen-help-formatter
local help = {}

local map = vim.tbl_map
local values = vim.tbl_values

local align_text = function(left, right, width)
  left = left or ''
  right = right or ''

  local remaining = width - #left - #right

  return string.format("%s%s%s", left, string.rep(" ", remaining), right)
end

local doc_wrap = function(text, opts)
  opts = opts or {}

  local prefix = opts.prefix or ''
  local width = opts.width or 70
  -- local is_func = opts.width or false
  local indent = opts.indent

  if not width then
    return text
  end

  if indent == nil then
    indent = string.rep(' ', #prefix)
  end

  -- local indent_only = (prefix == '') and (indent ~= nil)

  -- if is_func then
  --   return text
  -- end

  return utils.wrap(text, opts.width, indent, indent)
end

--- Format an entire generated metadata from |docgen|
---@param metadata table: The metadata from docgen
help.format = function(metadata)
  if vim.tbl_isempty(metadata) then
    return ''
  end

  local formatted = ''

  local add = function(text, no_nl)
    formatted = formatted .. (text or '') .. (no_nl and '' or "\n")
  end

  -- TODO: Make top level

  add(string.rep('=', 80) )
  if metadata.tag then
    add(align_text(nil, "*" .. metadata.tag .. "*", 80))
    add()
  end

  -- Make brief
  if metadata.brief then
    local result = help.format_brief(metadata.brief)

    if not result then error("Missing result") end

    add(result)
    add()
  end

  -- Make functions
  for _, v in pairs(metadata.functions or {}) do
    local result = help.format_function_metadata(v)
    if not result then error("Missing result") end

    add(result)
    add()
  end

  add()

  return formatted
end

help.format_brief = function(brief_metadata)
  return doc_wrap(table.concat(brief_metadata, " "))
end

help.format_function_metadata = function(metadata)
  local space_prefix = string.rep(" ", 8)

  local name = metadata.name
  local parameter_names = map(function(val)
    return val.name
  end, values(metadata.parameters))


  local left_side = string.format(
    "%s(%s)",
    name,
    table.concat(map(
      function(val) return string.format("{%s}", val) end,
      parameter_names
    ), ", ")
  )

  local right_side = string.format("*%s()*", name)

  local header = align_text(left_side, right_side, 78)

  local doc = ""
  doc = doc .. header  .. "\n"

  -- TODO(conni2461): I don't think thats the best idea to do that but it works for now.
  -- It kinda looks not right for us but i also don't want to write a 200 chars long
  -- line description
  for _, v in ipairs(metadata.description) do
    local description = doc_wrap(v, {
      prefix = space_prefix,
      width = 80,
    })
    doc = doc .. description .. "\n"
  end

  if not vim.tbl_isempty(metadata["parameters"]) then
    -- TODO: This needs to handle strings that get wrapped.

    local parameter_header = string.format("%sParameters: ~", space_prefix)
    local parameter_docs = table.concat(
      map(function(val)
        local param_prefix = string.format(
          "%s    {%s} (%s)  ",
          space_prefix,
          val,
          metadata.parameters[val].type
        )

        local empty_prefix = string.rep(" ", #param_prefix)

        local result = ''
        for i, v in ipairs(metadata.parameters[val].description) do
          if i == 1 then
            result = param_prefix .. v
          else
            result = result .. string.format("%s%s", empty_prefix, v)
          end
        end

        return result
      end, parameter_names),
      "\n"
    )

    doc = doc .. "\n"
    doc = doc .. parameter_header .. "\n"
    doc = doc .. parameter_docs .. "\n"
  end

  local gen_misc_doc = function(ident, title, ins)
    if metadata[ident] then
      doc = doc .. "\n"
      doc = doc .. string.format("%s%s: ~", space_prefix, title) .. "\n"

      local return_docs = table.concat(
        map(function(val)
          return string.format("%s    " .. ins, space_prefix, val)
        end, metadata[ident]),
        "\n"
      )

      doc = doc .. return_docs
    end
  end

  gen_misc_doc('return', 'Return', '%s')
  gen_misc_doc('see', 'See', '|%s()|')
  gen_misc_doc('usage', 'Usage', '%s')

  return doc
end

return help
