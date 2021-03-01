local m = {}

local Text = {}
Text.__index = Text

function Text:new()
  return setmetatable({
    state = nil,
    paragraphs = {},
    itemizes = {},
    enumerates = {},
    order = {}
  }, Text)
end

local states = setmetatable({
  NEWLINE = 'newline',
  ITEMIZE = 'itemize',
  ENUMERATE = 'enumerate',
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
  else
    return states.PARAGRAPH
  end
end

local run_state = {
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

function Text:handle_line(line)
  local new_state = interpret_state(line)
  if new_state == self.state then
    run_state[new_state](self, line)
  elseif self.state == states.NEWLINE and new_state == states.PARAGRAPH then
    self:start_new_paragraph()
    run_state[new_state](self, line)
    table.insert(self.order, new_state)
    self.state = new_state
  elseif new_state == states.ITEMIZE then
    self:start_new_itemize()
    run_state[new_state](self, line)
    table.insert(self.order, new_state)
    self.state = new_state
  elseif self.state == states.ITEMIZE and new_state == states.PARAGRAPH then
    self:append_to_itemize(line)
  elseif self.state == states.ITEMIZE and new_state == states.NEWLINE then
    table.insert(self.order, states.PARAGRAPH)
    run_state[new_state](self, line)
    self.state = new_state
  else
    if new_state == states.NEWLINE then
      table.insert(self.order, self.state)
    else
      table.insert(self.order, new_state)
    end
    run_state[new_state](self, line)

    self.state = new_state
  end
end

function Text:iter()
  local i = 0
  local i_s = { paragraph = 0, itemize = 0, enumerate = 0 }
  local n = table.getn(self.order)
  return function()
    i = i + 1
    if i <= n then
      i_s[self.order[i]] = i_s[self.order[i]] + 1
      if self.order[i] == states.PARAGRAPH then
        return self.paragraphs[i_s[self.order[i]]]
      elseif self.order[i] == states.ITEMIZE then
        return self.itemizes[i_s[self.order[i]]]
      elseif self.order[i] == states.ENUMERATE then
        return self.enumerates[i_s[self.order[i]]]
      else
        error('Error in render engine')
      end
    end
  end
end

function Text:start_new_paragraph()
  table.insert(self.paragraphs, "")
end

function Text:start_new_itemize()
  table.insert(self.itemizes, { })
end

function Text:add_to_paragraph(str)
  if table.getn(self.paragraphs) == 0 then self:start_new_paragraph() end
  self.paragraphs[#self.paragraphs] = append(self.paragraphs[#self.paragraphs], str)
end

function Text:add_to_itemize(str)
  if table.getn(self.itemizes) == 0 then self:start_new_itemize() end
  table.insert(self.itemizes[#self.itemizes], str)
end

function Text:append_to_itemize(str)
  local last_itemize = self.itemizes[#self.itemizes]
  self.itemizes[#self.itemizes][#last_itemize] = append(last_itemize[#last_itemize], str)
end

function Text:add_to_enumerate(str)
  -- TODO(conni2461):
  return str
end

function Text:is_empty()
  return table.getn(self.paragraphs) == 0 and
         table.getn(self.itemizes) == 0 and
         table.getn(self.enumerates) == 0
end

m.render = function(input, prefix, width)
  assert(#prefix < width, "Please don't play games with me.")

  local text = Text:new()

  for _, line in ipairs(vim.tbl_flatten(input)) do
    if not text:is_empty() or line ~= '' then
      text:handle_line(line)
    end
  end

  local default_prefix_width = #prefix
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

  for paragraph in text:iter() do
    if type(paragraph) == 'string' then
      handle(paragraph)
    else
      for _, str in ipairs(paragraph) do
        local str_start, _ = str:find('-')
        local base = string.rep(' ', (str_start - 1))
        local additional_prefix = { base, base .. '  ' }
        handle(str, additional_prefix)
      end
    end
  end
  return table.concat(output, '\n')
end

return m
