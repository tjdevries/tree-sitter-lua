local eq = assert.are.same
local renderer = require('docgen.renderer')

describe('renderer', function()
  describe('without prefix', function()
    it('should handle short lines', function()
      eq('Hello World', renderer.render({ 'Hello World' }, '', 80))
    end)

    it('should handle short lines with multiple entires', function()
      eq('Hello World', renderer.render({ 'Hello' , 'World' }, '', 80))
    end)

    it('should wrap line that exceed width', function()
      eq('Hello\nWorld', renderer.render({ 'Hello World' }, '', 5))
    end)

    it('should wrap lines that exceed width', function()
      eq('Hello\nWorld', renderer.render({ 'Hello', 'World' }, '', 5))
    end)

    it('should insert blank line', function()
      eq('Hello\n\nWorld', renderer.render({ 'Hello', '', 'World' }, '', 80))
    end)

    it('should keep punctuation', function()
      eq('Hello.\n\nWorld', renderer.render({ 'Hello.', '', 'World' }, '', 80))
    end)
  end)

  describe('with prefix', function()
    it('should handle short lines', function()
      eq('    Hello World', renderer.render({ 'Hello World' }, '    ', 80))
    end)

    it('should handle short lines with multiple entires', function()
      eq('    Hello World', renderer.render({ 'Hello' , 'World' }, '    ', 80))
    end)

    it('should wrap line that exceed width', function()
      eq('    Hello\n    World', renderer.render({ 'Hello World' }, '    ', 10))
    end)

    it('should wrap lines that exceed width', function()
      eq('    Hello\n    World', renderer.render({ 'Hello', 'World' }, '    ', 10))
    end)

    it('should insert blank line', function()
      eq('    Hello\n\n    World', renderer.render({ 'Hello', '', 'World' }, '    ', 80))
    end)

    it('should keep punctuation', function()
      eq('    Hello.\n\n    Wo, rld', renderer.render({ 'Hello.', '', 'Wo, rld' }, '    ', 80))
    end)
  end)

  describe('can handle itemize without prefix', function()
    it('works with one short item', function()
      eq('- item', renderer.render({ '- item' }, '', 80))
    end)

    it('works with multiple short items', function()
      eq('- item 1\n- item 2', renderer.render({ '- item 1', '- item 2' }, '', 80))
    end)

    it('works with wrap', function()
      eq('- item and\n  some more\n  things\n- item 2',
        renderer.render({ '- item and some more things', '- item 2' }, '', 12)
      )
    end)

    it('works with nested itemize', function()
      eq('- item 1\n  - item 1.1\n    - item 1.1.1\n  - item 1.2\n- item 2',
        renderer.render({
          '- item 1',
          '  - item 1.1',
          '    - item 1.1.1',
          '  - item 1.2',
          '- item 2',
        }, '', 80)
      )
    end)

    it('works with longer nested itemize', function()
      eq([[- item one with
  some
  additional
  context
  - item one.one
    with more
    context
    - item
      one.one.one
      with even
      more
      context
  - item one.two
    no context
- item two]],
        renderer.render({
          '- item one with some additional context',
          '  - item one.one with more context',
          '    - item one.one.one with even more context',
          '  - item one.two no context',
          '- item two',
        }, '', 16)
      )
    end)
  end)

  describe('can handle itemize with prefix', function()
    it('works with one short item', function()
      eq('- item', renderer.render({ '- item' }, '', 80))
    end)

    it('works with multiple short items', function()
      eq('    - item 1\n    - item 2', renderer.render({ '- item 1', '- item 2' }, '    ', 80))
    end)

    it('works with wrap', function()
      eq('    - item and\n      some more\n      things\n    - item 2',
        renderer.render({ '- item and some more things', '- item 2' }, '    ', 16)
      )
    end)

    it('works with nested itemize', function()
      eq([[    - item 1
      - item 1.1
        - item 1.1.1
      - item 1.2
    - item 2]],
        renderer.render({
          '- item 1',
          '  - item 1.1',
          '    - item 1.1.1',
          '  - item 1.2',
          '- item 2',
        }, '    ', 80)
      )
    end)

    it('works with longer nested itemize', function()
      eq([[    - item one with
      some
      additional
      context
      - item one.one
        with more
        context
        - item
          one.one.one
          with even
          more
          context
      - item one.two
        no context
    - item two]],
        renderer.render({
          '- item one with some additional context',
          '  - item one.one with more context',
          '    - item one.one.one with even more context',
          '  - item one.two no context',
          '- item two',
        }, '    ', 20)
      )
    end)
  end)

  it('can handle a text with paragraphes and itemize', function()
    local input = vim.trim[[
This is the first paragraph and describes a cool looking function. This string is longer than 80 so
the renderer should wrap it.
If not this would be pretty bad.

This is a new and short paragraph and the header of itemize:
- This is the first item
- This is the second item and is way longer than the first item which means it has to be wrapped. I hope
the renderer does this for me
- This is a third short item
    ]]

    local expected = [[This is the first paragraph and describes a cool looking function. This string
is longer than 80 so the renderer should wrap it. If not this would be pretty
bad.

This is a new and short paragraph and the header of itemize:
- This is the first item
- This is the second item and is way longer than the first item which means it
  has to be wrapped. I hope the renderer does this for me
- This is a third short item]]
    eq(expected, renderer.render(vim.split(input, '\n'), '', 80))
  end)

  it('can switch between itemize and paragraph', function()
    local input = vim.trim[[
This is the first paragraph and describes a cool looking function. This string is longer than 80 so
the renderer should wrap it.
If not this would be pretty bad.

- This is the first item
- This is the second item and is way longer than the first item which means it has to be wrapped. I hope
the renderer does this for me
- This is a third short item

New Paragraph. Please be shown

- New itemize
    ]]

    local expected = [[This is the first paragraph and describes a cool looking function. This string
is longer than 80 so the renderer should wrap it. If not this would be pretty
bad.

- This is the first item
- This is the second item and is way longer than the first item which means it
  has to be wrapped. I hope the renderer does this for me
- This is a third short item

New Paragraph. Please be shown

- New itemize]]
    eq(expected, renderer.render(vim.split(input, '\n'), '', 80))
  end)

  it('More fluid changes between paragraph and itemize', function()
    local input = [[
Examples of wrappers are:
  - `new_buffer_previewer`
  - `new_termopen_previewer`

To create a new table do following:
  - `local new_previewer = Previewer:new(opts)`

What `:new` expects is listed below]]

    local expected = [[
Examples of wrappers are:
  - `new_buffer_previewer`
  - `new_termopen_previewer`

To create a new table do following:
  - `local new_previewer = Previewer:new(opts)`

What `:new` expects is listed below]]
    eq(expected, renderer.render(vim.split(input, '\n'), '', 80))
  end)
end)
