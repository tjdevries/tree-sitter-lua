local docgen = require "docgen"
local docgen_help = require "docgen.help"

local eq = assert.are.same

local dedent = require("plenary.strings").dedent

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

describe("functions", function()
  describe("transform", function()
    it("should get the nodes of a simple exported function", function()
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
            ["field_list"] = {},
            fields = {},
            format = "function",
            name = "x.hello",
            ["parameter_list"] = {},
            parameters = {},
          },
        },
        return_module = "x",
      }, nodes)
    end)

    it("should get the nodes of multiple simple functions", function()
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
            ["field_list"] = {},
            fields = {},
            format = "function",
            name = "x.hello",
            ["parameter_list"] = {},
            parameters = {},
          },
          ["x.bye"] = {
            class = {},
            description = { "", "This function no documentation", "" },
            ["field_list"] = {},
            fields = {},
            format = "function",
            name = "x.bye",
            ["parameter_list"] = {},
            parameters = {},
          },
          ["x.good_evening"] = {
            class = {},
            description = { "", "This function some documentation", "" },
            ["field_list"] = {},
            fields = {},
            format = "function",
            name = "x.good_evening",
            ["parameter_list"] = {},
            parameters = {},
          },
        },
        return_module = "x",
      }, nodes)
    end)

    it("should get the nodes of a complex exported function", function()
      local nodes = get_dedented_nodes [[
        local x = {}

        --- This function has documentation
        ---@param abc string: Docs for abc
        ---@param def "This"|"That": Other docs for def
        ---@param bxy number: Final docs
        function x.hello(abc, def, bxy)
          return abc .. def .. tostring(bxy)
        end

        return x
      ]]

      eq({
        ["abc"] = { description = { "Docs for abc" }, name = "abc", type = { "string" } },
        ["def"] = { description = { "Other docs for def" }, name = "def", type = { '"This"', '"That"' } },
        ["bxy"] = { description = { "Final docs" }, name = "bxy", type = { "number" } },
      }, nodes.functions["x.hello"].parameters)

      eq({
        ["function_list"] = { "x.hello" },
        functions = {
          ["x.hello"] = {
            class = {},
            description = { "", "This function has documentation", "" },
            ["field_list"] = {},
            fields = {},
            format = "function",
            name = "x.hello",
            ["parameter_list"] = { "abc", "def", "bxy" },
            parameters = {
              ["abc"] = { description = { "Docs for abc" }, name = "abc", type = { "string" } },
              ["def"] = { description = { "Other docs for def" }, name = "def", type = { '"This"', '"That"' } },
              ["bxy"] = { description = { "Final docs" }, name = "bxy", type = { "number" } },
            },
          },
        },
        return_module = "x",
      }, nodes)
    end)

    it("should get the nodes of a complex exported function with multitypes", function()
      local nodes = get_dedented_nodes [[
        local x = {}

        --- This function has documentation
        ---@param a string|number: doc
        function x.hello(a)
          return a
        end

        return x
      ]]
      eq({
        ["function_list"] = { "x.hello" },
        functions = {
          ["x.hello"] = {
            class = {},
            description = { "", "This function has documentation", "" },
            ["field_list"] = {},
            fields = {},
            format = "function",
            name = "x.hello",
            ["parameter_list"] = { "a" },
            parameters = {
              ["a"] = { description = { "doc" }, name = "a", type = { "string", "number" } },
            },
          },
        },
        return_module = "x",
      }, nodes)
    end)
  end)

  describe("help output", function()
    local function check_function_output(input, output, block)
      local nodes = require("docgen").get_nodes(input)
      local result = docgen_help.format(nodes)
      block = block == nil and true or block
      output = block and help_block(output) or ""

      eq(vim.trim(output), vim.trim(result))
    end

    it("should export documented function", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        function x.hello()
          return 5
        end

        return x]],
        [[
        x.hello()                                                          *x.hello()*
            This function has documentation]]
      )
    end)

    it("should export this style as well function", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        x.hello = function()
          return 5
        end

        return x]],
        [[
        x.hello()                                                          *x.hello()*
            This function has documentation]]
      )
    end)

    it("should export multiple functions in file order", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        function x.ba() return 5 end

        --- This function other documentation
        function x.cb() return 5 end

        --- This function no documentation
        function x.ac() return 5 end

        return x]],
        [[
          x.ba()                                                                *x.ba()*
              This function has documentation



          x.cb()                                                                *x.cb()*
              This function other documentation



          x.ac()                                                                *x.ac()*
              This function no documentation]]
      )
    end)

    it("should export multiple functions in ascending order", function()
      check_function_output(
        [[
        ---@config { ['function_order'] = "ascending" }

        local x = {}

        --- This function has documentation
        function x.b() return 5 end

        --- This function other documentation
        function x.c() return 5 end

        --- This function no documentation
        function x.a() return 5 end

        return x]],
        [[
          x.a()                                                                  *x.a()*
              This function no documentation



          x.b()                                                                  *x.b()*
              This function has documentation



          x.c()                                                                  *x.c()*
              This function other documentation]]
      )
    end)

    it("should export multiple functions in descending order", function()
      check_function_output(
        [[
        ---@config { ['function_order'] = "descending" }

        local x = {}

        --- This function has documentation
        function x.ba() return 5 end

        --- This function other documentation
        function x.cb() return 5 end

        --- This function no documentation
        function x.ac() return 5 end

        return x]],
        [[
          x.cb()                                                                *x.cb()*
              This function other documentation



          x.ba()                                                                *x.ba()*
              This function has documentation



          x.ac()                                                                *x.ac()*
              This function no documentation]]
      )
    end)

    it("should export multiple functions in descending order", function()
      check_function_output(
        [[
        ---@config { function_order = function(tbl) table.sort(tbl, function(a, b) return a > b end) end }

        local x = {}

        --- This function has documentation
        function x.ba() return 5 end

        --- This function other documentation
        function x.cb() return 5 end

        --- This function no documentation
        function x.ac() return 5 end

        return x]],
        [[
          x.cb()                                                                *x.cb()*
              This function other documentation



          x.ba()                                                                *x.ba()*
              This function has documentation



          x.ac()                                                                *x.ac()*
              This function no documentation]]
      )
    end)

    it("should not export local function", function()
      check_function_output(
        [[
        --- This function has documentation
        local function hello()
          return 5
        end]],
        [[]],
        false
      )
    end)

    it("should not export hidden functions", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        function x.__hello()
          return 5
        end

        return x]],
        [[]]
      )
    end)

    it("should work with param", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param abc string: Docs for abc
        ---@param def string: Other docs for def
        ---@param bxy string: Final docs
        function x.hello(abc, def, bxy)
          return abc .. def .. bxy
        end

        return x]],
        [[
        x.hello({abc}, {def}, {bxy})                                       *x.hello()*
            This function has documentation


            Parameters: ~
                {abc} (string)  Docs for abc
                {def} (string)  Other docs for def
                {bxy} (string)  Final docs]]
      )
    end)

    it("should work with ellipsis param", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param ... vararg: Any number of arguments.
        function x.hello(...)
          return true
        end

        return x]],
        [[
        x.hello({...})                                                     *x.hello()*
            This function has documentation


            Parameters: ~
                {...} (vararg)  Any number of arguments.]]
      )
    end)

    it("should work with param and multitypes", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param abc string|number: Docs for abc
        ---@param def string: Other docs for def
        ---@param bxy string|function: Final docs
        function x.hello(abc, def, bxy)
          return abx .. def .. bxy
        end

        return x]],
        [[
        x.hello({abc}, {def}, {bxy})                                       *x.hello()*
            This function has documentation


            Parameters: ~
                {abc} (string|number)    Docs for abc
                {def} (string)           Other docs for def
                {bxy} (string|function)  Final docs]]
      )
    end)

    it("should work with long param", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param a string: This is some documentation for a pretty long param. This means that this description needs to be wrapped. Comon wrap.
        function x.hello(a)
          return abc .. def .. bxy
        end

        return x]],
        [[
        x.hello({a})                                                       *x.hello()*
            This function has documentation


            Parameters: ~
                {a} (string)  This is some documentation for a pretty long param. This
                              means that this description needs to be wrapped. Comon
                              wrap.]]
      )
    end)

    it("should create help tag in case of long function signature", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param very_long_parameter_1 number: Very long parameter 1.
        ---@param very_long_parameter_2 number: Very long parameter 2.
        ---@param very_long_parameter_3 number: Very long parameter 3.
        function x.normal_function(very_long_parameter_1, very_long_parameter_2, very_long_parameter_3)
          return true
        end

        return x]],
        [[
        x.normal_function({very_long_parameter_1}, {very_long_parameter_2}, {very_long_parameter_3}) *x.normal_function()*
            This function has documentation


            Parameters: ~
                {very_long_parameter_1} (number)  Very long parameter 1.
                {very_long_parameter_2} (number)  Very long parameter 2.
                {very_long_parameter_3} (number)  Very long parameter 3.]]
      )
    end)

    it("should work with return", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param abc string: Docs for abc
        ---@param def string: Other docs for def
        ---@param bxy string: Final docs
        ---@return string: concat
        function x.hello(abc, def, bxy)
          return abc .. def .. bxy
        end

        return x]],
        [[
        x.hello({abc}, {def}, {bxy})                                       *x.hello()*
            This function has documentation


            Parameters: ~
                {abc} (string)  Docs for abc
                {def} (string)  Other docs for def
                {bxy} (string)  Final docs

            Return: ~
                string: concat]]
      )
    end)

    it("should work with see", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@see x.bye
        function x.hello()
          return 0
        end

        return x]],
        [[
        x.hello()                                                          *x.hello()*
            This function has documentation


            See: ~
                |x.bye()|]]
      )
    end)

    it("should work with field", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param t table: some input table
        ---@field k1 number: first key of input table
        ---@field key function: second key of input table
        ---@field key3 table: third key of input table
        function x.hello(t)
          return 0
        end

        return x]],
        [[
        x.hello({t})                                                       *x.hello()*
            This function has documentation


            Parameters: ~
                {t} (table)  some input table

            Fields: ~
                {k1}   (number)    first key of input table
                {key}  (function)  second key of input table
                {key3} (table)     third key of input table]]
      )
    end)

    it("should work with field and multitypes", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param t table: some input table
        ---@field k1 string|number: first key of input table
        ---@field key function: second key of input table
        ---@field key3 table: third key of input table
        function x.hello(t)
          return 0
        end

        return x]],
        [[
        x.hello({t})                                                       *x.hello()*
            This function has documentation


            Parameters: ~
                {t} (table)  some input table

            Fields: ~
                {k1}   (string|number)  first key of input table
                {key}  (function)       second key of input table
                {key3} (table)          third key of input table]]
      )
    end)

    it("should work with see, param and return", function()
      check_function_output(
        [[
        local x = {}

        --- This function has documentation
        ---@param a string: hello
        ---@return string: hello
        ---@see x.bye
        function x.hello(a)
          return a
        end

        return x]],
        [[
        x.hello({a})                                                       *x.hello()*
            This function has documentation


            Parameters: ~
                {a} (string)  hello

            Return: ~
                string: hello

            See: ~
                |x.bye()|]]
      )
    end)

    it("should only return documentation for returned module", function()
      check_function_output(
        [[
        local a = {}
        local b = {}

        --- Documentation for a
        a.fun = function()
          return b.fun()
        end

        --- Documentation for b
        b.fun = function()
          return "Hello, World!"
        end

        return a]],
        [[
        a.fun()                                                              *a.fun()*
            Documentation for a]]
      )
    end)

    it("should be able to rename field heading", function()
      check_function_output(
        [[
        local builtin = {}

        ---@config { ['field_heading'] = "Options" }

        --- Search for a string and get results live as you type (respecting .gitignore)
        ---@param opts table: options to pass to the picker
        ---@field cwd string: root dir to search from (default: cwd, use utils.buffer_dir() to search relative to open buffer)
        builtin.live_grep = function()
          return 5
        end

        return builtin]],
        [[
        builtin.live_grep({opts})                                *builtin.live_grep()*
            Search for a string and get results live as you type (respecting
            .gitignore)


            Parameters: ~
                {opts} (table)  options to pass to the picker

            Options: ~
                {cwd} (string)  root dir to search from (default: cwd, use
                                utils.buffer_dir() to search relative to open buffer)]]
      )
    end)

    it("should be able to add a module prefix", function()
      check_function_output(
        [[
        local builtin = {}

        ---@config { ['field_heading'] = "Options", ['module'] = "telescope.builtin" }

        --- Search for a string and get results live as you type (respecting .gitignore)
        ---@param opts table: options to pass to the picker
        ---@field cwd string: root dir to search from (default: cwd, use utils.buffer_dir() to search relative to open buffer)
        builtin.live_grep = function()
          return 5
        end

        return builtin]],
        [[
        builtin.live_grep({opts})                      *telescope.builtin.live_grep()*
            Search for a string and get results live as you type (respecting
            .gitignore)


            Parameters: ~
                {opts} (table)  options to pass to the picker

            Options: ~
                {cwd} (string)  root dir to search from (default: cwd, use
                                utils.buffer_dir() to search relative to open buffer)]]
      )
    end)
  end)
end)
