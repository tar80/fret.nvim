local Fret = require('fret')

---@class config
---@field set_options fun(opts:Options):boolean?
local M = {}

local _default_keys = {
  fret_f = { key = 'f', direction = 'backward', till = 0 },
  fret_F = { key = 'F', direction = 'forward', till = 0 },
  fret_t = { key = 't', direction = 'backward', till = 1 },
  fret_T = { key = 'T', direction = 'forward', till = 1 },
}

-- Register a fret operation key
---@param mapkey string
---@param direction Direction
---@param till integer
local function register_keymap(mapkey, direction, till)
  local cmd = string.format('<Cmd>lua require("fret"):inst("%s", "%s", %s)<CR>', mapkey, direction, till)
  local desc = string.format('(fret-%s) Search for %s match', mapkey, direction)
  vim.keymap.set({ 'n', 'x', 'o' }, mapkey, function()
    Fret.mapped_trigger = true
    return cmd
  end, { expr = true, desc = desc })
end

function M.set_options(opts)
  if not opts then
    return false
  end
  vim.validate({
    fret_timeout = { opts.fret_timeout, 'number', true },
    fret_enable_kana = { opts.fret_enable_kana, 'boolean', true },
    fret_repeat_notify = { opts.fret_repeat_notify, 'boolean', true },
    fret_hlmode = { opts.fret_hlmode, 'string', true },
    altkeys = { opts.altkeys, 'table', true },
    mapkeys = { opts.mapkeys, 'table' },
  })
  if opts.fret_enable_kana then
    vim.g.fret_enable_kana = opts.fret_enable_kana
  end
  if opts.fret_repeat_notify then
    vim.g.fret_repeat_notify = opts.fret_repeat_notify
  end
  if opts.fret_hlmode then
    vim.g.fret_hlmode = opts.fret_hlmode
  end
  if opts.fret_timeout then
    vim.g.fret_timeout = opts.fret_timeout
  end
  if opts.altkeys then
    if opts.altkeys.lshift then
      Fret.altkeys.lshift = string.upper(opts.altkeys.lshift)
    end
    if opts.altkeys.rshift then
      Fret.altkeys.rshift = string.upper(opts.altkeys.rshift)
    end
  end
  if opts.mapkeys then
    for k, v in pairs(_default_keys) do
      local mapkey = opts.mapkeys[k] or ''
      if #mapkey == 1 then
        register_keymap(mapkey, v.direction, v.till)
      end
    end
  end
  return true
end

return M
