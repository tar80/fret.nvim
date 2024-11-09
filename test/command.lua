local ns = setmetatable({}, {
  __index = {
    namespace = vim.api.nvim_create_namespace('test'),
    floatwin_ids = {},
    clear = function(self)
      vim.api.nvim_buf_clear_namespace(0, self.namespace, 0, -1)
    end,
    add_highlight = function(self, row, open, close)
      row = tonumber(row)
      open = tonumber(open)
      close = tonumber(close)
      vim.api.nvim_buf_add_highlight(0, self.namespace, 'Error', row - 1, open - 0, close - 0)
    end,
    add_extmark = function(self, row, col)
      local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
      row = row and tonumber(row) or cur_row
      col = col and tonumber(col) or cur_col
      vim.api.nvim_buf_set_extmark(0, self.namespace, row - 1, col, {
        end_col = col + 2,
        virt_text = { { '1', 'Error' }, { '2', 'Search' } },
        virt_text_pos = 'overlay',
        hl_mode = 'combine',
      })
    end,
    open_floarwin = function(self, row, col)
      local opts = {
        relative = 'win',
        height = 1,
        width = 1,
        row = row,
        col = col,
        focusable = false,
        noautocmd = true,
        border = { '', '', '', '❰', '', '', '', '❱' },
        -- border = { "", "" ,"", "⡷", "", "", "", "⢾" },
        style = 'minimal',
      }
      local bufnr = vim.api.nvim_create_buf(false, true)
      local winid = vim.api.nvim_open_win(bufnr, false, opts)
      vim.api.nvim_win_set_hl_ns(winid, self.namespace)
      vim.wo[winid].winhl = 'Normal:Search'
      vim.api.nvim_set_option_value('winblend', 0, { win = winid })
      table.insert(self.floatwin_ids, bufnr)
    end,
    close_floatwin = function(self)
      if #self.floatwin_ids > 0 then
        for _, bufnr in ipairs(self.floatwin_ids) do
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      end
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
  print(line:sub(0, col))
end, { nargs = '?' })
vim.api.nvim_create_user_command('TestExtmark', function(opts)
  ns:add_extmark(opts.fargs[1], opts.fargs[2])
end, { nargs = '*' })
vim.api.nvim_create_user_command('TestFloatwin', function(opts)
  if opts.args == 'close' then
    ns:close_floatwin()
  else
    local row = opts.fargs[1] and tonumber(opts.fargs[1]) or vim.fn.winline() - 1
    local col = opts.fargs[1] and tonumber(opts.fargs[2]) or vim.fn.wincol() - 2
    ns:open_floarwin(row, col)
  end
end, { nargs = '*' })
ns:clear()
