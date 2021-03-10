local docgen = require('docgen')
local docgen_help = require('docgen.help')
local docgen_util = require('docgen.utils')

local dedent = function(str, leave_indent)
  -- find minimum common indent across lines
  local indent = nil
  for line in str:gmatch('[^\n]+') do
    local line_indent = line:match('^%s+') or ''
    if indent == nil or #line_indent < #indent then
      indent = line_indent
    end
  end
  if indent == nil or #indent == 0 then
    -- no minimum common indent
    return str
  end
  local left_indent = (' '):rep(leave_indent or 0)
  -- create a pattern for the indent
  indent = indent:gsub('%s', '[ \t]')
  -- strip it from the first line
  str = str:gsub('^'..indent, left_indent)
  -- strip it from the remaining lines
  str = str:gsub('[\n]'..indent, '\n' .. left_indent)
  return str
end

local is_empty = function(content)
  local lines = vim.split(content, '\n')
  for i=2, #lines do
    if lines[i] ~= '' then
      return false
    end
  end
  return true
end

local docs = {}

docs.test = function()
  -- Filepaths that should generate docs
  local input_files = {
    {
      head = "## Brief",
      pre_desc = "Brief is used to describe a module. This is an example input:",
      input = "./example/brief.lua",
      post_desc = ""
    },
    {
      head = "## Tag",
      pre_desc = "Add a tag to your module. This is suggested:",
      input = "./example/tag.lua",
      post_desc = ""
    },
    {
      head = "## Config",
      pre_desc = "You can configure docgen on file basis. For example you can define how `functions` or `classes` are sorted.",
      input = "./example/config.lua",
      post_desc = dedent[[
        Available keys value pairs are:
        - `function_order`:
          - `file_order` (default)
          - `ascending`
          - `descending`
          - or it can accept a function. example: `function(tbl) table.sort(tbl, function(a, b) return a > b end) end`
          - If you have a typo it will do `file_order` sorting
        - `class_order`:
          - `file_order` (default)
          - `ascending`
          - `descending`
          - or it can accept a function. example: `function(tbl) table.sort(tbl, function(a, b) return a > b end) end`
          - If you have a typo it will do `file_order` sorting
        - `field_order`:
          - `file_order` (default)
          - `ascending`
          - `descending`
          - or it can accept a function. example: `function(tbl) table.sort(tbl, function(a, b) return a > b end) end`
          - If you have a typo it will do `file_order` sorting]],
    },
    {
      head = "## Function Header",
      pre_desc = dedent[[
        You can describe your functions.

        Note: We will only generate documentation for functions that are exported with the module.]],
      input = "./example/function.lua",
      post_desc = ""
    },
    {
      head = "## Parameter",
      pre_desc = "You can specify parameters and document them with `---@param name type: desc`",
      input = "./example/parameter.lua",
      post_desc = ""
    },
    {
      head = "## Field",
      pre_desc = "Can be used to describe a parameter table.",
      input = "./example/field.lua",
      post_desc = ""
    },
    {
      head = "## Return",
      pre_desc = "You can specify a return parameter with `---@return type: desc`",
      input = "./example/return.lua",
      post_desc = ""
    },
    {
      head = "## See",
      pre_desc = "Reference something else.",
      input = "./example/see.lua",
      post_desc = ""
    },
    {
      head = "## Class",
      pre_desc = dedent[[
        You can define your own classes and types to give a better sense of the Input or Ouput of a function.
        Another good usecase for this are structs defined by ffi.

        This is a more complete (not functional) example where we define the documentation of the c struct
        `passwd` and return this struct with a function.]],
      input = "./example/class.lua",
      post_desc = ""
    },
    {
      head = "## Eval",
      pre_desc = dedent[[
      You can evaluate arbitrary code. For example if you have a static table you can
      do generate a table that will be part of the `description` output.
      ]],
      input = "./example/eval.lua",
      -- TODO(conni2461):
      -- Hard code eval because currently it doesn't create something.
      -- Your module doesn't exist. We can tackle this when we can have multiline
      -- eval
      post_desc = dedent[[

        Output:

        ```
        ================================================================================
        m.actual_func()                                              *m.actual_func()*
            The documentation for this function will be generated. The markdown
            renderer will be used again.
            With the same set of features.

            Static Values: ~
                a
                b
                c
                d
        ```]]
    },
  }

  local output_file_handle = io.open("HOWTO.md", "w")
  output_file_handle:write("# How to write emmy documentation\n\n")
  for _, file in pairs(input_files) do
    output_file_handle:write(file.head .. '\n\n')
    if file.pre_desc ~= '' then
      output_file_handle:write(file.pre_desc .. '\n\n')
    end

    local content = docgen_util.read(file.input)
    output_file_handle:write('```lua\n' .. content .. '\n```\n')

    local output = docgen_help.format(docgen.get_nodes(content))
    if not is_empty(output) then
      output_file_handle:write('\nOutput:\n\n```\n' .. output .. '\n```\n\n')
    end

    if file.post_desc ~= '' then
      output_file_handle:write(file.post_desc .. '\n\n')
    end
  end
  output_file_handle:close()
end

docs.test()

return docs
