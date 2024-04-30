if vim.g.loaded_fret then
  return
end

vim.g.loaded_fret = true

local UNIQ_ID = 'fret-nvim'
local hlgroup = {
  ignore = 'FretIgnore',
  first = 'FretCandidateFirst',
  second = 'FretCandidateSecond',
  sub = 'FretCandidateSub',
  alt = 'FretAlternative',
  hint = 'LspInlayHint',
}
local hl_detail = {
  light = {
    [hlgroup.ignore] = { default = true, fg = 'Gray', bg = 'NONE' },
    [hlgroup.first] = { default = true, fg = 'DarkCyan', bg = 'NONE', underline = true },
    [hlgroup.second] = { default = true, fg = 'DarkCyan', bg = 'NONE', underline = true },
    [hlgroup.sub] = { default = true, fg = 'LightBlue', bg = 'NONE' },
    [hlgroup.alt] = { default = true, fg = 'LightCyan', bg = 'DarkCyan' },
  },
  dark = {
    [hlgroup.ignore] = { default = true, fg = 'Gray', bg = 'NONE' },
    [hlgroup.first] = { default = true, fg = 'LightGreen', bg = 'NONE', underline = true },
    [hlgroup.second] = { default = true, fg = 'LightGreen', bg = 'NONE', underline = true },
    [hlgroup.sub] = { default = true, fg = 'DarkCyan', bg = 'NONE' },
    [hlgroup.alt] = { default = true, fg = 'DarkGreen', bg = 'LightGreen' },
  },
}
local augroup = vim.api.nvim_create_augroup(UNIQ_ID, { clear = true })

vim.g.fret_enable_kana = false
vim.g.fret_timeout = 0
_G._fret_highlights = {
  [0] = hlgroup.ignore,
  [1] = hlgroup.first,
  [2] = hlgroup.second,
  [3] = hlgroup.sub,
  [4] = hlgroup.alt,
  [5] = hlgroup.hint,
}

local rgx = vim.regex('^dark\\|light$')
local function set_hl()
  local bg = vim.go.background
  local hl = hl_detail[rgx:match_str(bg) and bg or 'dark']
  local iter = vim.iter(hl)
  iter:each(function(v)
    vim.api.nvim_set_hl(0, v, hl[v])
  end)
end

require('fret.util').autocmd({ 'ColorScheme' }, {
  desc = 'Reload fret hlgroups',
  group = augroup,
  callback = function()
    set_hl()
  end,
}, true)

set_hl()
