---@diagnostic disable: missing-fields
local assert = require('luassert')
local fret = require('fret')

describe('fret', function()
  local function create_test_session(mapkey, direction, till)
    local s = fret._session('new', mapkey, direction, till)
    s.info_width = 0
    s.leftcol = 0
    s.front_byteidx = 0
    s.cur_row = vim.api.nvim_win_get_cursor(0)[1]
    s.cur_col = vim.api.nvim_win_get_cursor(0)[2]
    s.bufnr = vim.api.nvim_get_current_buf()
    s.winid = vim.api.nvim_get_current_win()

    vim.api.nvim_set_option_value('wrap', false, { win = s.winid })
    s.keys.mark_pos[1] = 0

    return s
  end

  before_each(function()
    vim.cmd('enew!')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'hello world',
      'こんにちは世界',
      'third line',
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    vim.g.fret_hlmode = 'replace'
    vim.g.fret_enable_beacon = false
    vim.g.fret_enable_kana = true
    vim.g.fret_timeout = 1000
    vim.g.fret_max_length = 1000
    vim.g.fret_smart_fold = true

    pcall(fret.setup, {
      altkeys = { lshift = 'asdfg', rshift = 'hjkl;' },
      hlgroup = { [0] = 'Normal', [1] = 'Search', [2] = 'IncSearch', [3] = 'Error', [4] = 'Special', [5] = 'Comment' },
      beacon = { hl = 'IncSearch', interval = 100, blend = 0, decay = 15 },
      multi_label = ' %s',
    })
  end)

  describe('session management', function()
    it('should initialize a session with correct default flags', function()
      local s = create_test_session('f', 'forward', 0)
      assert.is_not_nil(s)
      assert.are.equal(1, s.cur_row)
      assert.is_false(s.reversive)
      assert.are.equal('utf-32', s.utf_encoding)
    end)

    it('should not error when setting info on an empty line', function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '' })
      local s = create_test_session('f', 'forward', 0)
      local indices = s:set_line_informations()
      assert.is_nil(indices)
    end)
  end)

  describe(':get_keys()', function()
    it('should preserve character order when reversive is false', function()
      local s = create_test_session('f', 'forward', 0)
      s.cur_col = 0
      local indices = 'abc'
      local line = s:get_keys(indices)

      assert.are.equal('abc', line)
      assert.are.equal(3, #s.keys.detail)
      assert.are.equal('a', s.keys.detail[1].chr)
    end)

    it('should reverse character order when reversive is true', function()
      local s = create_test_session('f', 'backward', 0)
      s.cur_col = 2
      local indices = 'abc'
      local line = s:get_keys(indices)

      assert.are.equal('cba', line)
    end)

    it('should map Japanese Kana to corresponding Romaji keys', function()
      local s = create_test_session('f', 'forward', 0)
      s.enable_kana = true
      s:store_key('あ', 1, 0, 1)
      assert.are.equal('a', s.keys.detail[1].chr)
    end)

    it('should handle search correctly in mixed ASCII and Multi-byte strings', function()
      local s = create_test_session('f', 'forward', 0)
      local mixed = 'aあb'
      local extracted = s:get_keys(mixed)
      assert.are.equal('aあb', extracted)
      assert.are.equal('b', s.keys.detail[3].chr)
    end)
  end)

  describe(':attach_extmark()', function()
    it('should attach extmarks when UI properties are initialized', function()
      local s = create_test_session('f', 'forward', 0)
      s.line = 'hello'

      s.keys.mark_pos = { [1] = 0, [2] = 1, [3] = 2, [4] = 3, [5] = 4 }
      s.keys.detail = { { level = 1, chr = 'h', actual = 'h', byteidx = 0, start_at = 1, double = false } }
      s.keys.first_idx = { ['h'] = 1 }

      local count = s:attach_extmark()
      assert.are.equal(1, count)

      local marks = vim.api.nvim_buf_get_extmarks(0, fret.ns, 0, -1, {})
      assert.is_true(#marks > 0)
    end)
  end)

  describe('Edge Cases', function()
    it('should truncate processing for very long lines (>1000 chars)', function()
      local long_line = string.rep('a', 1100)
      local s = create_test_session('f', 'forward', 0)
      s.cur_col = 0
      s:get_keys(long_line)
      assert.is_true(#s.keys.detail <= 1001)
    end)
  end)

  describe(':is_concealed()', function()
    it('should handle zerobase index conversion', function()
      local s = create_test_session('f', 'forward', 0)
      assert.is_not_nil(s:is_concealed())
    end)
  end)

  describe('Operator and Keystroke Logic', function()
    it("uses 'v' prefix when reversive is false (forward mode)", function()
      local s = create_test_session('f', 'forward', 0)
      s.line = 'hello'
      s.operative = true
      s.vcount = 1
      s.mapkey = 'f'
      s.keys.detail[1] = { actual = 'h', chr = 'h' }
      local keystroke = s:operable(1)
      assert.are.match('^v1fh', keystroke)
    end)

    it("uses 'hv' prefix when reversive is true (backward mode)", function()
      local s = create_test_session('f', 'backward', 0)
      s.line = 'hello'
      s.operative = true
      s.vcount = 1
      s.mapkey = 'f'
      s.keys.detail[1] = { actual = 'h', chr = 'h' }
      local keystroke = s:operable(1)
      assert.are.match('^hv1fh', keystroke)
    end)
  end)

  describe('Multi-level selection (Related keys)', function()
    it('should correctly map second-level labels to original positions', function()
      local s = create_test_session('f', 'forward', 0)
      s.line = 'aaa'
      s.keys.mark_pos = { [1] = 0, [2] = 1, [3] = 2 }

      for i = 1, 3 do
        s:store_key('a', i, i - 1, i)
      end

      local match_count = s:attach_extmark('a', 'a')
      assert.is_true(match_count >= 1)

      local has_labels = false
      for key, _ in pairs(s.keys.first_idx) do
        if key ~= 'a' then
          has_labels = true
          break
        end
      end
      assert.is_true(has_labels)
    end)
  end)

  describe('Multi-byte character boundaries', function()
    it('should calculate correct byte indices for Japanese characters', function()
      local s = create_test_session('f', 'forward', 0)
      -- "あいう" (3 chars, but 9 bytes in UTF-8)
      local text = 'あいう'
      s.cur_col = 0
      local extracted = s:get_keys(text)

      assert.are.equal('あいう', extracted)
      -- 'あ' (idx 1) は byte 0, 'い' (idx 4) は byte 3...
      assert.are.equal(1, s.keys.detail[1].byteidx)
      assert.are.equal(4, s.keys.detail[2].byteidx)
      assert.are.equal(7, s.keys.detail[3].byteidx)
    end)

    it('should handle search correctly in mixed ASCII and Multi-byte strings', function()
      local s = fret._session('new', 'f', 'forward', 0)
      local mixed = 'aあb'
      local extracted = s:get_keys(mixed)

      assert.are.equal('aあb', extracted)
      assert.are.equal('b', s.keys.detail[3].chr)
    end)
  end)

  describe('Dot-repeat()', function()
    it('repeats delete operation with dot', function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'abc def abc def' })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      local keys = vim.api.nvim_replace_termcodes('dfd', true, false, true)
      vim.api.nvim_feedkeys(keys, 'x', false)

      local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
      assert.are.equal('ef abc def', line)

      local dot = vim.api.nvim_replace_termcodes('.', true, false, true)
      vim.api.nvim_feedkeys(dot, 'x', false)

      line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
      assert.are.equal('ef', line)
    end)
  end)

  describe('Multi-byte support', function()
    it('moves cursor correctly to CJK characters', function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'あいうえお' })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      vim.schedule(function()
        fret.playing('f', 'forward', 0)
      end)

      vim.defer_fn(function()
        vim.api.nvim_input('u')
      end, 10)

      local success = vim.wait(1000, function()
        return vim.api.nvim_win_get_cursor(0)[2] == 6
      end, 50)

      local cursor = vim.api.nvim_win_get_cursor(0)

      assert.is_true(success, 'Timeout: Cursor stayed at ' .. cursor[2] .. '. Expected 6.')
      assert.are.equal(6, cursor[2])
    end)
  end)
end)
