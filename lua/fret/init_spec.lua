local Fret = require('fret')

describe('Fret', function()
  describe('.setup()', function()
    local opts = {}
    before_each(function()
      opts = { mapkeys = {} }
    end)
    it('mapkeys field is required in the option table', function()
      opts.mapkeys = nil
      assert.has_error(function()
        Fret.setup(opts)
      end)
      opts.fret_timeout = 100
      opts.fret_enable_kana = true
      opts.altkeys = { rshift = 'FDSAREWQVCXZGTB', lshift = 'JKLUIOPNMHY' }
      opts.mapkeys = { fret_f = 'f', fret_F = 'T' }
      assert.equal(Fret.setup(opts), true)
    end)

    it('fret_timeout field must be integer', function()
      opts.fret_enable_kana = '100'
      assert.has_error(function()
        Fret.setup(opts)
      end)
    end)

    it('fret_enable_kana field must be boolean', function()
      opts.fret_enable_kana = 'true'
      assert.has_error(function()
        Fret.setup(opts)
      end)
    end)

    it('altkeys field must be table', function()
      opts.altkeys = '{}'
      assert.has_error(function()
        Fret.setup(opts)
      end)
    end)
  end)
end)
