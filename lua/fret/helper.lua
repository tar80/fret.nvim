---@class helper
local M = {}

---@alias LogLevels 'TRACE'|'DEBUG'|'INFO'|'WARN'|'ERROR'|'OFF'
---@alias UtfEncoding 'utf-8'|'utf-16'|'utf-32'

---@param name string
---@param subject string
---@param msg string|string[][]
function M.echo(name, subject, msg)
  if type(msg) == 'string' then
    msg = { { msg } }
  end
  vim.api.nvim_echo({ { string.format('[%s] %s: ', name, subject) }, unpack(msg) }, false, {})
end

-- Get the current utf encoding
---@param encoding? string
---@return string encoding
function M.utf_encoding(encoding)
  encoding = string.lower(encoding or '')
  if encoding == 'utf-8' or encoding == 'utf-16' then
    return encoding
  end
  return 'utf-32'
end

-- Check the number of characters on the display
---@param string string
---@param column integer
---@return integer charwidth
function M.charwidth(string, column)
  return vim.api.nvim_strwidth(vim.fn.strcharpart(string, column, 1, true))
end

-- Operator-pending or not
---@param mode? string
function M.is_operator(mode)
  if not mode then
    mode = vim.api.nvim_get_mode().mode
  end
  return mode:find('^no')
end

local function _value_converter(value)
  local tbl = {}
  local t = type(value)
  if t == 'function' then
    tbl = value()
    return type(tbl) == 'table' and tbl or {}
  elseif t == 'string' then
    return { value }
  elseif t == 'table' then
    for att, _value in pairs(value) do
      local att_t = type(_value)
      if att_t == 'function' then
        _value = _value()
        if _value then
          tbl[att] = _value
        end
      end
      tbl[att] = _value
    end
    return tbl
  end
  return tbl
end

-- Set default highlights
---@param hlgroups table<string,vim.api.keyset.highlight>
function M.set_hl(hlgroups)
  vim.iter(hlgroups):each(function(name, value)
    local hl = _value_converter(value)
    hl['default'] = true
    vim.api.nvim_set_hl(0, name, hl)
  end)
end

---@param name string|string[]
---@param opts vim.api.keyset.create_autocmd
---@param safestate? boolean
function M.autocmd(name, opts, safestate)
  local callback = opts.callback
  opts.pattern = opts.pattern or '*'
  if safestate then
    opts.callback = function()
      opts.once = true
      opts.callback = callback
      vim.api.nvim_create_autocmd('SafeState', opts)
    end
  end
  vim.api.nvim_create_autocmd(name, opts)
end

return M
