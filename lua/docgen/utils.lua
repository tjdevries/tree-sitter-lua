local utils = {}

utils.wrap = function(str, limit, indent, indent1)
  indent = indent or ""
  indent1 = indent1 or indent
  limit = limit or 79
  local here = 1-#indent1
  return indent1 .. str:gsub("(%s+)()(%S+)()", function(sp, st, word, fi)
    local delta = 0
    word:gsub('@([@%a])', 
      function(c)
        if c == '@'     then delta = delta + 1 
        elseif c == 'x' then delta = delta + 5
        else                 delta = delta + 2 
        end
      end)
    here = here + delta
    if fi-here > limit then
      here = st - #indent + delta
      return "\n"..indent..word
    end
  end)
end

utils.read = function(f)
  local fp = assert(io.open(f))
  local contents = fp:read("all")
  fp:close()

  return contents
end


return utils
