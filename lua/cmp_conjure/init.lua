local cmp = require'cmp'
local conjure_eval = require'conjure.eval'

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.promise_id = nil
  self.input = nil
  return self
end

function source:is_available()
  return require'conjure.client'.current()
end

function source:get_keyword_pattern()
  return [[\%([0-9a-zA-Z\*\+!\-_'?<>=\/.:]*\)]]
end

function source:get_trigger_characters()
  return {'/', '.', ':'}
end

local kind_tbl = {
  clojure = {
    C = cmp.lsp.CompletionItemKind.Class,
    F = cmp.lsp.CompletionItemKind.Function,
    K = cmp.lsp.CompletionItemKind.Keyword,
    M = cmp.lsp.CompletionItemKind.Function,
    N = cmp.lsp.CompletionItemKind.Module,
    S = cmp.lsp.CompletionItemKind.Function,
    V = cmp.lsp.CompletionItemKind.Variable,
  },
}

local function lookup_kind(s)
  local ft_kind = kind_tbl[vim.bo.filetype]
  if ft_kind then
    return ft_kind[s]
  else
    return
  end
end

function source:complete(request, callback)
  local input = string.sub(request.context.cursor_before_line, request.offset)

  local completions = conjure_eval['completions-sync'](input)
  local items = {}

  for _, completion in ipairs(completions) do
    table.insert(items, {
      label = completion.word,
      documentation = {
        kind = cmp.lsp.MarkupKind.Markdown,
        value = completion.info,
      },
      kind = lookup_kind(completion.kind),
      dup = 0,
    })
  end
  callback(items)
end

return source
