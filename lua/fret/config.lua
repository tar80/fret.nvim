---@class config
---@field set_options fun(opts:Options):table?
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
    require('fret').mapped_trigger = true
    return cmd
  end, { expr = true, desc = desc })
end

function M.set_options(opts)
  if not opts then
    return
  end
  vim.validate('fret_timeout', opts.fret_timeout, 'number', true)
  vim.validate('fret_enable_kana', opts.fret_enable_kana, 'boolean', true)
  vim.validate('fret_enable_symbol', opts.fret_enable_symbol, 'boolean', true)
  vim.validate('fret_repeat_notify', opts.fret_repeat_notify, 'boolean', true)
  vim.validate('fret_smart_fold', opts.fret_smart_fold, 'boolean', true)
  vim.validate('fret_hlmode', opts.fret_hlmode, 'string', true)
  vim.validate('fret_beacon', opts.fret_beacon, 'boolean', true)
  vim.validate('beacon_opts', opts.beacon_opts, 'table', true)
  vim.validate('altkeys', opts.altkeys, 'table', true)
  vim.validate('mapkeys', opts.mapkeys, 'table', false)
  if opts.fret_enable_kana then
    vim.g.fret_enable_kana = opts.fret_enable_kana
  end
  if opts.fret_enable_symbol then
    vim.g.fret_enable_symbol = opts.fret_enable_symbol
  end
  if opts.fret_repeat_notify then
    vim.g.fret_repeat_notify = opts.fret_repeat_notify
  end
  if opts.fret_hlmode then
    vim.g.fret_hlmode = opts.fret_hlmode
  end
  if opts.fret_beacon then
    vim.g.fret_beacon = opts.fret_beacon
  end
  if opts.fret_smart_fold then
    vim.g.fret_smart_fold = opts.fret_smart_fold
  end
  if opts.mapkeys then
    for k, v in pairs(_default_keys) do
      local mapkey = opts.mapkeys[k] or ''
      if #mapkey == 1 then
        register_keymap(mapkey, v.direction, v.till)
      end
    end
  end
  vim.g.fret_timeout = opts.fret_timeout or 0
  return {
    altkeys = opts.altkeys or {},
    beacon = opts.beacon_opts or {},
  }
end

return M
