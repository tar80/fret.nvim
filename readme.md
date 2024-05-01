# 🎸fret.nvim

fret.nvim is provides enhanced f/t mapping for Neovim.  
Move the cursor to the desired character with fewer keystrokes.

In addition to the general f/t plugin behavior, it implements Related-mode.  
It provides alternate keys to jump to related character.

## Features

- [x] Related-mode is implemented
- [x] Repeat-keys (`;` `,` `.`) are valid
- [x] Always ignores uppercase and lowercase letters
- [x] Supports Kana-moji

[demo.mp4](https://github.com/tar80/fret.nvim/assets/45842304/b2957866-9184-4ea7-9b79-2b18dca17853)

## Requirements

- Neovim >= 0.10.0-dev-2999

## Installation

- lazy.nvim

```lua:
{
  'tar80/fret.nvim',
  opts = {
    ...
  },
}
```

## Configuration

- `mapkeys` field must be set to activate fret.nvim. Other fields are optional

```lua:
require('fret.config').setup({
  fret_timeout = 0,
  fret_enable_kana = false,
  fret_enable_symbol = false,
  fret_repeat_notify = false,
  fret_hlmode = 'replace',
  mapkeys = {
    fret_f = 'f',
    fret_F = 'F',
    fret_t = 't',
    fret_T = 'T',
  },
  altkeys = {
    lshift = 'JKLUIOPNMHY',
    rshift = 'FDSAREWQVCXZTGB',
  },
})
```
## Known issues

- Hint may appear twice when starting fret from cursor position just before inlay_hint

## Credits

fret.nvim is inspired by vim-eft and fuzzy-motion.vim.  
Check out these nice plugins.

- [hrsh7th/vim-eft](https://github.com/hrsh7th/vim-eft)
- [yuki-yano/fuzzy-motion.vim](https://github.com/yuki-yano/fuzzy-motion.vim)
