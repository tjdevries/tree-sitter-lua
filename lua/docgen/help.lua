local help = {}

local map = vim.tbl_map
local values = vim.tbl_values

local align_text = function(left, right, width)
  left = left or ''
  right = right or ''

  local remaining = width - #left - #right

  return string.format("%s%s%s", left, string.rep(" ", remaining), right)
end

help.format_function_metadata = function(metadata)
  local space_prefix = string.rep(" ", 16)

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
  local description = string.format(
    "%s%s",
    space_prefix,
    metadata.description
  )

  local parameter_header = string.format("%sParameters: ~", space_prefix)
  local parameter_docs = table.concat(
    map(function(val)
      return string.format(
        "%s    {%s} (%s)  %s",
        space_prefix,
        val,
        metadata.parameters[val].type,
        table.concat(metadata.parameters[val].description, " ")
      )
    end, parameter_names),
    "\n"
  )

  local doc = ""
  doc = doc .. header  .. "\n"
  doc = doc .. description .. "\n"
  doc = doc .. "\n"
  doc = doc .. parameter_header .. "\n"
  doc = doc .. parameter_docs .. "\n"

  return doc
end

return help
