local config = require('fret.config')

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
      opts.altkeys = { rshift = 'FDSAREWQVCXZGTB', lshift = 'JKLUIOPNMHY' }
      opts.mapkeys = { fret_f = 'f', fret_F = 'T' }
      assert.are.equal(config.set_options(opts), true)
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
        config.setup(opts)
      end)
    end)

    it('fret_enable_symble field must be boolean', function()
      opts.fret_enable_kana = 'true'
      assert.has_error(function()
        config.setup(opts)
      end)
    end)

    it('fret_repeat_notify field must be boolean', function()
      opts.fret_repeat_notify = 'true'
      assert.has_error(function()
        config.setup(opts)
      end)
    end)

    it('altkeys field must be table', function()
      opts.altkeys = '{}'
      assert.has_error(function()
        config.setup(opts)
      end)
    end)
  end)
end)

