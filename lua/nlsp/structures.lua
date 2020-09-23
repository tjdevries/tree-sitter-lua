-- TODO: Is this file useful at all?...
local structures = {}

structures.TextDocumentItem = {}

structures.TextDocumentItem.new = function(filename, text)
  return {
    uri = vim.uri_from_fname(filename),
    text = text,
  }
end

return structures
