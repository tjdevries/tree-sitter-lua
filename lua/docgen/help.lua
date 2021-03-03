local log = require('docgen.log')
local utils = require('docgen.utils')
local render = require('docgen.renderer').render

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

  -- Make functions, always do them sorted.
  local metadata_keys = vim.tbl_keys(metadata.functions or {})
  table.sort(metadata_keys)
  metadata_keys = vim.tbl_filter(function(func_name)
    if string.find(func_name, ".__", 1, true) then
      return false
    end

    if string.find(func_name, ":__", 1, true) then
      return false
    end

    if func_name:sub(1, 2) == "__" then
      return false
    end

    return func_name:sub(1, 2) ~= "__"
  end, metadata_keys)

  for _, func_name in ipairs(metadata_keys) do
    local v = metadata.functions[func_name]

    local result = help.format_function_metadata(v)
    if not result then error("Missing result") end

    add(result)
    add()
  end

  add()

  return formatted
end

help.format_brief = function(brief_metadata)
  -- TODO: In the future, maybe we could do more intelligent wrapping here.
  -- return doc_wrap(table.concat(brief_metadata, " "))
  -- print(vim.inspect(brief_metadata))

  return render(brief_metadata, '', 79)
end

help.format_function_metadata = function(function_metadata)
  local space_prefix = string.rep(" ", 4)

  local name = function_metadata.name

  local left_side = string.format(
    "%s(%s)",
    name,
    table.concat(map(
      function(val) return string.format("{%s}", function_metadata.parameters[val].name) end,
      function_metadata.parameter_list
    ), ", ")
  )

  local right_side = string.format("*%s()*", name)

  local header = align_text(left_side, right_side, 78)

  local doc = ""
  doc = doc .. header  .. "\n"

  -- local description = table.concat(
  --   map(function(val)
  --     if val == '' then return '\n' end
  --     return val
  --   end, function_metadata.description or {}),
  --   ' '
  -- )
  -- print(vim.inspect(function_metadata.description))
  local description = render(
    function_metadata.description,
    space_prefix,
    79
  )

  -- description = doc_wrap(description, {
  --   prefix = space_prefix,
  --   width = 80,
  -- })
  doc = doc .. description .. "\n"

  if not vim.tbl_isempty(function_metadata["parameters"]) then
    -- TODO: This needs to handle strings that get wrapped.

    local parameter_header = string.format("%sParameters: ~", space_prefix)
    local parameter_docs = table.concat(
      map(function(val)
        local param_prefix = string.format(
          "%s    {%s} (%s)  ",
          space_prefix,
          function_metadata.parameters[val].name,
          function_metadata.parameters[val].type
        )

        local empty_prefix = string.rep(" ", #param_prefix)

        local result = ''
        for i, v in ipairs(function_metadata.parameters[val].description) do
          if i == 1 then
            result = param_prefix .. v
          else
            result = result .. string.format("%s%s", empty_prefix, v)
          end
        end

        return result
      end, function_metadata.parameter_list),
      "\n"
    )

    doc = doc .. "\n"
    doc = doc .. parameter_header .. "\n"
    doc = doc .. parameter_docs .. "\n"
  end

  local gen_misc_doc = function(identification, ins)
    if function_metadata[identification] then
      local title = identification:sub(1, 1):upper() .. identification:sub(2, -1)

      if doc:sub(#doc, #doc) ~= '\n' then
        doc = doc .. '\n'
      end

      doc = doc .. "\n"
      doc = doc .. string.format("%s%s: ~", space_prefix, title) .. "\n"

      local return_docs = table.concat(
        map(function(val)
          return doc_wrap(string.format(ins, val), {
            prefix = space_prefix .. '    ',
            width = 80,
          })
        end, function_metadata[identification]),
        "\n"
      )

      doc = doc .. return_docs
    end
  end

  gen_misc_doc('varargs', '%s')
  gen_misc_doc('return', '%s')
  gen_misc_doc('usage', '%s')
  gen_misc_doc('see', '|%s()|')

  return doc
end

return help
