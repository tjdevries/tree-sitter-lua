local eq = assert.are.same

describe('doc_wrapper', function()
  local wrap = function(text)
    return require("docgen.help")._format(
      text,
      text.prefix or "",
      text.width or 80
    )
  end

  it('should not do anything weird with short lines', function()
    eq("hello", wrap { "hello" })
  end)

  it('should put different items on new lines', function()
    eq("hello\nworld", wrap {"hello", "world"})
  end)

  it('should let you prefix lines', function()
    eq("  hello\n  world", wrap {"hello", "world", prefix = "  "})
  end)

  it('should wrap long lines', function()
    eq("hello\nworld", wrap { "hello world", width = 8 })
  end)

  it('should wrap and indent long lines', function()
    eq("   hello\n   world", wrap {
      "hello world",
      width = 9,
      prefix = "   "
    })
  end)

  it('should let you pass in a list of entries', function()
    eq("   hello\n   world", wrap {
      {"hello world"},
      width = 9,
      prefix = "   "
    })
  end)
end)
