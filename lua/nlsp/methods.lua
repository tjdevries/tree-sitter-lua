local log = require('nlsp.log')
local rpc = require('nlsp.rpc')
local state = require('nlsp.state')

-- TODO: This shouldn't be called from here directly, it should be a layer that we call.
local ts = require('nlsp.ts')

local protocol = vim.lsp.protocol

local Config = {}

local methods = {}

function methods.initialize(params, id)
  if Initialized then
    error("already initialized!")
  end

  Config.root  = params.rootPath or params.rootUri

  log.info("Config.root = %q", Config.root)

  -- analyze.load_completerc(Config.root)
  -- analyze.load_luacheckrc(Config.root)

  --ClientCapabilities = params.capabilities
  Initialized = true

  -- hopefully this is modest enough
  return rpc.respond(id, nil, {
    capabilities = {
      -- completionProvider = {
      --   triggerCharacters = {".",":"},
      --   resolveProvider = false
      -- },
      definitionProvider = true,
      textDocumentSync = {
        openClose = true,

        -- Always send everything
        change = protocol.TextDocumentSyncKind.Full,

        -- Please send the whole text when you save
        -- because I'm too noob to do incremental stuff at the moment.
        save = { includeText = true },
      },
      hoverProvider = false,
      documentSymbolProvider = false,
      --referencesProvider = false,
      --documentHighlightProvider = false,
      --workspaceSymbolProvider = false,
      --codeActionProvider = false,
      --documentFormattingProvider = false,
      --documentRangeFormattingProvider = false,
      --renameProvider = false,
    }
  })
end

-- interface DidOpenTextDocumentParams {
--     -- The document that was opened.
--     textDocument: TextDocumentItem;
-- }
methods["textDocument/didOpen"] = function(params)
  state.textDocumentItem.open(params.textDocument)
end

methods["textDocument/didChange"] = function(params)
  state.textDocument.change(params.textDocument, params.contentChanges)
end

-- interface DidSaveTextDocumentParams {
--  -- The document that was saved.
--  textDocument: TextDocumentIdentifier;
--
--  -- Optional the content when saved.
--  -- Depends on the includeText value when the save notification was requested.
--  text?: string;
-- }
methods["textDocument/didSave"] = function(params)
  state.textDocument.save(params.textDocument, params.text)
end

methods["textDocument/didClose"] = function(params)
  state.textDocument.close(params.textDocument)
end


-- interface TextDocumentPositionParams {
--   textDocument: TextDocumentIdentifier
--   position: Position
-- }
methods["textDocument/definition"] = function(params)
  local definition = ts.get_definiton_at_position(params.position, vim.uri_to_bufnr(params.textDocument.uri))

  -- Send result
  rpc.respond(nil, {
    position = ts.node_to_position(definiton)
  })
end

return methods
