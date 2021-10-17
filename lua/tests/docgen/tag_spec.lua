local docgen = require "docgen"
local docgen_help = require "docgen.help"

local eq = assert.are.same

local dedent = require("plenary.strings").dedent

local get_dedented_nodes = function(source)
  return docgen.get_nodes(dedent(source))
end

describe("tag", function()
  local check_tag_string = function(input, tag_string)
    local nodes = get_dedented_nodes(input)

    eq(tag_string, nodes.tag)
  end

  it("should generate tag", function()
    check_tag_string(
      [=[
        ---@tag hello
      ]=],
      "hello"
    )
  end)

  it("should generate multiple tags", function()
    check_tag_string(
      [=[
        ---@tag hello       world
      ]=],
      "hello       world"
    )
  end)

  describe("help output", function()
    local function check_tag_output(input, output)
      local nodes = require("docgen").get_nodes(input)
      local result = docgen_help.format(nodes)
      result = result:gsub("================================================================================\n", "")

      eq(vim.trim(output), vim.trim(result))
    end

    it("should add tag", function()
      check_tag_output(
        [=[
        ---@tag hello
        ]=],
        [[*hello*]]
      )
    end)

    it("should add multiple tags", function()
      check_tag_output(
        [=[
        ---@tag hello world
        ]=],
        [[*hello* *world*]]
      )
    end)

    it("should not depend on the amount of whitespace in annotation", function()
      check_tag_output(
        [=[
        ---@tag hello  world      people
        ]=],
        [[*hello* *world* *people*]]
      )
    end)
  end)
end)
