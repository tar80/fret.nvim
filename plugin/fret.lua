if vim.g.loaded_fret then
  return
end

vim.g.loaded_fret = true

local UNIQ_ID = 'fret-nvim'
local HLGROUP = {
  ignore = 'FretIgnore',
  first = 'FretCandidateFirst',
  second = 'FretCandidateSecond',
  sub = 'FretCandidateSub',
  alt = 'FretAlternative',
  hint = 'LspInlayHint',
}
local hl_detail = {
  light = {
    [HLGROUP.ignore] = { default = true, fg = 'Gray', bg = 'NONE' },
    [HLGROUP.first] = { default = true, fg = 'DarkCyan', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.second] = { default = true, fg = 'DarkCyan', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.sub] = { default = true, fg = 'LightBlue', bg = 'NONE', underdotted = true },
    [HLGROUP.alt] = { default = true, fg = 'LightCyan', bg = 'DarkCyan', bold = true },
  },
  dark = {
    [HLGROUP.ignore] = { default = true, fg = 'Gray', bg = 'NONE' },
    [HLGROUP.first] = { default = true, fg = 'LightGreen', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.second] = { default = true, fg = 'LightGreen', bg = 'NONE', bold = true, underline = true },
    [HLGROUP.sub] = { default = true, fg = 'DarkCyan', bg = 'NONE', underdotted = true },
    [HLGROUP.alt] = { default = true, fg = 'DarkGreen', bg = 'LightGreen', bold = true },
  },
}
local augroup = vim.api.nvim_create_augroup(UNIQ_ID, { clear = true })

_G._fret_highlights = {
  [0] = HLGROUP.ignore,
  [1] = HLGROUP.first,
  [2] = HLGROUP.second,
  [3] = HLGROUP.sub,
  [4] = HLGROUP.alt,
  [5] = HLGROUP.hint,
}

local function set_hl()
  local hl = hl_detail[vim.go.background]
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
