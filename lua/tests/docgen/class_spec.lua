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

describe("class", function()
  describe("transform", function()
    it("should get the nodes of a simple class", function()
      local nodes = get_dedented_nodes [=[
        ---@class TestMap @table
      ]=]
      eq({
        classes = {
          ["TestMap"] = {
            name = "TestMap",
            desc = { "table" },
            fields = {},
            field_list = {},
          },
        },
        class_list = { "TestMap" },
      }, nodes)
    end)

    it("should get the fields of a simple class as well", function()
      local nodes = get_dedented_nodes [=[
        ---@class Array @number indexed starting at 1
        ---@field count number: Always handy to have a count
        ---@field type string: Imagine having a type for an array
        ---@field begin function: It even has a begin()?! Is this cpp?
        ---@field end function: It even has an end()?! Get out of here cpp!
      ]=]
      eq({
        classes = {
          ["Array"] = {
            name = "Array",
            desc = { "number indexed starting at 1" },
            fields = {
              count = { description = { "Always handy to have a count" }, name = "count", type = { "number" } },
              type = { description = { "Imagine having a type for an array" }, name = "type", type = { "string" } },
              begin = {
                description = { "It even has a begin()?! Is this cpp?" },
                name = "begin",
                type = { "function" },
              },
              ["end"] = {
                description = { "It even has an end()?! Get out of here cpp!" },
                name = "end",
                type = { "function" },
              },
            },
            field_list = { "count", "type", "begin", "end" },
          },
        },
        class_list = { "Array" },
      }, nodes)
    end)

    it("should get the fields of a simple class as well with multitypes", function()
      local nodes = get_dedented_nodes [=[
        ---@class Array @number indexed starting at 1
        ---@field count number: Always handy to have a count
        ---@field type string|number: Imagine having a type for an array
        ---@field begin function|table|nil: It even has a begin()?! Is this cpp?
        ---@field end function: It even has an end()?! Get out of here cpp!
      ]=]

      eq({
        classes = {
          ["Array"] = {
            name = "Array",
            desc = { "number indexed starting at 1" },
            fields = {
              count = { description = { "Always handy to have a count" }, name = "count", type = { "number" } },
              type = {
                description = { "Imagine having a type for an array" },
                name = "type",
                type = { "string", "number" },
              },
              begin = {
                description = { "It even has a begin()?! Is this cpp?" },
                name = "begin",
                type = { "function", "table", "nil" },
              },
              ["end"] = {
                description = { "It even has an end()?! Get out of here cpp!" },
                name = "end",
                type = { "function" },
              },
            },
            field_list = { "count", "type", "begin", "end" },
          },
        },
        class_list = { "Array" },
      }, nodes)
    end)

    it("should get the nodes of a sub class", function()
      local nodes = get_dedented_nodes [=[
        ---@class TestArray : TestMap @Numeric table
      ]=]
      eq({
        classes = {
          ["TestArray"] = {
            name = "TestArray",
            parent = "TestMap",
            desc = { "Numeric table" },
            fields = {},
            field_list = {},
          },
        },
        class_list = { "TestArray" },
      }, nodes)
    end)

    it("should get the nodes of a parent and sub class", function()
      local nodes = get_dedented_nodes [=[
        ---@class TestMap @table
        ---@class TestArray : TestMap @Numeric table
      ]=]
      eq({
        classes = {
          ["TestMap"] = {
            name = "TestMap",
            desc = { "table" },
            fields = {},
            field_list = {},
          },
          ["TestArray"] = {
            name = "TestArray",
            parent = "TestMap",
            desc = { "Numeric table" },
            fields = {},
            field_list = {},
          },
        },
        class_list = { "TestMap", "TestArray" },
      }, nodes)
    end)

    it("should get the nodes of a function class", function()
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
        function_list = { "Job:new" },
        functions = {
          ["Job:new"] = {
            class = { desc = { "desc" }, name = "Job" },
            description = { "", "HEADER", "" },
            fields = {
              cmd = { description = { "command" }, name = "cmd", type = { "string" } },
            },
            field_list = { "cmd" },
            format = "function",
            name = "Job:new",
            parameter_list = { "o" },
            parameters = {
              o = { description = { "options" }, name = "o", type = { "table" } },
            },
          },
        },
        return_module = "Job",
      }, nodes)
    end)
  end)

  describe("generate", function()
    local function check_class_output(input, output, block)
      local nodes = require("docgen").get_nodes(input)
      local result = docgen_help.format(nodes)
      block = block == nil and true or block
      output = block and help_block(output) or ""

      eq(vim.trim(output), vim.trim(result))
    end

    it("should generate the documentation of a class", function()
      check_class_output(
        [[
        ---@class TestMap @table
      ]],
        [[
        TestMap                                                              *TestMap*
            table
      ]]
      )
    end)

    it("should generate the documentation of a class without description, thanks tami :sob:", function()
      check_class_output(
        [[
        ---@class TestMap
      ]],
        [[
        TestMap                                                              *TestMap*
      ]]
      )
    end)

    it("should generate the documentation of a sub class", function()
      check_class_output(
        [[
        ---@class TestArray : TestMap @array
      ]],
        [[
        TestArray : TestMap                                                *TestArray*
            array

            Parents: ~
                |TestMap|
      ]]
      )
    end)

    it("should generate the documentation of a class with fields", function()
      check_class_output(
        [[
        ---@class Array @number indexed starting at 1
        ---@field count number: Always handy to have a count
        ---@field type string: Imagine having a type for an array
        ---@field begin function: It even has a begin()?! Is this cpp?
        ---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this. Please work :)
      ]],
        [[
        Array                                                                  *Array*
            number indexed starting at 1

            Fields: ~
                {count} (number)    Always handy to have a count
                {type}  (string)    Imagine having a type for an array
                {begin} (function)  It even has a begin()?! Is this cpp?
                {end}   (function)  It even has an end()?! Get out of here cpp! Oh by
                                    the way did you know that fields are wrapping? I
                                    didn't and this should prove this. Please work :)
      ]]
      )
    end)

    it(
      "should generate the documentation of a class with fields without description, thanks again tami :sob:",
      function()
        check_class_output(
          [[
        ---@class Array
        ---@field count number
      ]],
          [[
        Array                                                                  *Array*


            Fields: ~
                {count} (number)
      ]]
        )
      end
    )

    it("should generate the documentation of a class with fields and multitypes", function()
      check_class_output(
        [[
        ---@class Array @number indexed starting at 1
        ---@field count number: Always handy to have a count
        ---@field type string|number: Imagine having a type for an array
        ---@field begin function: It even has a begin()?! Is this cpp?
        ---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this. Please work :)
      ]],
        [[
        Array                                                                  *Array*
            number indexed starting at 1

            Fields: ~
                {count} (number)         Always handy to have a count
                {type}  (string|number)  Imagine having a type for an array
                {begin} (function)       It even has a begin()?! Is this cpp?
                {end}   (function)       It even has an end()?! Get out of here cpp!
                                         Oh by the way did you know that fields are
                                         wrapping? I didn't and this should prove
                                         this. Please work :)
      ]]
      )
    end)

    it("should generate the documentation of a class with fields ascending", function()
      check_class_output(
        [[
        ---@config { field_order = 'ascending' }

        ---@class Array @number indexed starting at 1
        ---@field count number: Always handy to have a count
        ---@field type string: Imagine having a type for an array
        ---@field begin function: It even has a begin()?! Is this cpp?
        ---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this. Please work :)
      ]],
        [[
        Array                                                                  *Array*
            number indexed starting at 1

            Fields: ~
                {begin} (function)  It even has a begin()?! Is this cpp?
                {count} (number)    Always handy to have a count
                {end}   (function)  It even has an end()?! Get out of here cpp! Oh by
                                    the way did you know that fields are wrapping? I
                                    didn't and this should prove this. Please work :)
                {type}  (string)    Imagine having a type for an array
      ]]
      )
    end)

    it("should generate the documentation of a class with fields descending", function()
      check_class_output(
        [[
        ---@config { field_order = 'descending' }

        ---@class Array @number indexed starting at 1
        ---@field count number: Always handy to have a count
        ---@field type string: Imagine having a type for an array
        ---@field begin function: It even has a begin()?! Is this cpp?
        ---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this. Please work :)
      ]],
        [[
        Array                                                                  *Array*
            number indexed starting at 1

            Fields: ~
                {type}  (string)    Imagine having a type for an array
                {end}   (function)  It even has an end()?! Get out of here cpp! Oh by
                                    the way did you know that fields are wrapping? I
                                    didn't and this should prove this. Please work :)
                {count} (number)    Always handy to have a count
                {begin} (function)  It even has a begin()?! Is this cpp?
      ]]
      )
    end)

    it("should generate the documentation of a class with fields with function", function()
      check_class_output(
        [[
        ---@config { field_order = function(tbl) table.sort(tbl, function(a, b) return a > b end) end }

        ---@class Array @number indexed starting at 1
        ---@field count number: Always handy to have a count
        ---@field type string: Imagine having a type for an array
        ---@field begin function: It even has a begin()?! Is this cpp?
        ---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this. Please work :)
      ]],
        [[
        Array                                                                  *Array*
            number indexed starting at 1

            Fields: ~
                {type}  (string)    Imagine having a type for an array
                {end}   (function)  It even has an end()?! Get out of here cpp! Oh by
                                    the way did you know that fields are wrapping? I
                                    didn't and this should prove this. Please work :)
                {count} (number)    Always handy to have a count
                {begin} (function)  It even has a begin()?! Is this cpp?
      ]]
      )
    end)

    it("should generate the documentation of a sub class with fields", function()
      check_class_output(
        [[
        ---@class Array : Map @number indexed starting at 1
        ---@field count number: Always handy to have a count
        ---@field type string: Imagine having a type for an array
        ---@field begin function: It even has a begin()?! Is this cpp?
        ---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this. Please work :)
      ]],
        [[
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
      ]]
      )
    end)

    it("should generate the documentation of multiple classes in file order", function()
      check_class_output(
        [[
        ---@class TestMap @table
        ---@class TestArray @array
      ]],
        [[
        TestMap                                                              *TestMap*
            table


        TestArray                                                          *TestArray*
            array
      ]]
      )
    end)

    it("should generate the documentation of multiple classes in ascending order", function()
      check_class_output(
        [[
        ---@config { ['class_order'] = 'ascending' }

        ---@class B @desc
        ---@class C @desc
        ---@class A @desc
      ]],
        [[
          A                                                                          *A*
              desc


          B                                                                          *B*
              desc


          C                                                                          *C*
              desc
      ]]
      )
    end)

    it("should generate the documentation of multiple classes in descending order", function()
      check_class_output(
        [[
        ---@config { ['class_order'] = 'descending' }

        ---@class Ba @desc
        ---@class Cb @desc
        ---@class Ac @desc
      ]],
        [[
          Cb                                                                        *Cb*
              desc


          Ba                                                                        *Ba*
              desc


          Ac                                                                        *Ac*
              desc
      ]]
      )
    end)

    it("should generate the documentation of multiple classes with function", function()
      check_class_output(
        [[
        ---@config { class_order = function(tbl) table.sort(tbl, function(a, b) return a > b end) end }

        ---@class Ba @desc
        ---@class Cb @desc
        ---@class Ac @desc
      ]],
        [[
          Cb                                                                        *Cb*
              desc


          Ba                                                                        *Ba*
              desc


          Ac                                                                        *Ac*
              desc
      ]]
      )
    end)

    -- TODO(conni2461): What are we generating here?!
    -- Does field describe the input table or the class
    it("should be able to generate function class", function()
      check_class_output(
        [[
        local Job = {}

        --- HEADER
        ---@class Job @desc
        ---@field cmd string: command
        ---@param o table: options
        function Job:new(o)
          return setmetatable(o, self)
        end

        return Job
      ]],
        [[
        Job:new({o})                                                       *Job:new()*
            HEADER


            Parameters: ~
                {o} (table)  options

            Fields: ~
                {cmd} (string)  command]]
      )
    end)

    it("works with a complex but complete example", function()
      check_class_output(
        [[
        local m = {}

        ---@class passwd @The passwd c struct
        ---@field pw_name string: username
        ---@field pw_name string: user password
        ---@field pw_uid number: user id
        ---@field pw_gid number: groupd id
        ---@field pw_gecos string: user information
        ---@field pw_dir string: user home directory
        ---@field pw_shell string: user default shell

        --- Get user by id
        ---@param id number: user id
        ---@return passwd: returns a password table
        function m.get_user(id)
          return ffi.C.getpwuid(id)
        end

        return m]],
        [[
          passwd                                                                *passwd*
              The passwd c struct

              Fields: ~
                  {pw_name}  (string)  user password
                  {pw_uid}   (number)  user id
                  {pw_gid}   (number)  groupd id
                  {pw_gecos} (string)  user information
                  {pw_dir}   (string)  user home directory
                  {pw_shell} (string)  user default shell


          m.get_user({id})                                                *m.get_user()*
              Get user by id


              Parameters: ~
                  {id} (number)  user id

              Return: ~
                  passwd: returns a password table]]
      )
    end)
  end)
end)
