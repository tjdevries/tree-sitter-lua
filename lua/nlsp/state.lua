
local storage = {}

--- Map<string, TextDocumentItem>
storage.textDocumentItems = {}

local state = {}

state._clear = function()
  storage = {}
  storage.textDocumentItems = {}
end

--[[ TextDocumentItem
interface TextDocumentItem {
    -- The text document's URI.
    uri: DocumentUri;

    -- The text document's language identifier.
    languageId: string;

    -- The version number of this document
    -- (it will increase after each change, including undo/redo).
    version: number;

    -- The content of the opened text document.
    text: string;
}

interface TextDocumentIdentifier {
  uri: DocumentUri;
}

interface VersionTextDocumentIdentifier extends TextDocumentIdentifier {
  version: number | null;
}
--]]

state.textDocumentItem = {}

state.textDocumentItem.open = function(textDocumentItem)
  assert(not storage.textDocumentItems[textDocumentItem.uri], "Should not have received an open for this before")
  storage.textDocumentItems[textDocumentItem.uri] = textDocumentItem

  -- TODO: Should probably do something with this...
end

state.textDocument = {}

state.textDocument.change = function(textDocument, contentChanges)
  assert(storage.textDocumentItems[textDocument.uri], "Should have already loaded this textDocument")

  assert(contentChanges, "Should have some changes to apply")
  assert(#contentChanges == 1, "Can only handle one change")

  local changes = contentChanges[1]
  assert(not changes.range)
  assert(not changes.rangeLength)

  state.textDocument.save(textDocument, changes.text)

  -- TODO: Should probably do something with this...
end

state.textDocument.save = function(textDocument, text)
  assert(storage.textDocumentItems[textDocument.uri], "Should have already loaded this textDocument")
  storage.textDocumentItems[textDocument.uri].text = text
end

state.textDocument.close = function(textDocument)
  assert(storage.textDocumentItems[textDocument.uri], "Should have already loaded this textDocument")
  storage.textDocumentItems[textDocument.uri] = nil
end

function state.get_text_document_item(uri)
  return storage.textDocumentItems[uri]
end

return state
