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
  local description = string.format(
    "%s%s",
    space_prefix,
    metadata.description
  )

  local doc = ""
  doc = doc .. header  .. "\n"
  doc = doc .. description .. "\n"

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

  if metadata["return"] then
    doc = doc .. "\n"
    doc = doc .. string.format("%sReturn: ~", space_prefix) .. "\n"
    -- doc = doc .. %s", space_prefix, metadata["return"]) .. "\n"

    local return_docs = table.concat(
      map(function(val)
        return string.format("%s    %s", space_prefix, val)
      end, metadata["return"]),
      "\n"
    )

    doc = doc .. return_docs
  end

  return doc
end

return help
