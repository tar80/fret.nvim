local config = require('fret.config')

local HLGROUP = {
  ignore = 'FretIgnore',
  first = 'FretCandidateFirst',
  second = 'FretCandidateSecond',
  sub = 'FretCandidateSub',
  alt = 'FretAlternative',
  hint = 'LspInlayHint',
}

describe('Fret.config', function()
  describe('.set_options()', function()
    local opts = {}
    before_each(function()
      opts = { mapkeys = {} }
    end)
    it('mapkeys field is required in the option table', function()
      opts.mapkeys = nil
      assert.has_error(function()
        config.set_options(opts)
      end)
      opts.fret_timeout = 100
      opts.fret_enable_kana = true
      opts.fret_enable_symbol = true
      opts.fret_enable_notify = true
      opts.fret_hlmode = 'combine'
      opts.fret_enable_beacon = true
      opts.beacon_opts = { hl = 'FretAlternative', interval = 80, blend = 20, decay = 10 }
      opts.altkeys = { rshift = 'FDSAREWQVCXZGTB', lshift = 'JKLUIOPNMHY' }
      opts.mapkeys = { fret_f = 'f', fret_F = 'T' }
      assert.same(config.set_options(opts), {
        altkeys = opts.altkeys,
        beacon = opts.beacon_opts,
        hlgroup = {
          [0] = HLGROUP.ignore,
          [1] = HLGROUP.first,
          [2] = HLGROUP.second,
          [3] = HLGROUP.sub,
          [4] = HLGROUP.alt,
          [5] = HLGROUP.hint,
        },
        hl_detail = {
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
        },
      })
    end)

    it('fret_timeout field must be integer', function()
      opts.fret_enable_kana = '100'
      assert.has_error(function()
        config.set_options(opts)
      end)
    end)

    it('fret_enable_kana field must be boolean', function()
      opts.fret_enable_kana = 'true'
      assert.has_error(function()
        config.set_options(opts)
      end)
    end)

    it('fret_enable_symble field must be boolean', function()
      opts.fret_enable_kana = 'true'
      assert.has_error(function()
        config.set_options(opts)
      end)
    end)

    it('fret_repeat_notify field must be boolean', function()
      opts.fret_repeat_notify = 'true'
      assert.has_error(function()
        config.set_options(opts)
      end)
    end)

    it('altkeys field must be table', function()
      opts.altkeys = '{}'
      assert.has_error(function()
        config.set_options(opts)
      end)
    end)

    it('fret_beacon field must be boolean', function()
      opts.fret_enable_beacon = 'true'
      assert.has_error(function()
        config.set_options(opts)
      end)
    end)

    it('beacon_opts field must be table', function()
      opts.beacon_opts = '{}'
      assert.has_error(function()
        config.set_options(opts)
      end)
    end)
  end)
end)
