# 🎸fret.nvim

fret.nvim is provides enhanced f/t mapping for Neovim.  
Move the cursor to the desired character with fewer keystrokes.

In addition to the general f/t plugin behavior, it implements Related-mode.  
It provides alternate keys to jump to related character.

## Features

- [x] Related-mode is implemented
- [X] Repeat-keys (`;` `,` `.`) are valid. Excludes Related-mode
- [X] Always ignores uppercase and lowercase letters
- [x] Supports Kana-moji

[demo.webm](https://user-images.githubusercontent.com/45842304/229152547-096a0528-820f-4810-83aa-14d200e4a31f.webm)

## Requirements

- Neovim >= 0.9

## Installation

- lazy.nvim

```lua:
'tar80/fret.nvim'
```

## Configration

- `mapkeys` field must be set to activate fret.nvim. Other fields are not required

```lua:
require('fret.config').setup({
  fret_timeout = 0,
  fret_enable_kana = false,
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

## Credits

fret.nvim was developed inspired by vim-eft and fuzzy-motion.vim.  
Check out these nice plugins.

- [hrsh7th/vim-eft](https://github.com/hrsh7th/vim-eft)
- [yuki-yano/fuzzy-motion.vim](https://github.com/yuki-yano/fuzzy-motion.vim)

