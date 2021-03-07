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
    describe('transform', function()
      it('should get the nodes of a simple exported function', function()
        local nodes = get_dedented_nodes [[
          local x = {}

          --- This function has documentation
          function x.hello()
            return 5
          end

          return x
        ]]
        eq({
          ["function_list"] = { "x.hello" },
          functions = {
            ["x.hello"] = {
              class = {},
              description = { "", "This function has documentation", "" },
              ["field_list"] = {}, fields = {},
              format = "function",
              name = "x.hello",
              ["parameter_list"] = {}, parameters = {}
            }
          }
        }, nodes)
      end)

      it('should get the nodes of multiple simple functions', function()
        local nodes = get_dedented_nodes [[
          local x = {}

          --- This function has documentation
          function x.hello()
            return 5
          end

          --- This function no documentation
          function x.bye()
            return 10
          end

          --- This function some documentation
          function x.good_evening()
            return 15
          end

          return x
        ]]
        eq({
          ["function_list"] = { "x.hello", "x.bye", "x.good_evening" },
          functions = {
            ["x.hello"] = {
              class = {},
              description = { "", "This function has documentation", "" },
              ["field_list"] = {}, fields = {},
              format = "function",
              name = "x.hello",
              ["parameter_list"] = {}, parameters = {}
            },
            ["x.bye"] = {
              class = {},
              description = { "", "This function no documentation", "" },
              ["field_list"] = {}, fields = {},
              format = "function",
              name = "x.bye",
              ["parameter_list"] = {}, parameters = {}
            },
            ["x.good_evening"] = {
              class = {},
              description = { "", "This function some documentation", "" },
              ["field_list"] = {}, fields = {},
              format = "function",
              name = "x.good_evening",
              ["parameter_list"] = {}, parameters = {}
            }
          }
        }, nodes)
      end)

      it('should get the nodes of a complex exported function', function()
        local nodes = get_dedented_nodes [[
          local x = {}

          --- This function has documentation
          ---@param abc string: Docs for abc
          ---@param def string: Other docs for def
          ---@param bxy number: Final docs
          function x.hello(abc, def, bxy)
            return abc .. def .. tostring(bxy)
          end

          return x
        ]]
        eq({
          ["function_list"] = { "x.hello" },
          functions = {
            ["x.hello"] = {
              class = {},
              description = { "", "This function has documentation", "" },
              ["field_list"] = {}, fields = {},
              format = "function",
              name = "x.hello",
              ["parameter_list"] = { "abc", "def", "bxy" },
              parameters = {
                ["abc"] = { description = { "Docs for abc" }, name = "abc", type = "string" },
                ["def"] = { description = { "Other docs for def" }, name = "def", type = "string" },
                ["bxy"] = { description = { "Final docs" }, name = "bxy", type = "number" },
              }
            }
          }
        }, nodes)
      end)
    end)

    describe('help output', function()
      local function check_function_output(input, output, block)
        local nodes = require('docgen').get_nodes(input)
        local result = docgen_help.format(nodes)
        block = block == nil and true or block
        output = block and help_block(output) or ''

        eq(vim.trim(output), vim.trim(result))
      end
      it('should export documented function', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          function x.hello()
            return 5
          end

          return x]], [[
          x.hello()                                                          *x.hello()*
              This function has documentation]])
      end)

      it('should export multiple functions in file order', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          function x.ba() return 5 end

          --- This function other documentation
          function x.cb() return 5 end

          --- This function no documentation
          function x.ac() return 5 end

          return x]], [[
            x.ba()                                                                *x.ba()*
                This function has documentation



            x.cb()                                                                *x.cb()*
                This function other documentation



            x.ac()                                                                *x.ac()*
                This function no documentation]])
      end)

      it('should export multiple functions in ascending order', function()
        check_function_output([[
          ---@config { ['function_order'] = "ascending" }

          local x = {}

          --- This function has documentation
          function x.b() return 5 end

          --- This function other documentation
          function x.c() return 5 end

          --- This function no documentation
          function x.a() return 5 end

          return x]], [[
            x.a()                                                                  *x.a()*
                This function no documentation



            x.b()                                                                  *x.b()*
                This function has documentation



            x.c()                                                                  *x.c()*
                This function other documentation]])
      end)

      it('should export multiple functions in descending order', function()
        check_function_output([[
          ---@config { ['function_order'] = "descending" }

          local x = {}

          --- This function has documentation
          function x.ba() return 5 end

          --- This function other documentation
          function x.cb() return 5 end

          --- This function no documentation
          function x.ac() return 5 end

          return x]], [[
            x.cb()                                                                *x.cb()*
                This function other documentation



            x.ba()                                                                *x.ba()*
                This function has documentation



            x.ac()                                                                *x.ac()*
                This function no documentation]])
      end)

      it('should not export local function', function()
        check_function_output([[
          --- This function has documentation
          local hello()
            return 5
          end]], [[]], false)
      end)

      it('should not export hidden functions', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          function x.__hello()
            return 5
          end

          return x]], [[]])
      end)

      it('should work with param', function()
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

      it('should work with long param', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          ---@param x string: This is some documentation for a pretty long param. This means that this description needs to be wrapped. Comon wrap.
          function x.hello(abc, def, bxy)
            return abc .. def .. bxy
          end

          return x]], [[
          x.hello({x})                                                       *x.hello()*
              This function has documentation


              Parameters: ~
                  {x} (string)  This is some documentation for a pretty long param. This
                                means that this description needs to be wrapped. Comon
                                wrap.]])
      end)

      it('should work with return', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          ---@param abc string: Docs for abc
          ---@param def string: Other docs for def
          ---@param bxy string: Final docs
          ---@return string: concat
          function x.hello(abc, def, bxy)
            return abc .. def .. bxy
          end

          return x]], [[
          x.hello({abc}, {def}, {bxy})                                       *x.hello()*
              This function has documentation


              Parameters: ~
                  {abc} (string)  Docs for abc
                  {def} (string)  Other docs for def
                  {bxy} (string)  Final docs

              Return: ~
                  string: concat]])
      end)

      it('should work with see', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          ---@see x.bye
          function x.hello()
            return 0
          end

          return x]], [[
          x.hello()                                                          *x.hello()*
              This function has documentation


              See: ~
                  |x.bye()|]])
      end)

      it('should work with field', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          ---@param t table: some input table
          ---@field k1 number: first key of input table
          ---@field key function: second key of input table
          ---@field key3 table: third key of input table
          function x.hello(t)
            return 0
          end

          return x]], [[
          x.hello({t})                                                       *x.hello()*
              This function has documentation


              Parameters: ~
                  {t} (table)  some input table

              Fields: ~
                  {k1}   (number)    first key of input table
                  {key}  (function)  second key of input table
                  {key3} (table)     third key of input table]])
      end)

      it('should work with see, param and return', function()
        check_function_output([[
          local x = {}

          --- This function has documentation
          ---@param a string: hello
          ---@return string: hello
          ---@see x.bye
          function x.hello(a)
            return a
          end

          return x]], [[
          x.hello({a})                                                       *x.hello()*
              This function has documentation


              Parameters: ~
                  {a} (string)  hello

              Return: ~
                  string: hello

              See: ~
                  |x.bye()|]])
      end)
    end)
  end)

  describe('class', function()
    describe('transform', function()
      it('should get the nodes of a simple class', function()
        local nodes = get_dedented_nodes [=[
          ---@class TestMap @table
        ]=]
        eq({
          classes = { ["TestMap"] = {
            name = 'TestMap',
            desc = { 'table' },
            fields = {},
            field_list = {}
          } },
          class_list = { 'TestMap' }
        }, nodes)
      end)

      it('should get the fields of a simple class as well', function()
        local nodes = get_dedented_nodes [=[
          ---@class Array @number indexed starting at 1
          ---@field count number: Always handy to have a count
          ---@field type string: Imagine having a type for an array
          ---@field begin function: It even has a begin()?! Is this cpp?
          ---@field end function: It even has an end()?! Get out of here cpp!
        ]=]
        eq({
          classes = { ["Array"] = {
            name = 'Array',
            desc = { 'number indexed starting at 1' },
            fields = {
              count = { description = { "Always handy to have a count" }, name = "count", type = "number", },
              type = { description = { "Imagine having a type for an array" }, name = "type", type = "string", },
              begin = { description = { "It even has a begin()?! Is this cpp?" }, name = "begin", type = "function", },
              ["end"] = { description = { "It even has an end()?! Get out of here cpp!" }, name = "end", type = "function", },
            },
            field_list = { "count", "type", "begin", "end" },
          } },
          class_list = { 'Array' },
        }, nodes)
      end)

      it('should get the nodes of a sub class', function()
        local nodes = get_dedented_nodes [=[
          ---@class TestArray : TestMap @Numeric table
        ]=]
        eq({
          classes = { ["TestArray"] = {
            name = 'TestArray',
            parent = 'TestMap',
            desc = { 'Numeric table' },
            fields = {},
            field_list = {}
          } },
          class_list = { "TestArray" },
        }, nodes)
      end)

      it('should get the nodes of a parent and sub class', function()
        local nodes = get_dedented_nodes [=[
          ---@class TestMap @table
          ---@class TestArray : TestMap @Numeric table
        ]=]
        eq({
          classes = {
            ["TestMap"] = {
                name = 'TestMap',
                desc = { 'table' },
                fields = {},
                field_list = {}
            }, ["TestArray"] = {
              name = 'TestArray',
              parent = 'TestMap',
              desc = { 'Numeric table' },
              fields = {},
              field_list = {}
            }
          },
          class_list = { 'TestMap', 'TestArray' }
        }, nodes)
      end)

      it('should get the nodes of a parent and sub class', function()
        local nodes = get_dedented_nodes [=[
          local Job = {}

          --- HEADER
          ---@class Job @desc
          ---@field cmd string: command
          ---@param o table: options
          function Job:new(o)
            return setmetatable(o, self)
          end

          return Job
        ]=]
        eq({
          function_list = { 'Job:new' },
          functions = {
            ["Job:new"] = {
              class = { desc = { "desc" }, name = "Job" },
              description = { "", "HEADER", "" },
              fields = {
                cmd = { description = { "command" }, name = "cmd", type = "string", }
              },
              field_list = { "cmd" },
              format = "function",
              name = "Job:new",
              parameter_list = { "o" },
              parameters = {
                o = { description = { "options" }, name = "o", type = "table" }
              }
            }
          },
        }, nodes)
      end)
    end)

    describe('generate', function()
      local function check_class_output(input, output, block)
        local nodes = require('docgen').get_nodes(input)
        local result = docgen_help.format(nodes)
        block = block == nil and true or block
        output = block and help_block(output) or ''

        eq(vim.trim(output), vim.trim(result))
      end

      it('should generate the documentation of a class', function()
        check_class_output([[
          ---@class TestMap @table
        ]], [[
          TestMap                                                              *TestMap*
              table
        ]])
      end)

      it('should generate the documentation of a sub class', function()
        check_class_output([[
          ---@class TestArray : TestMap @array
        ]], [[
          TestArray : TestMap                                                *TestArray*
              array

              Parents: ~
                  |TestMap|
        ]])
      end)

      it('should generate the documentation of a class with fields', function()
        check_class_output([[
          ---@class Array @number indexed starting at 1
          ---@field count number: Always handy to have a count
          ---@field type string: Imagine having a type for an array
          ---@field begin function: It even has a begin()?! Is this cpp?
          ---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this. Please work :)
        ]], [[
          Array                                                                  *Array*
              number indexed starting at 1

              Fields: ~
                  {count} (number)    Always handy to have a count
                  {type}  (string)    Imagine having a type for an array
                  {begin} (function)  It even has a begin()?! Is this cpp?
                  {end}   (function)  It even has an end()?! Get out of here cpp! Oh by
                                      the way did you know that fields are wrapping? I
                                      didn't and this should prove this. Please work :)
        ]])
      end)


      it('should generate the documentation of a sub class with fields', function()
        check_class_output([[
          ---@class Array : Map @number indexed starting at 1
          ---@field count number: Always handy to have a count
          ---@field type string: Imagine having a type for an array
          ---@field begin function: It even has a begin()?! Is this cpp?
          ---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this. Please work :)
        ]], [[
          Array : Map                                                            *Array*
              number indexed starting at 1

              Parents: ~
                  |Map|

              Fields: ~
                  {count} (number)    Always handy to have a count
                  {type}  (string)    Imagine having a type for an array
                  {begin} (function)  It even has a begin()?! Is this cpp?
                  {end}   (function)  It even has an end()?! Get out of here cpp! Oh by
                                      the way did you know that fields are wrapping? I
                                      didn't and this should prove this. Please work :)
        ]])
      end)

      it('should generate the documentation of multiple classes in file order', function()
        check_class_output([[
          ---@class TestMap @table
          ---@class TestArray @array
        ]], [[
          TestMap                                                              *TestMap*
              table


          TestArray                                                          *TestArray*
              array
        ]])
       end)

      it('should generate the documentation of multiple classes in ascending order', function()
        check_class_output([[
          ---@config { ['class_order'] = 'ascending' }

          ---@class B @desc
          ---@class C @desc
          ---@class A @desc
        ]], [[
            A                                                                          *A*
                desc


            B                                                                          *B*
                desc


            C                                                                          *C*
                desc
        ]])
      end)

      it('should generate the documentation of multiple classes in descending order', function()
        check_class_output([[
          ---@config { ['class_order'] = 'descending' }

          ---@class Ba @desc
          ---@class Cb @desc
          ---@class Ac @desc
        ]], [[
            Cb                                                                        *Cb*
                desc


            Ba                                                                        *Ba*
                desc


            Ac                                                                        *Ac*
                desc
        ]])
       end)
    end)
  end)

  describe('config', function()
    describe('transform', function()
      it('should interpret config', function()
        local nodes = get_dedented_nodes [=[
          ---@config { ['function_order'] = "ascending" }
        ]=]
        eq({ config = {
          ['function_order'] = "ascending"
        }}, nodes)
      end)
    end)
  end)
end)
