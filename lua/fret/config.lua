local Fret = require('fret')

---@class config
---@field setup function
M = {}

---@param mapkey string Key to assign fret function
---@param key string `f` or `t` or `F` or `T`
---@param direction string `forward` or `backward`
---@param till integer `0` or `1`
local function map(mapkey, key, direction, till)
  vim.keymap.set({ 'n', 'x', 'o' }, mapkey, function()
    return string.format('<Cmd>lua require("fret").inst("%s", "%s", %s, true)<CR>', key, direction, till)
  end, { expr = true, desc = string.format('fret-%s go %s search', key, direction) })
end

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
        map(t.mapkeys[k], v.key, v.direction, v.till)
      end
    end
  end
end

return M
