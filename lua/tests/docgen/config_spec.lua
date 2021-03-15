local docgen = require('docgen')

local eq = assert.are.same

describe('config', function()
  describe('transform', function()
    it('should interpret config strings', function()
      local nodes = docgen.get_nodes[[---@config { ['function_order'] = "ascending" }]]
      eq({ config = {
        ['function_order'] = "ascending"
      }}, nodes)
    end)

    it('should interpret config functions', function()
      local nodes = docgen.get_nodes[[---@config { ['function_order'] = function(tbl) table.sort(tbl) end }]]
      eq("function", type(nodes.config.function_order))
    end)
  end)
end)
