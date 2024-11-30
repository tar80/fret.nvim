---@class config
---@field set_options fun(opts:Options):table?
local M = {}

local L_SHIFT = 'JKLUIOPNMHY'
local R_SHIFT = 'FDSAREWQVCXZGTB'
local KEYS = {
  fret_f = { key = 'f', direction = 'backward', till = 0 },
  fret_F = { key = 'F', direction = 'forward', till = 0 },
  fret_t = { key = 't', direction = 'backward', till = 1 },
  fret_T = { key = 'T', direction = 'forward', till = 1 },
}
local BEACON = {
  hl = 'FretAlternative',
  blend = 30,
  decay = 15,
}
local HLGROUP = {
  ignore = 'FretIgnore',
  first = 'FretCandidateFirst',
  second = 'FretCandidateSecond',
  sub = 'FretCandidateSub',
  alt = 'FretAlternative',
  hint = 'LspInlayHint',
}
local hlgroup = {
  [0] = HLGROUP.ignore,
  [1] = HLGROUP.first,
  [2] = HLGROUP.second,
  [3] = HLGROUP.sub,
  [4] = HLGROUP.alt,
  [5] = HLGROUP.hint,
}
local hl_detail = {
  light = {
    [HLGROUP.ignore] = { fg = 'Gray', bg = 'NONE' },
    [HLGROUP.first] = { fg = 'DarkCyan', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.second] = { fg = 'DarkCyan', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.sub] = { fg = 'LightBlue', bg = 'NONE', underdotted = true },
    [HLGROUP.alt] = { fg = 'LightCyan', bg = 'DarkCyan', bold = true },
  },
  dark = {
    [HLGROUP.ignore] = { fg = 'Gray', bg = 'NONE' },
    [HLGROUP.first] = { fg = 'LightGreen', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.second] = { fg = 'LightGreen', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.sub] = { fg = 'DarkCyan', bg = 'NONE', underdotted = true },
    [HLGROUP.alt] = { fg = 'DarkGreen', bg = 'LightGreen', bold = true },
  },
}

-- Register a fret operation key
---@param mapkey string
---@param direction Direction
---@param till integer
local function register_keymap(mapkey, direction, till)
  local desc = string.format('Fret %s jump', direction)
  local cmd = string.format('<Cmd>lua require("fret"):inst("%s", "%s", %s)<CR>', mapkey, direction, till)
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
    for k, v in pairs(KEYS) do
      local mapkey = opts.mapkeys[k] or ''
      if #mapkey == 1 then
        register_keymap(mapkey, v.direction, v.till)
      end
    end
  end
  vim.g.fret_timeout = opts.fret_timeout or 0

  local altkeys = {
    lshift = (opts.altkeys and opts.altkeys.lshift or L_SHIFT):upper(),
    rshift = (opts.altkeys and opts.altkeys.rshift or R_SHIFT):upper(),
  }
  local beacon = vim.tbl_extend('force', BEACON, opts.beacon_opts or {})

  return {
    altkeys = altkeys,
    beacon = beacon,
    hlgroup = hlgroup,
    hl_detail = hl_detail,
  }
end

return M
