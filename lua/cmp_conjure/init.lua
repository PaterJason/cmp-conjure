local cmp = require'cmp'
local conjure_eval = require'conjure.eval'

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
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

local function lookup_kind(s, ft)
  local ft_kinds = kind_tbl[ft]
  if ft_kinds then
    return ft_kinds[s]
  else
    return
  end
end

function source:complete(request, callback)
  local input = string.sub(request.context.cursor_before_line, request.offset)

  conjure_eval.completions(input, function(results)
    local items = {}
    for _, completion in ipairs(results) do
      table.insert(items, {
        label = completion.word,
        documentation = {
          kind = cmp.lsp.MarkupKind.Markdown,
          value = completion.info,
        },
        kind = lookup_kind(completion.kind, request.context.filetype),
      })
    end
    callback(items)
  end)
end

return source
