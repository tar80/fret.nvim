local M = {}

local helper = require('fret.helper')
local compat = require('fret.compat')

---@private
local DEFAULT_OPTIONS = {
  relative = 'win',
  height = 1,
  focusable = false,
  noautocmd = true,
  border = false,
  style = 'minimal',
}

---@param hl string Hlgroup
---@param interval integer repeat interval
---@param blend integer Initial value of winblend
---@param decay integer winblend becay
function M.new(hl, interval, blend, decay)
  return setmetatable({
    timer = assert(vim.uv.new_timer()),
    is_running = false,
    hl = hl,
    interval = interval,
    blend = blend,
    decay = decay,
  }, { __index = M })
end

-- Flash around the cursor
---@param winid integer
function M:around_cursor(winid)
  local win_region = function()
    local text = vim.api.nvim_get_current_line()
    local cur_col = vim.api.nvim_win_get_cursor(winid)[2]
    local charidx = compat.str_utfindex(text, helper.utf_encoding(), cur_col, false)
    local charwidth = helper.charwidth(text, charidx)
    local next_charwidth = helper.charwidth(text, charidx + 1)
    local winwidth = next_charwidth == 0 and charwidth * 3 or charwidth * 2 + next_charwidth
    local row = vim.fn.winline() - 1
    local col = vim.fn.wincol() - 1 - charwidth
    local relative = 'win'
    return { height = 1, width = math.max(1, winwidth), row = row, col = col, relative = relative }
  end
  self:flash(win_region)
end

-- Flash around the cursor position
---@param win_region fun():{height:integer,width:integer,row:integer,col:integer,relative?:string}
function M:flash(win_region)
  local region = win_region()
  if not self.is_running then
    self.is_running = true
    vim.schedule(function()
      local opts = vim.tbl_extend('force', DEFAULT_OPTIONS, region)
      local bufnr = vim.api.nvim_create_buf(false, true)
      self.winid = vim.api.nvim_open_win(bufnr, false, opts)
      vim.api.nvim_set_option_value(
        'winhighlight',
        ('Normal:%s,EndOfBuffer:%s'):format(self.hl, self.hl),
        { win = self.winid }
      )
      vim.api.nvim_set_option_value('winblend', self.blend, { win = self.winid })
      self.timer:start(
        0,
        self.interval,
        vim.schedule_wrap(function()
          if not vim.api.nvim_win_is_valid(self.winid) then
            return
          end
          local blending = vim.api.nvim_get_option_value('winblend', { win = self.winid }) + self.decay
          if blending > 100 then
            blending = 100
          end
          vim.api.nvim_set_option_value('winblend', blending, { win = self.winid })
          if vim.api.nvim_get_option_value('winblend', { win = self.winid }) == 100 and self.timer:is_active() then
            self.timer:stop()
            self.is_running = false
            vim.api.nvim_win_close(self.winid, true)
          end
        end)
      )
    end)
  else
    vim.api.nvim_win_set_config(self.winid, region)
    vim.api.nvim_set_option_value('winblend', self.blend, { win = self.winid })
  end
end

return M
