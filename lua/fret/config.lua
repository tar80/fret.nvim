local Fret = require('fret')

---@class config
---@field set_options function
local M = {}

---@param opts table User configured options
M.set_options = function(opts)
  local default_keys = {
    fret_f = { key = 'f', direction = 'forward', till = 0 },
    fret_F = { key = 'F', direction = 'backward', till = 0 },
    fret_t = { key = 't', direction = 'forward', till = 1 },
    fret_T = { key = 'T', direction = 'backward', till = 1 },
  }

  vim.g.fret_enable_kana = opts.fret_enable_kana
  vim.g.fret_timeout = opts.fret_timeout

  if opts.altkeys then
    Fret.altkeys.lshift = string.upper(opts.altkeys.lshift or Fret.altkeys.lshift)
    Fret.altkeys.rshift = string.upper(opts.altkeys.rshift or Fret.altkeys.rshift)
  end

  if opts.mapkeys then
    for k, v in pairs(default_keys) do
      if type(opts.mapkeys[k]) == 'string' and #opts.mapkeys[k] == 1 then
        Fret.keymap(opts.mapkeys[k], v.key, v.direction, v.till)
      end
    end
  end
end

return M
