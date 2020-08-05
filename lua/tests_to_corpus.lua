
local test_cases = {}


for _, filename in ipairs(vim.split(vim.fn.glob("./tests/*.scm"), "\n")) do
  local file = io.open(filename, "r")
  local outfile = io.open("corpus/" .. vim.fn.fnamemodify(filename, ":t:r") .. ".txt", "w")

  local in_code = false
  local in_test = false

  for line in file:lines() do
    if line == nil then
      print("LINE WAS NIL", _)
    elseif string.sub(line, 1, 3) == ';;;' then
      outfile:write("\n")
      outfile:write("==================\n")
      outfile:write(string.sub(line, 5) .. "\n")
      outfile:write("==================\n")
      outfile:write("\n")
    elseif string.sub(line, 1, 1) == ';' then
      in_code = true
      outfile:write(string.sub(line, 2) .. "\n")
    elseif #line > 0 then
      if in_code then
        outfile:write("\n---\n\n")
        in_code = false
      end
      outfile:write(line .. "\n")
    end
  end

  outfile:close()
end
