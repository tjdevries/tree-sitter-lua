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
  NEWLINE = "newline",
  ITEMIZE = "itemize",
  ENUMERATE = "enumerate",
  IGNORE = "ignore",
  CODE = "code",
  ENDIGNORE = "endignore",
  PARAGRAPH = "paragraph",
}, {
  __index = function(_, k)
    error(k .. " is not a valid state!")
  end,
  __newindex = function(_, k, _)
    error("Not allowed to update " .. k .. "!")
  end,
})

local interpret_state = function(line)
  if line == "" then
    return states.NEWLINE
  elseif vim.startswith(vim.trim(line), "-") then
    return states.ITEMIZE
  elseif vim.trim(line):match "^[0-9]" then
    return states.ENUMERATE
  elseif line == "<code>" then
    return states.CODE
  elseif line == "<pre>" then
    return states.IGNORE
  elseif line == "</pre>" or line == "</code>" then
    return states.ENDIGNORE
  else
    return states.PARAGRAPH
  end
end

local dispatch_state = {
  [states.PARAGRAPH] = function(self, line)
    return self:add_to_paragraph(line)
  end,
  [states.NEWLINE] = function(self)
    self:start_new_paragraph()
  end,
  [states.ITEMIZE] = function(self, line)
    return self:add_to_itemize(line)
  end,
  [states.ENUMERATE] = function(self, line)
    return self:add_to_enumerate(line)
  end,
}

local trim_trailing = function(str)
  return str:gsub("%s*$", "")
end

local real_append = function(l, r)
  if #l == 0 then
    return r
  end
  if l:sub(#l, #l) == " " then
    return l .. r
  else
    return l .. " " .. r
  end
end

local append = function(l, r)
  if type(l) == "table" then
    if r:match "<br>$" then
      r = trim_trailing(r:gsub("<br>$", ""))
      l[#l] = real_append(l[#l], r)
      table.insert(l, "")
    else
      l[#l] = real_append(l[#l], r)
    end
    return l
  end
  return real_append(l, r)
end

function Text:error()
  error(
    string.format(
      "Error while rendering things. Order: %s, paragraphs: %s, itemizes: %s, enumerates: %s, ignores: %s",
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
  elseif new_state == states.CODE then
    -- Start new Ignore block
    self:start_new_ignore(true)
    self.state = states.IGNORE
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
    if self.order[#self.order] == states.IGNORE then
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
  elseif
    new_state == states.NEWLINE
    and (
      self.state == states.ITEMIZE
      or self.state == states.ENUMERATE
      or self.state == states.PARAGRAPH
      or self.state == nil
    )
  then
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
  local n = #self.order
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
  if #self.paragraphs > 0 then
    self.paragraphs[#self.paragraphs] = trim_trailing(self.paragraphs[#self.paragraphs])
  end
  table.insert(self.paragraphs, "")
  table.insert(self.order, states.PARAGRAPH)
  if line then
    self:add_to_paragraph(line)
  end
end

function Text:start_new_itemize(line)
  table.insert(self.itemizes, {})
  table.insert(self.order, states.ITEMIZE)
  if line then
    self:add_to_itemize(line)
  end
end

function Text:start_new_enumerate(line)
  table.insert(self.enumerates, {})
  table.insert(self.order, states.ENUMERATE)
  if line then
    self:add_to_enumerate(line)
  end
end

function Text:start_new_ignore(code)
  if code then
    table.insert(self.ignores, { ">" })
  else
    table.insert(self.ignores, {})
  end
  table.insert(self.order, states.IGNORE)
end

function Text:add_to_paragraph(str)
  if str:match "<br>$" then
    self.paragraphs[#self.paragraphs] = append(self.paragraphs[#self.paragraphs], str:gsub("<br>$", ""))
    self:start_new_paragraph()
  else
    self.paragraphs[#self.paragraphs] = append(self.paragraphs[#self.paragraphs], str)
  end
end

function Text:add_to_itemize(str)
  if str:match "<br>$" then
    str = trim_trailing(str:gsub("<br>$", ""))
    table.insert(self.itemizes[#self.itemizes], { str, "" })
  else
    table.insert(self.itemizes[#self.itemizes], str)
  end
end

function Text:add_to_enumerate(str)
  if str:match "<br>$" then
    str = trim_trailing(str:gsub("<br>$", ""))
    table.insert(self.enumerates[#self.enumerates], { str, "" })
  else
    table.insert(self.enumerates[#self.enumerates], str)
  end
end

function Text:add_to_ignore(str)
  table.insert(self.ignores[#self.ignores], str)
end

function Text:append_to_itemize(str)
  local last_itemize = self.itemizes[#self.itemizes]
  self.itemizes[#self.itemizes][#last_itemize] = append(last_itemize[#last_itemize], str)
end

function Text:append_to_enumerate(str)
  local last_enumerate = self.enumerates[#self.enumerates]
  self.enumerates[#self.enumerates][#last_enumerate] = append(last_enumerate[#last_enumerate], str)
end

function Text:is_empty()
  return #self.paragraphs == 0 and #self.itemizes == 0 and #self.enumerates == 0
end

local get_text_from_input = function(input)
  local text = Text:new()

  for _, line in ipairs(vim.tbl_flatten(input)) do
    if not text:is_empty() or line ~= "" then
      text:handle_line(line)
    end
  end

  return text
end

m.render = function(input, prefix, width)
  assert(#prefix < width, "Please don't play games with me.")
  assert(type(input) == "table", "Input has to be a table")

  local text = get_text_from_input(input)

  local output = {}

  local handle = function(string, additional_prefix)
    additional_prefix = additional_prefix or { "", "" }

    local line = prefix .. additional_prefix[1]
    local current_prefix = prefix .. additional_prefix[2]
    if type(string) ~= "table" then
      string = { string }
    end
    for idx, lstring in ipairs(string) do
      for _, word in ipairs(vim.split(lstring, " ")) do
        if #append(line, word) <= width then
          line = append(line, word)
        else
          table.insert(output, line)
          line = current_prefix .. word
        end
      end
      if string[idx + 1] ~= nil and string[idx + 1] ~= "" then
        line = trim_trailing(line)
        table.insert(output, line)
        line = current_prefix
      end
    end
    if line:match "^%s+$" then
      line = ""
    end
    line = trim_trailing(line)
    table.insert(output, line)
  end

  for typ, paragraph in text:iter() do
    if typ == states.PARAGRAPH then
      handle(paragraph)
    elseif typ == states.ITEMIZE then
      for _, str in ipairs(paragraph) do
        local str_start, _ = (function()
          if type(str) == "table" then
            return str[1]:find "-"
          end
          return str:find "-"
        end)()
        local base = string.rep(" ", (str_start - 1))
        local additional_prefix = { base, base .. "  " }
        handle(str, additional_prefix)
      end
    elseif typ == states.ENUMERATE then
      local max, maxc = {}, {}
      for _, str in ipairs(paragraph) do
        local indent_level, newc = (function()
          if type(str) == "table" then
            return str[1]:find "[0-9.]+%. "
          end
          return str:find "[0-9.]+%. "
        end)()
        indent_level = indent_level - 1
        newc = newc - indent_level
        if not newc then
          error "Invalid enumerate. Enumerates have to end with `dot`. Example: `1. Item` or `1.1. Item`"
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
        max[k] = string.rep(" ", v)
      end
      for _, str in ipairs(paragraph) do
        local str_start, str_end = (function()
          local left, right
          if type(str) == "table" then
            left, _ = str[1]:find "[0-9.]+%. "
            _, right = str[1]:gsub("^%s*", ""):find "[0-9]+. "
          else
            left, _ = str:find "[0-9.]+%. "
            _, right = str:gsub("^%s*", ""):find "[0-9]+. "
          end
          return left, right
        end)()

        local base = string.rep(" ", (str_start - 1))
        local diff = string.rep(" ", (maxc[str_start - 1] - str_end))
        local additional_prefix = { base .. diff, base .. max[str_start - 1] }
        handle(str, additional_prefix)
      end
    elseif typ == states.IGNORE then
      for _, str in ipairs(paragraph) do
        local construct = trim_trailing(prefix .. str)
        table.insert(output, construct)
      end
      if paragraph[1] == ">" then
        table.insert(output, "<")
      end
    else
      text:error()
    end
  end
  return table.concat(output, "\n")
end

--- This is a paragraph only rendering and is used for prefix indentation,
--- beginning second line.
---
--- Used for parameters and field description
m.render_without_first_line_prefix = function(input, prefix, width)
  assert(#prefix < width, "Please don't play games with me.")
  assert(type(input) == "table", "Input has to be a table")

  local text = get_text_from_input(input)

  local output = {}
  for type, paragraph in text:iter() do
    if type == states.PARAGRAPH then
      local line = ""
      for _, word in ipairs(vim.split(paragraph, " ")) do
        local inner_width = width
        if #output == 0 then
          inner_width = inner_width - #prefix
        end
        if #append(line, word) <= inner_width then
          line = append(line, word)
        else
          table.insert(output, line)
          line = prefix .. word
        end
      end
      if line:match "^%s+$" then
        line = ""
      end
      table.insert(output, line)
    else
      error "Didn't i said paragraph only?! Read the friendly manual"
    end
  end
  return table.concat(output, "\n")
end

return m
