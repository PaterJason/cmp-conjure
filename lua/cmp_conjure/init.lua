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

local kind_lookup = {
  F = 3,
  K = 14,
  M = 3,
  S = 18,
  V = 6,
  N = 9,
}

function source:get_keyword_pattern()
  return [[\%([0-9a-zA-Z\*\+!\-_'?<>=\/.:]*\)]]
end

function source:get_trigger_characters()
  return {'/', '.', ':'}
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
      kind = kind_lookup[completion.kind],
      dup = 0,
    })
  end
  callback(items)
end

return source
