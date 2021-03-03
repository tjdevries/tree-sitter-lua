local docgen = require('docgen')
local docgen_help = require('docgen.help')

local eq = assert.are.same

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

local dedent_trim = function(x)
  return vim.trim(dedent(x))
end

local help_block = function(x)
  return "================================================================================\n"
    .. dedent_trim((x:gsub("\n%s*$", "")))
end


local get_dedented_nodes = function(source)
  return docgen.get_nodes(dedent(source))
end

describe('docgen', function()
  describe('dedent', function()
    it('should dedent things', function()
      eq('hello', dedent 'hello')
      eq('hello', dedent [[
                            hello]])
    end)
  end)

  describe('brief', function()
    local check_brief_nodes = function(input, brief_node)
      local nodes = get_dedented_nodes(input)

      eq({
        brief = brief_node
      }, nodes)
    end

    it('should generate a brief', function()
      check_brief_nodes(
        [=[
          ---@brief [[
          --- Hello world
          ---@brief ]]
        ]=],
       { "Hello world" }
      )
    end)

    it('should generate a multi-line brief', function()
      check_brief_nodes(
        [=[
          ---@brief [[
          --- Hello world
          --- Yup again
          ---@brief ]]
        ]=],
        { "Hello world", "Yup again" }
      )
    end)

    it('keeps empty strings for empty lines', function()
      check_brief_nodes(
        [=[
          ---@brief [[
          --- Hello world
          ---
          --- Yup again
          ---@brief ]]
        ]=],
        { "Hello world", "", "Yup again" }
      )
    end)

    it('should keep indents in the inner strings', function()
      check_brief_nodes(
        [=[
          ---@brief [[
          --- Hello world:
          ---   - This is indented
          ---       - And this is some more
          ---   - Not as indented
          ---@brief ]]
        ]=],
        {
          "Hello world:",
          "  - This is indented",
          "      - And this is some more",
          "  - Not as indented"
        }
      )
    end)

    describe('help output', function()
      local function check_brief_output(input, output)
        local nodes = require('docgen').get_nodes(input)
        local result = docgen_help.format(nodes)

        eq(help_block(output), vim.trim(result))
      end

      it('should not wrap lines, if <br>', function()
        check_brief_output([=[
          ---@brief [[
          --- Hello world<br>
          --- Yup again
          ---@brief ]]
        ]=], [[
          Hello world
          Yup again
        ]])
      end)

      it('should wrap lines', function()
        check_brief_output([=[
          ---@brief [[
          --- Hello world
          --- Yup again
          ---@brief ]]
        ]=], [[
          Hello world Yup again
        ]])
      end)

      it('should keep empty lines', function()
        check_brief_output([=[
          ---@brief [[
          --- Hello world
          ---
          --- Yup again
          ---@brief ]]
        ]=], [[
          Hello world

          Yup again
        ]])
      end)

      it('should keep indenting working', function()
        check_brief_output([=[
          ---@brief [[
          --- Hello world:
          ---   - This is indented
          ---       - And this is some more
          ---   - Not as indented
          ---@brief ]]
        ]=], [[
          Hello world:
            - This is indented
                - And this is some more
            - Not as indented
        ]])
      end)
    end)
  end)

  describe('functions', function()
    it('should generate a function that is exported', function()
      local nodes = get_dedented_nodes [[
        local x = {}

        --- This function has documentation
        ---@param abc string: Docs for abc
        ---@param def string: Other docs for def
        ---@param bxy string: Final docs
        function x.hello(abc, def, bxy)
          return abc .. def .. bxy
        end

        return x
      ]]

      local params = nodes.functions["x.hello"].parameters
      eq({ 'abc', 'def', 'bxy' }, nodes.functions["x.hello"].parameter_list)
      local param_names = {}
      for k, _ in pairs(params) do param_names[k] = true end
      eq({
        abc = true,
        def = true,
        bxy = true
      }, param_names)
    end)

    describe('help output', function()
      local function check_function_output(input, output)
        local nodes = require('docgen').get_nodes(input)
        local result = docgen_help.format(nodes)

        eq(help_block(output), vim.trim(result))
      end
      it('should work with describe', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          ---@param abc string: Docs for abc
          ---@param def string: Other docs for def
          ---@param bxy string: Final docs
          function x.hello(abc, def, bxy)
            return abc .. def .. bxy
          end

          return x]], [[
          x.hello({abc}, {def}, {bxy})                                       *x.hello()*
              This function has documentation


              Parameters: ~
                  {abc} (string)  Docs for abc
                  {def} (string)  Other docs for def
                  {bxy} (string)  Final docs]])
      end)
    end)
  end)
end)
