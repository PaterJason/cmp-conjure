local cmp = require'cmp'
local conjure_eval = require'conjure.eval'
local conjure_promise = require'conjure.promise'

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.promise_id = nil
  self.timer = nil
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

local function close(self)
  local completions
  if self.timer then
    self.timer:stop()
    self.timer:close()
    self.timer = nil
  end
  if self.promise_id then
    completions = conjure_promise.close(self.promise_id)
    self.promise_id = nil
  end
  return completions
end

function source:complete(request, callback)
  local input = string.sub(request.context.cursor_before_line, request.offset)

  close(self)
  self.promise_id = conjure_eval['completions-promise'](input)
  self.timer = vim.loop.new_timer()

  local i = 0
  self.timer:start(50, 50, vim.schedule_wrap(function()
    if conjure_promise['done?'](self.promise_id) then
      local items = {}
      local completions = close(self)
      for _, completion in ipairs(completions) do
        table.insert(items, {
          label = completion.word,
          documentation = {
            kind = cmp.lsp.MarkupKind.Markdown,
            value = completion.info,
          },
          kind = lookup_kind(completion.kind),
        })
      end
      callback(items)
    elseif i >= 200 then
      close(self)
      callback()
    end
    i = i + 1
  end))
end

return source
