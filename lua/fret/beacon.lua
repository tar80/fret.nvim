local M = {}

---@private
local cache = {
  winid = 0,
  is_running = false,
}

---@private
local _float_options = {
  relative = 'win',
  height = 1,
  focusable = false,
  noautocmd = true,
  border = false,
  style = 'minimal',
}

---@private
local timer = assert(vim.uv.new_timer())

-- Get floating window rectangle
---@param winid integer
---@return integer winwidth, integer row, integer col
local function _get_win_rect(winid)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(winid)[2]
  local charidx = vim.str_utfindex(line, col)
  local charwidth = math.min(2, #vim.fn.strcharpart(line, charidx, 1, true))
  local next_charwidth = math.min(2, #vim.fn.strcharpart(line, charidx + 1, 1, true))
  local winwidth = next_charwidth == 0 and charwidth * 3 or charwidth * 2 + next_charwidth
  local winline = vim.fn.winline() - 1
  local wincol = vim.fn.wincol() - 1
  return math.max(1, winwidth), winline, wincol - charwidth
end

-- Flash around the cursor position
---@param cur_winid integer
---@param hl string Hlgroup
---@param interval integer repeat interval
---@param blend integer Initial value of winblend
---@param decay integer winblend becay
function M.flash_cursor(cur_winid, hl, interval, blend, decay)
  if not cache.is_running then
    cache.is_running = true
    vim.schedule(function()
      local width, row, col = _get_win_rect(cur_winid)
      local opts = vim.tbl_extend('force', _float_options, { width = width, row = row, col = col })
      local bufnr = vim.api.nvim_create_buf(false, true)
      cache.winid = vim.api.nvim_open_win(bufnr, false, opts)
      vim.api.nvim_set_option_value('winhighlight', ('Normal:%s'):format(hl), { win = cache.winid })
      vim.api.nvim_set_option_value('winblend', blend, { win = cache.winid })
      timer:start(
        0,
        interval,
        vim.schedule_wrap(function()
          if not vim.api.nvim_win_is_valid(cache.winid) then
            return
          end
          local blending = vim.api.nvim_get_option_value('winblend', { win = cache.winid }) + decay
          if blending > 100 then
            blending = 100
          end
          vim.api.nvim_set_option_value('winblend', blending, { win = cache.winid })
          if vim.api.nvim_get_option_value('winblend', { win = cache.winid }) == 100 and timer:is_active() then
            timer:stop()
            cache.is_running = false
            vim.api.nvim_win_close(cache.winid, true)
          end
        end)
      )
    end)
  else
    local width, row, col = _get_win_rect(cur_winid)
    vim.api.nvim_win_set_config(cache.winid, { relative = 'win', width = width, row = row, col = col })
    vim.api.nvim_set_option_value('winblend', blend, { win = cache.winid })
  end
end

return M
