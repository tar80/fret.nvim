local Fret = require('fret')

---@class config
---@field setup function
M = {}

---@param t table User configured options
M.setup = function(t)
  local default_keys = {
    fret_f = { key = 'f', direction = 'forward', till = 0 },
    fret_F = { key = 'F', direction = 'backward', till = 0 },
    fret_t = { key = 't', direction = 'forward', till = 1 },
    fret_T = { key = 'T', direction = 'backward', till = 1 },
  }

  vim.g.fret_enable_kana = t.fret_enable_kana
  vim.g.fret_timeout = t.fret_timeout

  if t.altkeys then
    Fret.altkeys.lshift = string.upper(t.altkeys.lshift or Fret.altkeys.lshift)
    Fret.altkeys.rshift = string.upper(t.altkeys.rshift or Fret.altkeys.rshift)
  end

  if t.mapkeys then
    for k, v in pairs(default_keys) do
      if type(t.mapkeys[k]) == 'string' and #t.mapkeys[k] == 1 then
        Fret.keymap(t.mapkeys[k], v.key, v.direction, v.till)
      end
    end
  end
end

return M
