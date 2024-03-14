local render = require("docgen.renderer").render
local render_without_first_line_prefix = require("docgen.renderer").render_without_first_line_prefix

---@brief [[
--- All help formatting related utilties. Used to transform output from |docgen| into vim style documentation.
--- Other documentation styles are possible, but have not yet been implemented.
---@brief ]]

---@tag docgen-help-formatter
local help = {}

local trim_trailing = function(str)
  return str:gsub("%s*$", "")
end

local align_text = function(left, right, width)
  left = left or ""
  right = right or ""

  local remaining = width - #left - #right

  return string.format("%s%s%s", left, string.rep(" ", remaining), right)
end

--- Format an entire generated metadata from |docgen|
---@param metadata table: The metadata from docgen
help.format = function(metadata)
  if vim.tbl_isempty(metadata) then
    return ""
  end

  local formatted = ""

  local add = function(text, no_nl)
    formatted = string.format("%s%s%s", formatted, (text or ""), (no_nl and "" or "\n"))
  end

  -- TODO: Make top level

  add(string.rep("=", 80))
  if metadata.tag then
    -- Support multiple tags
    local tags = vim.tbl_map(function(x)
      return string.format("*%s*", x)
    end, vim.split(metadata.tag, "%s+"))

    local left = (function()
      if metadata.config and metadata.config.name and type(metadata.config.name) == "string" then
        return metadata.config.name:upper()
      else
        local ret = vim.split(metadata.tag, "%s+")
        if ret and ret[1] then
          ret = vim.split(ret[1], "%.")
          ret = ret[#ret]
        end
        return ret:upper()
      end
    end)()
    add(align_text(left, table.concat(tags, " "), 80))
    add()
  end

  -- Make brief
  if metadata.brief then
    local result = help.format_brief(metadata.brief)

    if not result then
      error "Missing result"
    end

    add(result)
    add()
  end

  -- Make commands
  local commands = metadata.commands or {}
  if not vim.tbl_isempty(commands) then
    add(help.format_commands(commands, metadata.config))
    add()
  end

  -- Make classes
  local metadata_classes = vim.deepcopy(metadata.class_list or {})

  if metadata.config then
    if type(metadata.config.class_order) == "function" then
      metadata.config.class_order(metadata_classes)
    elseif metadata.config.class_order == "ascending" then
      table.sort(metadata_classes)
    elseif metadata.config.class_order == "descending" then
      table.sort(metadata_classes, function(a, b)
        return a > b
      end)
    end
  end
  for _, class_name in ipairs(metadata_classes) do
    local v = metadata.classes[class_name]

    local result = help.format_class_metadata(v, metadata.config)
    if not result then
      error "Missing result"
    end

    add(result)
    add()
  end

  -- Make functions
  local metadata_keys = vim.deepcopy(metadata.function_list or {})

  if metadata.config then
    if type(metadata.config.function_order) == "function" then
      metadata.config.function_order(metadata_keys)
    elseif metadata.config.function_order == "ascending" then
      table.sort(metadata_keys)
    elseif metadata.config.function_order == "descending" then
      table.sort(metadata_keys, function(a, b)
        return a > b
      end)
    end

    -- config.module:
    --   Replace the module return name with this.
    if metadata.config.module then
      if type(metadata.return_module) == "string" then
        metadata.config.transform_name = function(_, name)
          return (string.gsub(name, metadata.return_module, metadata.config.module, 1))
        end
      end
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

    local result = help.format_function_metadata(v, metadata.config)
    if not result then
      error "Missing result"
    end

    add(result)
    add()
  end

  add()

  return formatted
end

help.format_brief = function(brief_metadata)
  return render(brief_metadata, "", 79)
end

-- TODO(conni2461): Do we want some configuration for alignment?!
help.__left_side_parameter_field = function(input, max_name_width, space_prefix)
  local name = string.format("%s%s{%s} ", space_prefix, space_prefix, input.name)
  local diff = max_name_width - #input.name

  return string.format("%s%s(%s)  ", name, string.rep(" ", diff), table.concat(input.type, "|"))
end

help.format_parameter_field = function(input, space_prefix, max_name_width, align_width)
  local left_side = help.__left_side_parameter_field(input, max_name_width, space_prefix)

  local width = math.max(align_width, 78)
  local right_side = render_without_first_line_prefix(input.description, string.rep(" ", align_width), width)
  if right_side == "" then
    return string.format("%s\n", trim_trailing(left_side))
  end

  local diff = align_width - #left_side
  assert(diff >= 0, "Otherwise we have a big error somewhere in docgen")

  return string.format("%s%s%s\n", left_side, string.rep(" ", diff), right_side)
end

help.iter_parameter_field = function(input, list, name, space_prefix)
  local output = ""
  if list and table.getn(list) > 0 then
    output = string.format("%s\n%s%s: ~\n", output, space_prefix, name)
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
      output =
        string.format("%s%s", output, help.format_parameter_field(input[e], space_prefix, max_name_width, left_width))
    end
  end
  return output
end

help.format_class_metadata = function(class, config)
  config = config or {}
  local space_prefix = string.rep(" ", config.space_prefix or 4)

  local doc = ""
  local left_side = class.parent and string.format("%s : %s", class.name, class.parent) or class.name

  local header = align_text(left_side, string.format("*%s*", class.name), 78)
  doc = string.format("%s%s\n", doc, header)

  local description = render(class.desc, space_prefix, 79)
  doc = string.format("%s%s\n", doc, description)

  if class.parent then
    doc = string.format("%s\n%sParents: ~\n%s%s|%s|\n", doc, space_prefix, space_prefix, space_prefix, class.parent)
  end

  if type(config.field_order) == "function" then
    config.field_order(class.field_list)
  elseif config.field_order == "ascending" then
    table.sort(class.field_list)
  elseif config.field_order == "descending" then
    table.sort(class.field_list, function(a, b)
      return a > b
    end)
  end
  doc = string.format(
    "%s%s",
    doc,
    help.iter_parameter_field(class.fields, class.field_list, config.field_heading or "Fields", space_prefix)
  )

  return doc
end

---@class DocgenCommand
---@field name string
---@field usage string
---@field documentation string[]

--- Format commands
---@param command_metadata DocgenCommand[]
---@param config any
help.format_commands = function(command_metadata, config)
  local doc = ""

  for _, command in ipairs(command_metadata) do
    config = config or {}

    local right_side = string.format("*:%s*", command.name)
    local header = align_text("", right_side, 78)

    doc = doc .. header .. "\n"
    doc = doc .. command.usage .. " ~\n"
    doc = doc .. render(command.documentation, "    ", 79)
    doc = doc .. "\n\n"
  end

  return doc
end

help.format_function_metadata = function(function_metadata, config)
  config = config or {}
  local space_prefix = string.rep(" ", 4)

  local name = function_metadata.name
  local tag = config.transform_name and config.transform_name(function_metadata, name) or name

  local left_side = string.format(
    "%s(%s)",
    name,
    table.concat(
      vim.tbl_map(function(val)
        return string.format("{%s}", function_metadata.parameters[val].name)
      end, function_metadata.parameter_list),
      ", "
    )
  )

  -- Add single whitespace on the left to ensure that it reads as help tag
  local right_side = string.format(" *%s()*", tag)

  -- TODO(conni2461): LONG function names break this thing
  local header = align_text(left_side, right_side, 78)

  local doc = ""
  doc = string.format("%s%s\n", doc, header)

  local description = render(function_metadata.description or {}, space_prefix, 79)
  doc = string.format("%s%s\n", doc, description)

  -- TODO(conni2461): CLASS

  -- Handles parameter if used
  doc = string.format(
    "%s%s",
    doc,
    help.iter_parameter_field(
      function_metadata.parameters,
      function_metadata.parameter_list,
      "Parameters",
      space_prefix
    )
  )

  if type(config.field_order) == "function" then
    config.field_order(function_metadata.field_list)
  elseif config.field_order == "ascending" then
    table.sort(function_metadata.field_list)
  elseif config.field_order == "descending" then
    table.sort(function_metadata.field_list, function(a, b)
      return a > b
    end)
  end
  -- Handle fields if used
  doc = string.format(
    "%s%s",
    doc,
    help.iter_parameter_field(
      function_metadata.fields,
      function_metadata.field_list,
      config.field_heading or "Fields",
      space_prefix
    )
  )

  local gen_misc_doc = function(identification, ins)
    if function_metadata[identification] then
      local title = string.format("%s%s", identification:sub(1, 1):upper(), identification:sub(2, -1))

      if doc:sub(#doc, #doc) ~= "\n" then
        doc = string.format("%s\n", doc)
      end
      doc = string.format("%s\n%s%s: ~\n", doc, space_prefix, title)
      for _, x in ipairs(function_metadata[identification]) do
        doc = string.format("%s%s\n", doc, render({ string.format(ins, x) }, string.rep(space_prefix, 2), 78))
      end
    end
  end

  gen_misc_doc("varargs", "%s")
  gen_misc_doc("return", "%s")
  gen_misc_doc("usage", "%s")
  gen_misc_doc("see", "|%s()|")

  return doc
end

return help
