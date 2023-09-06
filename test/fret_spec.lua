--This file can be run with "PlenaryTestFile %"
--[[ test string

👍abc ABC	1234あいうえお　カキクケコｻｼｽｾｿ'"(|\)
ad abc abcd bcd cda da
forward      |👍abc abc	1234cあいうえア　カキクケコｻｼｽｾｿ そ'"(|\)
forward till |👍abc abc	1234cあいうえア　カキクケコｻｼｽｾｿ そ'"(|\)
forward kana |👍abc abc	1234cあいうえア　カキクケコｻｼｽｾｿ そ'"(|\)
👍abc abc	1234cあいうえア　カキクケコｻｼｽｾｿ そ'"(\) | backward
👍abc abc	1234cあいうえア　カキクケコｻｼｽｾｿ そ'"(\) | backward till
👍abc abc	1234cあいうえア　カキクケコｻｼｽｾｿ そ'"(\) | backward kana

[ related-mode input "A" ]
forward |abc Abc あいうえお アイウエオ ｱｲｳｴｵ
        |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
till    |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
abc ABC あいうえお アイウエオ ｱｲｳｴｵ| backward
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa|
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa| till

[ dot-repert ]
<delete this range>$ input dt$
abcd|<this range is removed by .(dot)>|$
--]]

_G.fret_debug = true
local wd = vim.fn.expand('%:p:h:h')
local loaded, kana, timeout

if package.loaded['fret'] then
  loaded = true
  kana = vim.g.fret_enable_kana
  timeout = vim.g.fret_timeout
  package.loaded['fret'] = nil
end

vim.opt.runtimepath:append(wd)
local fret = require('fret')
vim.g.fret_enable_kana = false
vim.g.fret_timeout = 0
local pos = vim.api.nvim_win_get_cursor(0)

fret._clear_namespace()

describe('_indices()', function()
  local _indices = function(key, direction, till)
    return fret._debug(key, direction, till, function(d)
      return d.indices
    end)
  end
  local _get_levels = function()
    local l = ''
    local keys = fret._read_data().keys
    for _, v in ipairs(keys) do
      l = l .. v.level
    end
    return l
  end
  it('forward chars', function()
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    local chars = _indices('f', 'forward', 0)
    assert.is_same([[abc ABC	1234'"(|\)]], chars)
    assert.is_same('0011112220111100000000000000000111111', _get_levels())
  end)
  it('backward chars', function()
    vim.api.nvim_command('normal g_')
    local chars = _indices('F', 'backward', 1)
    assert.is_same([[\|("'4321	CBA cba]], chars)
    assert.is_same('011110000000000000000011110111122200', _get_levels())
  end)
  it('forward chars + kana', function()
    vim.g.fret_enable_kana = true
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    local chars = _indices('t', 'forward', 1)
    assert.is_same([[abc ABC	1234あいうえおカキクケコｻｼｽｾｿ'"(|\)]], chars)
    assert.is_same('0011112220111103111101233312333111111', _get_levels())
  end)
  it('backward chars + kana', function()
    vim.api.nvim_command('normal g_')
    local chars = _indices('T', 'backward', 1)
    assert.is_same([[\|("'ｿｾｽｼｻコケクキカおえういあ4321	CBA cba]], chars)
    assert.is_same('011111233312333011111011110112122300', _get_levels())
  end)
  it('blank', function()
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    assert.is_same('', _indices('f', 'forward', 0))
    assert.is_same('', _indices('F', 'backward', 0))
  end)
  vim.g.fret_enable_kana = false
end)

describe('_match_keys()', function()
  local _match_keys = function(key, direction, till)
    return fret._debug(key, direction, till, function(d)
      local t = vim.split(('0'):rep(#d.indices), '', { plain = true })
      for _, v in pairs(d.match_chars) do
        t[v] = 1
      end
      return table.concat(t, '')
    end)
  end
  before_each(function()
    vim.api.nvim_win_set_cursor(0, { 5, 0 })
  end)
  it('f', function()
    assert.is_same('0111110000000000000000', _match_keys('f', 'forward', 0))
  end)
  it('t', function()
    assert.is_same('0011110000100000000000', _match_keys('t', 'forward', 1))
  end)
  it('F', function()
    vim.api.nvim_command('normal g_')
    assert.is_same('111010001000000000000', _match_keys('F', 'backward', 0))
  end)
  it('T', function()
    vim.api.nvim_command('normal g_')
    assert.is_same('011110001000000000000', _match_keys('T', 'backward', 1))
  end)
end)

describe('highlight match keys', function()
  local _set_highlights = function(key, direction, till)
    return fret._debug(key, direction, till, function(d)
      d:attach_highlight('n')
    end)
  end
  vim.g.fret_enable_kana = false
  it('forward', function()
    vim.api.nvim_win_set_cursor(0, { 6, 14 })
    _set_highlights('f', 'forward', 0)
    fret._clear_data()
  end)
  it('forward till', function()
    vim.api.nvim_win_set_cursor(0, { 7, 14 })
    _set_highlights('t', 'forward', 1)
    fret._clear_data()
  end)
  it('forward kana', function()
    vim.g.fret_enable_kana = true
    vim.api.nvim_win_set_cursor(0, { 8, 14 })
    _set_highlights('f', 'forward', 0)
    fret._clear_data()
  end)
  it('backward', function()
    vim.g.fret_enable_kana = false
    vim.api.nvim_win_set_cursor(0, { 9, 80 })
    _set_highlights('F', 'backward', 0)
    fret._clear_data()
  end)
  it('backward till', function()
    vim.api.nvim_win_set_cursor(0, { 10, 80 })
    _set_highlights('T', 'backward', 1)
    fret._clear_data()
  end)
  it('backward till kana', function()
    vim.g.fret_enable_kana = true
    vim.api.nvim_win_set_cursor(0, { 11, 80 })
    _set_highlights('T', 'backward', 1)
    fret._clear_data()
  end)
end)

describe('related-mode', function()
  local _get_markers = function(char)
    local altkeys = vim.deepcopy(fret.altkeys)
    fret.altkeys = { lshift = 'JKLUIOPNMHY', rshift = 'FDSAREWQVCXZGTB' }
    local t = fret._get_markers(char)
    fret.altkeys = altkeys
    return t
  end
  vim.g.fret_enable_kana = true
  it('check alt-markers', function()
    assert.is_same('FDSAREWQVCXZGTB', _get_markers('F'))
    assert.is_same('DFSAREWQVCXZGTB', _get_markers('D'))
    assert.is_same('BFDSAREWQVCXZGT', _get_markers('B'))
    assert.is_same('JKLUIOPNMHY', _get_markers('J'))
    assert.is_same('KJLUIOPNMHY', _get_markers('K'))
    assert.is_same('YJKLUIOPNMH', _get_markers('Y'))
  end)
  local _related = function(input, key, direction, till)
    fret._debug(key, direction, till, function(d)
      d['input'] = input
      d.match_chars = {}
      fret._attach_extmark(input, input:lower(), d.cursor[1])
    end)
  end
  it('set extmarks', function()
    vim.api.nvim_win_set_cursor(0, { 14, 8 })
    _related('A', 'f', 'forward', 0)
    vim.api.nvim_win_set_cursor(0, { 15, 8 })
    _related('A', 'f', 'forward', 0)
    vim.api.nvim_win_set_cursor(0, { 16, 8 })
    _related('A', 't', 'forward', 1)
    vim.api.nvim_win_set_cursor(0, { 17, 55 })
    _related('A', 'F', 'backward', 0)
    vim.api.nvim_win_set_cursor(0, { 18, 35 })
    _related('A', 'F', 'backward', 0)
    vim.api.nvim_win_set_cursor(0, { 19, 35 })
    _related('A', 'T', 'backward', 1)
  end)
end)

describe('dot repeat', function()
  it('delete range and dot-repeat', function()
    vim.api.nvim_win_set_cursor(0, { 22, 0 })
    vim.api.nvim_command('normal! dt$')
    vim.api.nvim_win_set_cursor(0, { 23, 4 })
    vim.api.nvim_command('normal! .')
    assert.is_same('abcd$', vim.api.nvim_buf_get_lines(0, 22, 23, false)[1])
    vim.api.nvim_command('silent normal! u')
  end)
end)

vim.api.nvim_win_set_cursor(0, pos)
_G.fret_debug = nil
package.loaded['fret'] = nil

if loaded then
  vim.g.fret_enable_kana = kana
  vim.g.fret_timeout = timeout
else
  vim.g.fret_enable_kana = nil
  vim.g.fret_timeout = nil
end
