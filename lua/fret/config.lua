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
  interval = 80,
  blend = 20,
  decay = 10,
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
---@param mapkeys table<MapKeys,string>
local function register_keymap(mapkeys)
  for k, v in pairs(KEYS) do
    local mapkey = mapkeys[k] or ''
    if #mapkey == 1 then
      local cmd = string.format('<Cmd>lua require("fret"):inst("%s", "%s", %s)<CR>', mapkey, v.direction, v.till)
      local desc = string.format('Fret %s jump', v.direction)
      vim.keymap.set({ 'n', 'x', 'o' }, mapkey, function()
        require('fret').mapped_trigger = true
        return cmd
      end, { expr = true, desc = desc })
    end
  end
  vim.keymap.set({ 'n', 'x' }, '<Plug>(fret-cue)', function()
    require('fret').same_key_repeat()
  end, { desc = 'Fret same-key-repeat' })
  vim.keymap.set({ 'n', 'x' }, '<Plug>(fret-cue)<Nul>', '<Nop>', { desc = 'Fret dummy map for same-key-repeat' })
end

function M.set_options(opts)
  if not opts then
    return
  end
  vim.validate('fret_timeout', opts.fret_timeout, 'number', true)
  vim.validate('fret_samekey_timeout', opts.fret_samekey_timeout, 'number', true)
  vim.validate('fret_enable_beacon', opts.fret_enable_beacon, 'boolean', true)
  vim.validate('fret_enable_kana', opts.fret_enable_kana, 'boolean', true)
  vim.validate('fret_enable_symbol', opts.fret_enable_symbol, 'boolean', true)
  vim.validate('fret_repeat_notify', opts.fret_repeat_notify, 'boolean', true)
  vim.validate('fret_smart_fold', opts.fret_smart_fold, 'boolean', true)
  vim.validate('fret_hlmode', opts.fret_hlmode, 'string', true)
  vim.validate('beacon_opts', opts.beacon_opts, 'table', true)
  vim.validate('altkeys', opts.altkeys, 'table', true)
  vim.validate('mapkeys', opts.mapkeys, 'table', false)

  vim.g.fret_enable_beacon = opts.fret_enable_beacon
  vim.g.fret_enable_kana = opts.fret_enable_kana
  vim.g.fret_enable_symbol = opts.fret_enable_symbol
  vim.g.fret_repeat_notify = opts.fret_repeat_notify
  vim.g.fret_hlmode = opts.fret_hlmode
  vim.g.fret_smart_fold = opts.fret_smart_fold
  vim.g.fret_timeout = opts.fret_timeout or 0
  vim.g.fret_samekey_timeout = opts.fret_samekey_timeout or 0
  if opts.mapkeys then
    register_keymap(opts.mapkeys)
  end

  -- notify deprecated options
  if opts.fret_beacon then
    vim.deprecate('fret_beacon', 'fret_enable_beacon', 'recently', 'Fret', false)
  end

  local _altkeys = {
    lshift = (opts.altkeys and opts.altkeys.lshift or L_SHIFT):upper(),
    rshift = (opts.altkeys and opts.altkeys.rshift or R_SHIFT):upper(),
  }
  local _beacon = vim.tbl_extend('force', BEACON, opts.beacon_opts or {})

  return {
    altkeys = _altkeys,
    beacon = _beacon,
    hlgroup = hlgroup,
    hl_detail = hl_detail,
  }
end

return M
