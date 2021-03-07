local log = require('docgen.log')
local utils = require('docgen.utils')
local render = require('docgen.renderer').render
local renderi = require('docgen.renderer').renderi

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

  -- Make classes
  local metadata_classes = vim.deepcopy(metadata.class_list or {})

  if metadata.config then
    if metadata.config.class_order == 'ascending' then
      table.sort(metadata_classes)
    elseif metadata.config.class_order == 'descending' then
      table.sort(metadata_classes, function(a, b) return a > b end)
    end
  end
  for _, class_name in ipairs(metadata_classes) do
    local v = metadata.classes[class_name]

    local result = help.format_class_metadata(v)
    if not result then error("Missing result") end

    add(result)
    add()
  end

  -- Make functions
  local metadata_keys = vim.deepcopy(metadata.function_list or {})

  if metadata.config then
    if metadata.config.function_order == 'ascending' then
      table.sort(metadata_keys)
    elseif metadata.config.function_order == 'descending' then
      table.sort(metadata_keys, function(a, b) return a > b end)
    end
  end
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
  return render(brief_metadata, '', 79)
end

-- TODO(conni2461): Do we want some configuration for alignment?!
help.__left_side_parameter_field = function(input, max_name_width, space_prefix)
  local name = string.format("%s%s{%s} ",
    space_prefix,
    space_prefix,
    input.name
  )
  local diff = max_name_width - #input.name

  return string.format("%s%s(%s)  ", name, string.rep(' ', diff), input.type)
end

help.format_parameter_field = function(input, space_prefix, max_name_width, align_width)
  local left_side = help.__left_side_parameter_field(input, max_name_width, space_prefix)
  local right_side = renderi(input.description, string.rep(' ', align_width), 79)

  local diff = align_width - #left_side
  assert(diff >= 0, "Otherwise we have a big error somewhere in docgen")

  return left_side .. string.rep(' ', diff) .. right_side .. '\n'
end

help.iter_parameter_field = function(input, list, name, space_prefix)
  local output = ""
  if list and table.getn(list) > 0 then
    output = output .. "\n" .. space_prefix .. name .. ": ~" .. "\n"
    local max_name_width = 0
    for _, e in ipairs(list) do
      local width = #input[e].name
      if width > max_name_width then
        max_name_width = width
      end
    end

    local left_width = 0
    for _, e in ipairs(list) do
      local width = #(help.__left_side_parameter_field(input[e], max_name_width, space_prefix))
      if width > left_width then
        left_width = width
      end
    end

    for _, e in ipairs(list) do
      output = output .. help.format_parameter_field(input[e], space_prefix, max_name_width, left_width)
    end
  end
  return output
end

help.format_class_metadata = function(class)
  local space_prefix = string.rep(" ", 4)

  local doc = ""
  local left_side = class.parent and
                    string.format("%s : %s", class.name, class.parent) or
                    class.name

  local header = align_text(left_side, string.format("*%s*", class.name), 78)
  doc = doc .. header .. "\n"

  local description = render(
    class.desc,
    space_prefix,
    79
  )
  doc = doc .. description .. "\n"

  if class.parent then
    doc = doc .. "\n" .. space_prefix .. "Parents: ~" .. "\n"
    doc = doc .. string.format('%s%s|%s|\n', space_prefix, space_prefix, class.parent)
  end


  doc = doc .. help.iter_parameter_field(class.fields,
                                         class.field_list,
                                         "Fields",
                                         space_prefix
                                        )

  return doc
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

  -- TODO(conni2461): LONG function names break this thing
  local header = align_text(left_side, right_side, 78)

  local doc = ""
  doc = doc .. header  .. "\n"

  local description = render(
    function_metadata.description,
    space_prefix,
    79
  )
  doc = doc .. description .. "\n"

  -- TODO(conni2461): CLASS

  -- Handles parameter if used
  doc = doc .. help.iter_parameter_field(function_metadata.parameters,
                                         function_metadata.parameter_list,
                                         "Parameters",
                                         space_prefix
                                        )

  -- Handle fields if used
  doc = doc .. help.iter_parameter_field(function_metadata.fields,
                                         function_metadata.field_list,
                                         "Fields",
                                         space_prefix
                                        )

  local gen_misc_doc = function(identification, ins)
    if function_metadata[identification] then
      local title = identification:sub(1, 1):upper() .. identification:sub(2, -1)

      if doc:sub(#doc, #doc) ~= '\n' then
        doc = doc .. '\n'
      end
      doc = doc .. "\n" .. string.format("%s%s: ~", space_prefix, title) .. "\n"
      for _, x in ipairs(function_metadata[identification]) do
        doc = doc .. render({ string.format(ins, x) }, space_prefix .. space_prefix, 80) .. "\n"
      end
    end
  end

  gen_misc_doc('varargs', '%s')
  gen_misc_doc('return', '%s')
  gen_misc_doc('usage', '%s')
  gen_misc_doc('see', '|%s()|')

  return doc
end

return help
