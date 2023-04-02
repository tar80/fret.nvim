if vim.g.loaded_fret then
  return
end

local fret_au = vim.api.nvim_create_augroup('fret-nvim', { clear = true })
local hl = {
  { name = 'FretConfirm', fg = 'LightGreen', bg = 'NONE', deco = 'underline' },
  { name = 'FretCandidate', fg = 'DarkCyan', bg = 'NONE', deco = 'NONE' },
  { name = 'FretAlternative', fg = 'Black', bg = 'LightGreen', deco = 'NONE' },
  { name = 'FretIgnore', fg = 'Gray', bg = 'NONE', deco = 'NONE' },
}

vim.g.loaded_fret = true
vim.g.fret_enable_kana = false
vim.g.fret_timeout = 0
vim.g._fret_highlights = { ['0'] = hl[4].name, ['1'] = hl[1].name, ['2'] = hl[2].name, ['3'] = hl[3].name }

local function set_hl()
  for _, v in ipairs(hl) do
    vim.api.nvim_command(
      string.format(
        'highlight! default %s gui=%s guifg=%s guibg=%s cterm=%s ctermfg=%s ctermbg=%s',
        v.name,
        v.deco,
        v.fg,
        v.bg,
        v.deco,
        v.fg,
        v.bg
      )
    )
  end
end

vim.api.nvim_create_autocmd({ 'ColorScheme' }, {
  group = fret_au,
  callback = function()
    set_hl()
  end,
})

set_hl()
