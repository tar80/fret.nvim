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
}
local hl_detail = {
  [hlgroup.ignore] = { fg = 'Gray', bg = 'NONE' },
  [hlgroup.first] = { fg = 'LightGreen', bg = 'NONE', underline = true },
  [hlgroup.second] = { fg = 'LightGreen', bg = 'DarkGreen' },
  [hlgroup.sub] = { fg = 'DarkGreen', bg = 'NONE' },
  [hlgroup.alt] = { fg = 'Black', bg = 'LightGreen' },
}
local augroup = vim.api.nvim_create_augroup(UNIQ_ID, { clear = true })

vim.g.fret_enable_kana = false
vim.g.fret_timeout = 0
vim.g._fret_highlights =
  { ['0'] = hlgroup.ignore, ['1'] = hlgroup.first, ['2'] = hlgroup.second, ['3'] = hlgroup.sub, ['4'] = hlgroup.alt }

---@param init? boolean
local function set_hl(init)
  for k, v in pairs(hl_detail) do
    if init then
      v.default = true
    end
    vim.api.nvim_set_hl(0, k, v)
  end
end

vim.api.nvim_create_autocmd({ 'ColorScheme' }, {
  group = augroup,
  callback = function()
    set_hl()
  end,
})

set_hl(true)
