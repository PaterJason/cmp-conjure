local cmp = require "cmp"
local conjure_eval = require "conjure.eval"

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

function source:is_available()
  if require("conjure.client").current() == nil then
    return false
  else
    return true
  end
end

function source:get_keyword_pattern()
  return [[\k\+]]
end

function source:get_trigger_characters()
  return { "/", ".", ":" }
end

local kind_tbl = {
  clojure = {
    C = cmp.lsp.CompletionItemKind.Class,
    F = cmp.lsp.CompletionItemKind.Function,
    K = cmp.lsp.CompletionItemKind.Keyword,
    L = cmp.lsp.CompletionItemKind.Variable,
    M = cmp.lsp.CompletionItemKind.Function,
    N = cmp.lsp.CompletionItemKind.Module,
    R = cmp.lsp.CompletionItemKind.File,
    S = cmp.lsp.CompletionItemKind.Function,
    V = cmp.lsp.CompletionItemKind.Variable,
  },
  fennel = {
    ["boolean"] = cmp.lsp.CompletionItemKind.Value,
    ["function"] = cmp.lsp.CompletionItemKind.Function,
    ["nil"] = cmp.lsp.CompletionItemKind.Value,
    ["number"] = cmp.lsp.CompletionItemKind.Value,
    ["string"] = cmp.lsp.CompletionItemKind.Value,
    ["table"] = cmp.lsp.CompletionItemKind.Struct,
  },
}

function source:complete(request, callback)
  local input = string.sub(request.context.cursor_before_line, request.offset)

  conjure_eval.completions(input, function(results)
    local items = {}
    for _, completion in ipairs(results) do
      table.insert(items, {
        label = completion.word,
        detail = completion.menu,
        documentation = {
          kind = cmp.lsp.MarkupKind.PlainText,
          value = completion.info,
        },
        kind = (completion.kind and vim.tbl_get(kind_tbl, request.context.filetype, completion.kind))
          or cmp.lsp.CompletionItemKind.Text,
      })
    end
    callback(items)
  end)
end

return source
