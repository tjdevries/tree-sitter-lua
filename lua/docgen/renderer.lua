local m = {}

local Text = {}
Text.__index = Text

function Text:new()
  return setmetatable({
    state = nil,
    paragraphs = {},
    itemizes = {},
    enumerates = {},
    ignores = {},
    order = {},
  }, Text)
end

local states = setmetatable({
  NEWLINE = 'newline',
  ITEMIZE = 'itemize',
  ENUMERATE = 'enumerate',
  IGNORE = 'ignore',
  ENDIGNORE = 'endignore',
  PARAGRAPH = 'paragraph'
}, {
  __index = function(_, k)
    error(k .. ' is not a valid state!')
  end,
  __newindex = function(_, k, _)
    error('Not allowed to update ' .. k .. '!')
  end
})

local interpret_state = function(line)
  if line == '' then
    return states.NEWLINE
  elseif vim.startswith(vim.trim(line), '-') then
    return states.ITEMIZE
  elseif vim.trim(line):match('^[0-9]') then
    return states.ENUMERATE
  elseif line == '<pre>' then
    return states.IGNORE
  elseif line == '</pre>' then
    return states.ENDIGNORE
  else
    return states.PARAGRAPH
  end
end

local dispatch_state = {
  [states.PARAGRAPH] = function(self, line) return self:add_to_paragraph(line) end,
  [states.NEWLINE] = function(self) self:start_new_paragraph() end,
  [states.ITEMIZE] = function(self, line) return self:add_to_itemize(line) end,
  [states.ENUMERATE] = function(self, line) return self:add_to_enumerate(line) end,
}

local append = function(l, r)
  if #l == 0 then
    return r
  end
  if l:sub(#l, #l) == ' ' then
    return l .. r
  else
    return l .. ' ' .. r
  end
end

local trim_trailing = function(str)
  return str:gsub('%s*$', '')
end

function Text:error()
  error(
    string.format('Error while rendering things. Order: %s, paragraphs: %s, itemizes: %s, enumerates: %s, ignores: %s',
      vim.inspect(self.order),
      vim.inspect(self.paragraphs),
      vim.inspect(self.itemizes),
      vim.inspect(self.enumerates),
      vim.inspect(self.ignores)
    )
  )
end

function Text:handle_line(line)
  local new_state = interpret_state(line)

  if new_state == self.state then
    -- Happens when we didn't have a change in state
    dispatch_state[new_state](self, line)
  elseif new_state == states.IGNORE then
    -- Start new Ignore block
    self:start_new_ignore()
    self.state = new_state
  elseif self.state == states.IGNORE and new_state ~= states.ENDIGNORE then
    -- Write lines to ignore block
    self:add_to_ignore(line)
  elseif self.state == states.IGNORE and new_state == states.ENDIGNORE then
    -- End ignore block
    self.state = nil
  elseif self.state == states.NEWLINE and new_state == states.PARAGRAPH then
    -- From newline into new Paragraph
    if self.order[table.getn(self.order)] == states.IGNORE then
      -- If prev state was IGNORE add a newline on top
      table.insert(self.order, new_state)
    end
    self:start_new_paragraph(line)
    self.state = new_state
  elseif new_state == states.ITEMIZE then
    -- Start new Itemize block
    self:start_new_itemize(line)
    self.state = new_state
  elseif self.state == states.ITEMIZE and new_state == states.PARAGRAPH then
    -- If we have a new paragraph in an itemize (part of the previous itemize)
    self:append_to_itemize(line)
  elseif new_state == states.ENUMERATE then
    -- Start new Itemize block
    self:start_new_enumerate(line)
    self.state = new_state
  elseif self.state == states.ENUMERATE and new_state == states.PARAGRAPH then
    -- If we have a new paragraph in an itemize (part of the previous itemize)
    self:append_to_enumerate(line)
  elseif self.state == nil and new_state == states.PARAGRAPH then
    -- Start a new paragraph
    self:start_new_paragraph(line)
    self.state = new_state
  elseif new_state == states.NEWLINE and (self.state == states.ITEMIZE or
         self.state == states.ENUMERATE or
         self.state == states.PARAGRAPH or
         self.state == nil) then
    -- After a itemize have a empty line or
    -- Insert newline when Paragraph or
    -- Newline after a prev block was closed (pre)
    self:start_new_paragraph()
    self.state = new_state
  else
    self:error()
  end
end

function Text:iter()
  local i = 0
  local i_s = { paragraph = 0, itemize = 0, enumerate = 0, ignore = 0 }
  local n = table.getn(self.order)
  return function()
    i = i + 1
    if i <= n then
      i_s[self.order[i]] = i_s[self.order[i]] + 1
      if self.order[i] == states.PARAGRAPH then
        return self.order[i], self.paragraphs[i_s[self.order[i]]]
      elseif self.order[i] == states.ITEMIZE then
        return self.order[i], self.itemizes[i_s[self.order[i]]]
      elseif self.order[i] == states.ENUMERATE then
        return self.order[i], self.enumerates[i_s[self.order[i]]]
      elseif self.order[i] == states.IGNORE then
        return self.order[i], self.ignores[i_s[self.order[i]]]
      else
        self:error()
      end
    end
  end
end

function Text:start_new_paragraph(line)
  if table.getn(self.paragraphs) > 0 then
    self.paragraphs[table.getn(self.paragraphs)] = trim_trailing(self.paragraphs[table.getn(self.paragraphs)])
  end
  table.insert(self.paragraphs, "")
  table.insert(self.order, states.PARAGRAPH)
  if line then
    self:add_to_paragraph(line)
  end
end

function Text:start_new_itemize(line)
  table.insert(self.itemizes, { })
  table.insert(self.order, states.ITEMIZE)
  if line then
    self:add_to_itemize(line)
  end
end

function Text:start_new_enumerate(line)
  table.insert(self.enumerates, { })
  table.insert(self.order, states.ENUMERATE)
  if line then
    self:add_to_enumerate(line)
  end
end

function Text:start_new_ignore()
  table.insert(self.ignores, { })
  table.insert(self.order, states.IGNORE)
end

function Text:add_to_paragraph(str)
  if str:match('<br>$') then
    self.paragraphs[table.getn(self.paragraphs)] = append(self.paragraphs[table.getn(self.paragraphs)], str:gsub('<br>$', ''))
    self:start_new_paragraph()
  else
    self.paragraphs[table.getn(self.paragraphs)] = append(self.paragraphs[table.getn(self.paragraphs)], str)
  end
end

function Text:add_to_itemize(str)
  table.insert(self.itemizes[table.getn(self.itemizes)], str)
end

function Text:add_to_enumerate(str)
  table.insert(self.enumerates[table.getn(self.enumerates)], str)
end

function Text:add_to_ignore(str)
  table.insert(self.ignores[table.getn(self.ignores)], str)
end

function Text:append_to_itemize(str)
  local last_itemize = self.itemizes[table.getn(self.itemizes)]
  self.itemizes[table.getn(self.itemizes)][table.getn(last_itemize)] = append(last_itemize[table.getn(last_itemize)], str)
end

function Text:append_to_enumerate(str)
  local last_enumerate = self.enumerates[table.getn(self.enumerates)]
  self.enumerates[table.getn(self.enumerates)][table.getn(last_enumerate)] = append(last_enumerate[table.getn(last_enumerate)], str)
end

function Text:is_empty()
  return table.getn(self.paragraphs) == 0 and
         table.getn(self.itemizes) == 0 and
         table.getn(self.enumerates) == 0
end

m.render = function(input, prefix, width)
  assert(#prefix < width, "Please don't play games with me.")
  assert(type(input) == 'table', "Input has to be a table")

  local text = Text:new()

  for _, line in ipairs(vim.tbl_flatten(input)) do
    if not text:is_empty() or line ~= '' then
      text:handle_line(line)
    end
  end

  local output = {}

  local handle = function(string, additional_prefix)
    additional_prefix = additional_prefix or { '', '' }

    local line = prefix .. additional_prefix[1]
    local current_prefix = prefix .. additional_prefix[2]
    for _, word in ipairs(vim.split(string, ' ')) do
      if #append(line, word) <= width then
        line = append(line, word)
      else
        table.insert(output, line)
        line = current_prefix .. word
      end
    end
    if line:match('^%s+$') then line = '' end
    table.insert(output, line)
  end

  for type, paragraph in text:iter() do
    if type == states.PARAGRAPH then
      handle(paragraph)
    elseif type == states.ITEMIZE then
      for _, str in ipairs(paragraph) do
        local str_start, _ = str:find('-')
        local base = string.rep(' ', (str_start - 1))
        local additional_prefix = { base, base .. '  ' }
        handle(str, additional_prefix)
      end
    elseif type == states.ENUMERATE then
      local max, maxc = {}, {}
      for _, str in ipairs(paragraph) do
        local indent_level, newc = str:find('[0-9.]+%. ')
        indent_level = indent_level - 1
        newc = newc - indent_level
        if not newc then
          error('Invalid enumerate. Enumerates have to end with `dot`. Example: `1. Item` or `1.1. Item`')
        end
        if not maxc[indent_level] then
          maxc[indent_level] = newc
        else
          if newc > maxc[indent_level] then
            maxc[indent_level] = newc
          end
        end
      end
      for k, v in pairs(maxc) do
        max[k] = string.rep(' ', v)
      end
      for _, str in ipairs(paragraph) do
        local str_start, _ = str:find('[0-9.]+%. ')
        local _, str_end = str:gsub('^%s*', ''):find('[0-9]+. ')
        local base = string.rep(' ', (str_start - 1))
        local diff = string.rep(' ', (maxc[str_start - 1] - str_end))
        local additional_prefix = { base .. diff, base .. max[str_start - 1] }
        handle(str, additional_prefix)
      end
    elseif type == states.IGNORE then
      for _, str in ipairs(paragraph) do
        local construct = trim_trailing(prefix .. str)
        table.insert(output, construct)
      end
    else
      text:error()
    end
  end
  return table.concat(output, '\n')
end

--- renderi is a paragraph only rendering and is used for prefix indentation,
--- beginning second line.
---
--- Used for parameters and field description
m.renderi = function(input, prefix, width)
  assert(#prefix < width, "Please don't play games with me.")
  assert(type(input) == 'table', "Input has to be a table")

  local text = Text:new()

  for _, line in ipairs(vim.tbl_flatten(input)) do
    if not text:is_empty() or line ~= '' then
      text:handle_line(line)
    end
  end

  local output = {}
  for type, paragraph in text:iter() do
    if type == states.PARAGRAPH then
      local line = ""
      for _, word in ipairs(vim.split(paragraph, ' ')) do
        local inner_width = width
        if table.getn(output) == 0 then
          inner_width = inner_width - #prefix
        end
        if #append(line, word) <= inner_width then
          line = append(line, word)
        else
          table.insert(output, line)
          line = prefix .. word
        end
      end
      if line:match('^%s+$') then line = '' end
      table.insert(output, line)
    else
      error("Didn't i said paragraph only?! Read the friendly manual")
    end
  end
  return table.concat(output, '\n')
end

return m
