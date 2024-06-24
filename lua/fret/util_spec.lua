local util = require('fret.util')
local stub = require('luassert.stub')

describe('.notify()', function()
  it('returns notification', function()
    local name = 'Name'
    local message = 'test message'
    local errorlevel = vim.diagnostic.severity.WARN
    local expect = string.format('[%s] %s', name, message)
    local s = stub(vim, 'notify')
    -- If options argument is not specified, an empty table is specified
    util.notify(name, message, errorlevel)
    assert.stub(s).was.called_with(expect, errorlevel, {})

    -- Basically, there is no need to specify anything in the options argument.
    -- If you use nvim-notify you can use the title field
    local options = { title = 'test' }
    util.notify(name, message, errorlevel, options)
    assert.stub(s).was.called_with(expect, errorlevel, options)
    s:revert()
  end)
end)

describe('.echo()', function()
  local s
  before_each(function()
    s = stub(vim.api, 'nvim_echo')
  end)

  local name = 'Name'
  local subject = 'subject'
  it('returns echo. "msg" can be a string', function()
    local msg = 'string messages'
    local expects = { { '[Name] subject: ' }, { msg } }
    util.echo(name, subject, msg)
    assert.stub(s).was.called_with(expects, false, {})
  end)

  it('returns echo. "msg" can be a table of string array', function()
    local msg = { { 'table' }, { 'of', 'Error' }, { 'messages', 'Warn' } }
    local expects = { { '[Name] subject: ' }, unpack(msg) }
    util.echo(name, subject, msg)
    assert.stub(s).was.called_with(expects, false, {})
  end)
end)

describe('.charwidth()', function()
  local s = '0あ😀'

  it('charcter width on screen. half width character must return "1"', function()
    assert.is.equal(1, util.charwidth(s, 0))
  end)
  it('charcter width on screen. full width character must return "2"', function()
    assert.is.equal(2, util.charwidth(s, 1))
  end)
  it('charcter width on screen. emoji must return "2"', function()
    assert.is.equal(2, util.charwidth(s, 2))
  end)
end)

describe('.tbl_insert()', function()
  local tbl
  before_each(function()
    tbl = { a = 1, b = 2, c = { 3 } }
  end)

  it('not specified "pos", the value must be inserted at the end', function()
    local key = 'c'
    local value = 4
    local expects = { a = 1, b = 2, c = { 3, 4 } }
    util.tbl_insert(tbl, key, value)
    assert.are.same(expects, tbl)
  end)

  it('specified "pos", the value must be inserted at the specified position', function()
    local key = 'c'
    local value = 4
    local expects = { a = 1, b = 2, c = { 4, 3 } }
    util.tbl_insert(tbl, key, 1, value)
    assert.are.same(expects, tbl)
  end)

  it('does not exist "key" in the specified table, "key" must be added', function()
    local key = 'd'
    local value = 4
    local expects = { a = 1, b = 2, c = { 3 }, d = { 4 } }
    util.tbl_insert(tbl, key, value)
    assert.are.same(expects, tbl)
  end)
end)

describe('.autocmd()', function()
  it('"safestate" is specifeid. SafeState event must be executed once by the callback', function()
    local name = 'User'
    local safestate = true
    local group = 'fret_test'
    local callback = function()
      vim.print('test')
    end
    local opts = { desc = 'decription', pattern = '*', group = group, callback = callback }
    local expects = vim.tbl_deep_extend('force', opts, { once = true, callback = callback })
    local id = vim.api.nvim_create_augroup(group, {})
    util.autocmd(name, opts, safestate)
    local s = stub(vim.api, 'nvim_create_autocmd')
    vim.api.nvim_exec_autocmds(name, { group = group })
    assert.stub(s).was.called_with('SafeState', expects)
    vim.api.nvim_del_autocmd(id)
  end)
end)

describe('.set_timer()', function()
  local timer = util.set_timer()
  local s
  before_each(function()
    s = stub(vim, 'schedule')
  end)

  it('not called if a negative number is specified for the "debounce" method', function()
    timer.debounce(-1, function() end)
    vim.wait(100)
    assert.stub(s).was.called(0)
  end)

  it('"debounce" method must be reset if it is called again before the "timeout"', function()
    timer.debounce(50, function() end)
    assert.stub(s).was.called(0)
    vim.wait(20)
    timer.debounce(50, function() end)
    vim.wait(20)
    timer.debounce(50, function() end)
    vim.wait(20)
    assert.stub(s).was.called(0)
    vim.wait(30)
    assert.stub(s).was.called(1)
  end)

  it('"stop" method stops the timer', function()
    timer.debounce(50, function() end)
    timer:stop()
    assert.is.equal(timer:_closing(), false)
    vim.wait(100)
    assert.stub(s).was.called(0)
  end)

  it('"close" method stops the timer', function()
    timer.debounce(50, function() end)
    assert.is.equal(timer:_closing(), false)
    timer:close()
    assert.is.equal(timer:_closing(), true)
    vim.wait(100)
    assert.stub(s).was.called(0)
  end)
end)

describe('.indicator()', function()
  local ns = vim.api.nvim_create_namespace('fret_test')

  it('should display an indicator', function()
    local text = 'test'
    local timeout = 200
    local row = 0
    local col = 0

    local winid = util.indicator(ns, text, timeout, row, col)
    local ns_id = vim.api.nvim_get_hl_ns({ winid = winid })
    assert.is.equal(ns, ns_id)

    local bufnr = vim.api.nvim_win_get_buf(winid)
    local content = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
    assert.equal(text, content[1])

    assert.is.True(vim.api.nvim_win_is_valid(winid))
    vim.api.nvim_win_close(winid, true)
  end)
end)

describe('.ext_sign()', function()
  local _opts = { sign_hl_group = 'Normal' }

  it('should call nvim_buf_set_extmark with default opts', function()
    local s = stub(vim.api, 'nvim_buf_set_extmark')
    local winid = 0
    local row, col = 1, 1
    local opts = {}
    local expects = vim.tbl_extend('force', _opts, opts)
    util.ext_sign(winid, row, col, opts)
    assert.stub(s).was.called_with(0, winid, row, col, expects)
  end)

  it('should call nvim_buf_set_extmark with specified opts', function()
    local s = stub(vim.api, 'nvim_buf_set_extmark')
    local winid = 0
    local row, col = 1, 1
    local opts = { sign_text = '@' }
    local expects = vim.tbl_extend('force', _opts, opts)
    util.ext_sign(winid, row, col, opts)
    assert.stub(s).was.called_with(0, winid, row, col, expects)
  end)
end)
