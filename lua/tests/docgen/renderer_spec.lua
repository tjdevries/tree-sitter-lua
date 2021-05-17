local eq = assert.are.same
local renderer = require('docgen.renderer')

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

describe('renderer', function()
  describe('without prefix', function()
    it('should handle short lines', function()
      eq('Hello World', renderer.render({ 'Hello World' }, '', 80))
    end)

    it('should handle short lines with multiple entires', function()
      eq('Hello World', renderer.render({ 'Hello' , 'World' }, '', 80))
    end)

    it('should allow manually breakage at the end of line', function()
      eq('Hello\nWorld', renderer.render({ 'Hello<br>' , 'World' }, '', 80))
    end)

    it('should allow manually breakage at the end of line and trim', function()
      eq('Hello.\nWorld', renderer.render({ 'Hello. <br>' , 'World' }, '', 80))
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

    it('should allow manually breakage at the end of line', function()
      eq('    Hello\n    World', renderer.render({ 'Hello<br>' , 'World' }, '    ', 80))
    end)

    it('should allow manually breakage at the end of line and trim', function()
      eq('    Hello.\n    World', renderer.render({ 'Hello. <br>' , 'World' }, '    ', 80))
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

    it('works with br', function()
      eq(dedent[[
        - 0 <= number < 1
          This means total width as a percentage.
        - 1 <= number
          This means total width as a fixed number.]], renderer.render({
        '- 0 <= number < 1 <br>',
        '  This means total width as a percentage.',
        '- 1 <= number <br>',
        '  This means total width as a fixed number.'
      }, '', 80))
    end)

    it('works with br and wrap', function()
      eq(dedent[[
        - key idea of point one
          A very long and detailed explanation about point one that is longer than the
          width of the docs file.
        - key idea of point two
          An even longer and more detailed explanation about point two that would be far
          too long for use in a docs file without a break somewhere.]], renderer.render({
        '- key idea of point one <br>',
        '  A very long and detailed explanation about point one that is longer than the width of the docs file.',
        '- key idea of point two <br>',
        '  An even longer and more detailed explanation about point two that would be far too long for',
        '  use in a docs file without a break somewhere.'
      }, '', 80))
    end)

    it('works with multiple brs', function()
      eq(dedent[[
        - 0 <= number < 1
          This means total width as a percentage.
          This means total width as a percentage.
        - 1 <= number
          This means total width as a fixed number. This means total width as a fixed
          number.]], renderer.render({
        '- 0 <= number < 1 <br>',
        '  This means total width as a percentage.<br>',
        '  This means total width as a percentage.<br>',
        '- 1 <= number <br>',
        '  This means total width as a fixed number.',
        '  This means total width as a fixed number.',
      }, '', 80))
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
      eq(dedent([[
        - item one with
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
        - item two]]),
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

  describe('can handle enumerate without prefix', function()
    it('works with one short item', function()
      eq('1. item', renderer.render({ '1. item' }, '', 80))
    end)

    it('works with multiple short items', function()
      eq('1. item\n2. item', renderer.render({ '1. item', '2. item' }, '', 80))
    end)

    it('works with wrap', function()
      eq('1. item and\n   some more\n   things\n2. item',
        renderer.render({ '1. item and some more things', '2. item' }, '', 12)
      )
    end)

    it('can skip numbers', function()
      eq('1. item\n3. item\n5. item',
        renderer.render({ '1. item', '3. item', '5. item' }, '', 12)
      )
    end)

    it('formats against biggest number', function()
      eq(' 1. item\n 3. item\n10. item',
        renderer.render({ '1. item', '3. item', '10. item' }, '', 12)
      )
    end)

    it('formats against biggest number works in any order', function()
      eq('  1. item\n100. item\n 10. item',
        renderer.render({ '1. item', '100. item', '10. item' }, '', 12)
      )
    end)

    it('works with nested enumerate', function()
      eq('1. item\n  1.1. item\n    1.1.1. item\n  1.2. item\n2. item',
        renderer.render({
          '1. item',
          '  1.1. item',
          '    1.1.1. item',
          '  1.2. item',
          '2. item',
        }, '', 80)
      )
    end)

    it('works with nested complex enumerate', function()
      eq(dedent[[
        1. item
           10. item this
               should
               wrap at
               some
               point
            1.1.1. item
          1.2. item
        2. item]],
        renderer.render({
          '1. item',
          '  10. item this should wrap at some point',
          '    1.1.1. item',
          '  1.2. item',
          '2. item',
        }, '', 16)
      )
    end)
  end)

  describe('can handle enumerate with prefix', function()
    it('works with one short item', function()
      eq('  1. item', renderer.render({ '1. item' }, '  ', 80))
    end)

    it('works with multiple short items', function()
      eq('  1. item\n  2. item', renderer.render({ '1. item', '2. item' }, '  ', 80))
    end)

    it('works with wrap', function()
      eq('  1. item\n     and\n     some\n     more\n     things\n  2. item',
        renderer.render({ '1. item and some more things', '2. item' }, '  ', 12)
      )
    end)

    it('can skip numbers', function()
      eq('  1. item\n  3. item\n  5. item',
        renderer.render({ '1. item', '3. item', '5. item' }, '  ', 12)
      )
    end)

    it('formats against biggest number', function()
      eq('   1. item\n   3. item\n  10. item',
        renderer.render({ '1. item', '3. item', '10. item' }, '  ', 12)
      )
    end)

    it('formats against biggest number works in any order', function()
      eq('    1. item\n  100. item\n   10. item',
        renderer.render({ '1. item', '100. item', '10. item' }, '  ', 12)
      )
    end)

    it('works with br', function()
      eq(dedent[[
        1. 0 <= number < 1
           This means total width as a percentage.
        2. 1 <= number
           This means total width as a fixed number.]], renderer.render({
        '1. 0 <= number < 1 <br>',
        '   This means total width as a percentage.',
        '2. 1 <= number <br>',
        '   This means total width as a fixed number.'
      }, '', 80))
    end)

    it('works with br and wrap', function()
      eq(dedent[[
        1. key idea of point one
           A very long and detailed explanation about point one that is longer than the
           width of the docs file.
        2. key idea of point two
           An even longer and more detailed explanation about point two that would be
           far too long for use in a docs file without a break somewhere.]], renderer.render({
        '1. key idea of point one <br>',
        '   A very long and detailed explanation about point one that is longer than the width of the docs file.',
        '2. key idea of point two <br>',
        '   An even longer and more detailed explanation about point two that would be far too long for',
        '   use in a docs file without a break somewhere.'
      }, '', 80))
    end)

    it('works with multiple brs', function()
      eq(dedent[[
        1. 0 <= number < 1
           This means total width as a percentage.
           This means total width as a percentage.
        2. 1 <= number
           This means total width as a fixed number. This means total width as a fixed
           number.]], renderer.render({
        '1. 0 <= number < 1 <br>',
        '   This means total width as a percentage.<br>',
        '   This means total width as a percentage.<br>',
        '2. 1 <= number <br>',
        '   This means total width as a fixed number.',
        '   This means total width as a fixed number.',
      }, '', 80))
    end)

    it('works with nested enumerate', function()
      eq('  1. item\n    1.1. item\n      1.1.1. item\n    1.2. item\n  2. item',
        renderer.render({
          '1. item',
          '  1.1. item',
          '    1.1.1. item',
          '  1.2. item',
          '2. item',
        }, '  ', 80)
      )
    end)

    it('works with nested complex enumerate', function()
      eq([[  1. item
     10. item this
         should
         wrap at
         some
         point
      1.1.1. item
    1.2. item
  2. item]],
        renderer.render({
          '1. item',
          '  10. item this should wrap at some point',
          '    1.1.1. item',
          '  1.2. item',
          '2. item',
        }, '  ', 18)
      )
    end)
  end)

  describe('combination', function()
    it('can handle a text with paragraphes and itemize', function()
      local input = dedent[[
        This is the first paragraph and describes a cool looking function. This string is longer than 80 so
        the renderer should wrap it.
        If not this would be pretty bad.

        This is a new and short paragraph and the header of itemize:
        - This is the first item
        - This is the second item and is way longer than the first item which means it has to be wrapped. I hope
        the renderer does this for me
        - This is a third short item]]

      local expected = dedent[[
        This is the first paragraph and describes a cool looking function. This string
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
      local input = dedent[[
        This is the first paragraph and describes a cool looking function. This string is longer than 80 so
        the renderer should wrap it.
        If not this would be pretty bad.

        - This is the first item
        - This is the second item and is way longer than the first item which means it has to be wrapped. I hope
        the renderer does this for me
        - This is a third short item

        New Paragraph. Please be shown

        - New itemize]]

      local expected = dedent[[
        This is the first paragraph and describes a cool looking function. This string
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
      local input = dedent[[
        Examples of wrappers are:
          - `new_buffer_previewer`
          - `new_termopen_previewer`

        To create a new table do following:
          - `local new_previewer = Previewer:new(opts)`

        What `:new` expects is listed below]]

      local expected = dedent[[
        Examples of wrappers are:
          - `new_buffer_previewer`
          - `new_termopen_previewer`

        To create a new table do following:
          - `local new_previewer = Previewer:new(opts)`

        What `:new` expects is listed below]]
      eq(expected, renderer.render(vim.split(input, '\n'), '', 80))
    end)

    it('More changes between paragraph, itemize and enumerate', function()
      local input = dedent[[
        Examples of wrappers are:
          1. `new_buffer_previewer`
          2. `new_termopen_previewer`

        To create a new table do following:
          - `local new_previewer = Previewer:new(opts)`

        What `:new` expects is listed below with a long wrapping line that will lead into nested enumerate:
          1. Item
            1.1. Nooooo
              1.1.1. :(
            1.2. Nice
          2. I lost it writing this parser]]

      local expected = dedent[[
        Examples of wrappers are:
          1. `new_buffer_previewer`
          2. `new_termopen_previewer`

        To create a new table do following:
          - `local new_previewer = Previewer:new(opts)`

        What `:new` expects is listed below with a long wrapping line that will lead
        into nested enumerate:
          1. Item
            1.1. Nooooo
              1.1.1. :(
            1.2. Nice
          2. I lost it writing this parser]]
      eq(expected, renderer.render(vim.split(input, '\n'), '', 80))
    end)
  end)

  describe('pre without prefix', function()
    it('can ignore simple blocks', function()
      eq('Hello World', renderer.render({'<pre>', 'Hello World', '</pre>' }, '', 80))
    end)

    it('can ignore complex blocks', function()
      eq('Steps\n Hello\n  World', renderer.render({'<pre>', 'Steps', ' Hello', '  World', '</pre>' }, '', 80))
    end)

    it('combination with Paragraph', function()
      eq(dedent[[
        This is a long paragraph that will be wrapped after that we expect a pre block
        that will ignore stuff

        Steps
         Hello
          World

        End paragraph just for the LULW s. Please just work.]],
        renderer.render({
          'This is a long paragraph that will be wrapped after that we expect a pre block that will ignore stuff',
          '',
          '<pre>',
          'Steps',
          ' Hello',
          '  World',
          '</pre>',
          '',
          'End paragraph just for the LULW s. Please just work.',
        }, '', 80))
    end)
  end)

  describe('pre with prefix', function()
    it('can ignore simple blocks', function()
      eq('    Hello World', renderer.render({'<pre>', 'Hello World', '</pre>' }, '    ', 80))
    end)

    it('can ignore complex blocks', function()
      eq([[    Steps
     Hello
      World]], renderer.render({'<pre>', 'Steps', ' Hello', '  World', '</pre>' }, '    ', 80))
    end)

    it('combination with Paragraph', function()
      eq([[    This is a long paragraph that will be wrapped after that we expect a pre
    block that will ignore stuff

    Steps
     Hello
      World

    End paragraph just for the LULW s. Please just work.]], renderer.render(
        {
          'This is a long paragraph that will be wrapped after that we expect a pre block that will ignore stuff',
          '',
          '<pre>',
          'Steps',
          ' Hello',
          '  World',
          '</pre>',
          '',
          'End paragraph just for the LULW s. Please just work.',
        }, '    ', 80))
    end)
  end)
end)

describe("render_without_first_line_prefix", function()
  it("works with short line and no prefix", function()
    eq('Short line', renderer.render_without_first_line_prefix({'Short line'}, '', 80))
  end)

  it("works with short line and prefix", function()
    eq('Short line', renderer.render_without_first_line_prefix({'Short line'}, '    ', 80))
  end)

  it("works with long wrapping line and prefix", function()
    eq([[This should be longer than the line
    width, causing this to wrap and not
    wrap the first line. Thats insane.
    Hype!]],
    renderer.render_without_first_line_prefix(
      {
        'This should be longer than the line width, causing',
        'this to wrap and not wrap the first line. Thats insane. Hype!'
      }, '    ', 40))
  end)
end)
