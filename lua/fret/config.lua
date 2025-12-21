---@class config
---@field set_options fun(opts:Options):table?
local M = {}
local validate = require('fret.compat').validate

local MULTI_LABEL = { filler = ' ', position = 'after' }
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
  chain = 'FretChain',
}
local hlgroup = {
  [0] = HLGROUP.ignore,
  [1] = HLGROUP.first,
  [2] = HLGROUP.second,
  [3] = HLGROUP.sub,
  [4] = HLGROUP.alt,
  [5] = HLGROUP.hint,
  [6] = HLGROUP.chain,
}
local hl_detail = {
  light = {
    [HLGROUP.ignore] = { fg = 'Gray', bg = 'NONE' },
    [HLGROUP.first] = { fg = 'DarkCyan', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.second] = { fg = 'DarkCyan', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.sub] = { fg = 'LightBlue', bg = 'NONE', underdotted = true },
    [HLGROUP.alt] = { fg = 'LightCyan', bg = 'DarkCyan', bold = true },
    [HLGROUP.chain] = { fg = 'DarkCyan', bg = 'LightCyan', bold = true },
  },
  dark = {
    [HLGROUP.ignore] = { fg = 'Gray', bg = 'NONE' },
    [HLGROUP.first] = { fg = 'LightGreen', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.second] = { fg = 'LightGreen', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.sub] = { fg = 'DarkCyan', bg = 'NONE', underdotted = true },
    [HLGROUP.alt] = { fg = 'DarkGreen', bg = 'LightGreen', bold = true },
    [HLGROUP.chain] = { fg = 'LightGreen', bg = 'DarkGreen', bold = true },
  },
}

local function set_multi_label_pattern(opts)
  local label = opts.fret_multi_label or MULTI_LABEL
  local p = label.position == 'before' and '%s%%s' or '%%s%s'
  return p:format(label.filler)
end

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
    require('fret').same_key_chain()
  end, { desc = 'Fret same-key-chain' })
  vim.keymap.set({ 'n', 'x' }, '<Plug>(fret-cue)<Nul>', '<Nop>', { desc = 'Fret same-key-chain timeout' })
end

function M.set_options(opts)
  if not opts then
    return
  end
  validate('fret_multi_label', opts.fret_multi_label, function(t)
    local filler = t.filler
    local position = t.position
    if not (type(filler) == 'string' and #filler == 1) then
      return false, 'fret_multi_label["filler"] must be a "1 byte character"'
    end
    if not (type(position) == 'string' and (position == 'before' or position == 'after')) then
      return false, 'fret_multi_label["position"] must be "before" or "after"'
    end
    return true
  end, true)
  validate('fret_timeout', opts.fret_timeout, 'number', true)
  validate('fret_samekey_chain', opts.fret_samekey_chain, 'boolean', true)
  validate('fret_enable_beacon', opts.fret_enable_beacon, 'boolean', true)
  validate('fret_enable_kana', opts.fret_enable_kana, 'boolean', true)
  validate('fret_enable_symbol', opts.fret_enable_symbol, 'boolean', true)
  validate('fret_repeat_notify', opts.fret_repeat_notify, 'boolean', true)
  validate('fret_smart_fold', opts.fret_smart_fold, 'boolean', true)
  validate('fret_hlmode', opts.fret_hlmode, 'string', true)
  validate('beacon_opts', opts.beacon_opts, 'table', true)
  validate('altkeys', opts.altkeys, 'table', true)
  validate('mapkeys', opts.mapkeys, 'table', false)

  vim.g.fret_enable_beacon = opts.fret_enable_beacon
  vim.g.fret_enable_kana = opts.fret_enable_kana
  vim.g.fret_enable_symbol = opts.fret_enable_symbol
  vim.g.fret_repeat_notify = opts.fret_repeat_notify
  vim.g.fret_hlmode = opts.fret_hlmode
  vim.g.fret_samekey_chain = opts.fret_samekey_chain
  vim.g.fret_smart_fold = opts.fret_smart_fold
  vim.g.fret_timeout = opts.fret_timeout or 0

  if opts.mapkeys then
    register_keymap(opts.mapkeys)
  end

  -- notify deprecated options
  if opts.fret_samekey_repeat then
    vim.deprecate('fret_samekey_repeat', 'fret_samekey_chain', 'recently', 'Fret', false)
    vim.g.fret_samekey_chain = true
  end
  if opts.fret_beacon then
    vim.deprecate('fret_beacon', 'fret_enable_beacon', 'recently', 'Fret', false)
    vim.g.fret_enable_beacon = true
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
    multi_label = set_multi_label_pattern(opts),
  }
end

return M
