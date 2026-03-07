# 🎸 fret.nvim

**fret.nvim** provides enhanced `f`/`t` mappings for Neovim, allowing you to move the cursor to any character with fewer keystrokes.

Beyond standard horizontal movement, it features a unique **Related-mode**, providing intuitive alternative keys to jump to distant or recurring characters instantly.

## Features

- [x] **Related-mode**: Smart two-step jumping for distant targets.
- [x] **Full Repeat Support**: Works seamlessly with `;`, `,`, and `.` (dot-repeat).
- [x] **Case-Insensitive**: Always ignores case for faster recognition.
- [x] **Multilingual**: Supports **Kana-moji** (Japanese) and Symbols.
- [x] **Visual Feedback**: Beacon flashes upon jumping to help track your cursor.
- [x] **Smart Fold**: Automatically opens/closes folds during searching.
- [x] **Same-Key-Chain**: Rapidly jump through identical characters using a single key.

[demo.mp4](https://github.com/tar80/fret.nvim/assets/45842304/b2957866-9184-4ea7-9b79-2b18dca17853)

### Same-Key-Chain function

When enabled, pressing the same lowercase key allows for rapid, chained actions. This is perfect for stepping through multiple occurrences of the same character without re-initiating the search.

Enable this by setting `fret_samekey_chain = true` in your configuration.

![same_key_chain](https://github.com/user-attachments/assets/ccef0487-07f6-40ba-992c-2278a953af7b)

## Requirements

- Neovim >= 0.10.0

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'tar80/fret.nvim',
  opts = {
    -- Your configuration here
  },
}
```

## Configuration

The mapkeys field must be set to activate fret.nvim. All other fields are optional.

```lua
require('fret').setup({
  mapkeys = {
    fret_f = 'f',
    fret_F = 'F',
    fret_t = 't',
    fret_T = 'T',
  },
  -- Optional settings (defaults shown below)
  fret_timeout = 0,         -- Timeout for input (ms). 0 is disabled.
  fret_max_length = 1000,   -- Max characters analyzed per line (for performance).
  fret_enable_beacon = false,
  fret_enable_kana = false,
  fret_enable_symbol = false,
  fret_repeat_notify = false,
  fret_samekey_chain = false,
  fret_smart_fold = false,
  fret_hlmode = 'replace',  -- 'replace' | 'combine' | 'blend'
  multi_label = {
    filler = ' ',           -- Multi-byte character alignment filler
    position = 'before'     -- 'before' | 'after'
  },
  beacon_opts = {
    hl = 'FretAlternative',
    interval = 80,
    blend = 20,
    decay = 10
  },
  altkeys = {
    lshift = 'JKLUIOPNMHY',
    rshift = 'FDSAREWQVCXZTGB',
  },
})
```

## Usage

1. Press f (or F/t/T).

2. Direct Jump: Type the lowercase character you see underlined.

3. Related-mode: Type the Uppercase version of a character to see "alternative labels" (Related-mode).
   Then, press the corresponding alternative key to jump.

<!-- ## Known issues -->

## Credits

fret.nvim is inspired by:

- [hrsh7th/vim-eft](https://github.com/hrsh7th/vim-eft)
- [yuki-yano/fuzzy-motion.vim](https://github.com/yuki-yano/fuzzy-motion.vim)
