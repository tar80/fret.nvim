local ns = {}
setmetatable(ns, {
  __index = {
    namespace = vim.api.nvim_create_namespace('test'),
    clear = function(self)
      vim.api.nvim_buf_clear_namespace(0, self.namespace, 0, -1)
    end,
    add_highlight = function(self, row, open, close)
      row = tonumber(row)
      open = tonumber(open)
      close = tonumber(close)
      vim.api.nvim_buf_add_highlight(0, self.namespace, 'Error', row - 1, open, close)
    end,
  },
})

vim.api.nvim_create_user_command('TestClearNamespace', function()
  ns:clear()
end, {})
vim.api.nvim_create_user_command('TestAddHighlight', function(opts)
  ns:add_highlight(unpack(opts.fargs))
end, { nargs = '+' })
vim.api.nvim_create_user_command('TestCharInfo', function()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local charidx = vim.str_utfindex(line, col)
  local byteidx = vim.str_byteindex(line, charidx)
  local char = vim.fn.strcharpart(line, charidx, 1)
  local dispwidth = vim.api.nvim_strwidth(line:sub(1, col))
  print('char:', char, 'bytes:', #char, 'idx:', charidx + 1, 'byteidx(col):', byteidx + 1, 'dispwidth:', dispwidth)
end, {})
vim.api.nvim_create_user_command('TestSetCursor', function(opts)
  return vim.api.nvim_win_set_cursor(0, { tonumber(opts.fargs[1]), tonumber(opts.fargs[2]) })
end, { nargs = '+' })
vim.api.nvim_create_user_command('TestCharpart', function(opts)
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local chars = vim.fn.strcharpart(line, 0, opts.args)
  print(chars)
end, { nargs = 1 })
