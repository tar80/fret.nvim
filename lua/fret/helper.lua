---@meta helper
---@class helper
local M = {}

---@alias LogLevels 'TRACE'|'DEBUG'|'INFO'|'WARN'|'ERROR'|'OFF'
---@alias UtfEncoding 'utf-8'|'utf-16'|'utf-32'

---@param name string
---@param message string
---@param errorlevel LogLevels
function M.notify(name, message, errorlevel)
  vim.notify(message, vim.log.levels[string.upper(errorlevel)], { title = name })
end

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
  encoding = string.lower(encoding or vim.bo.fileencoding)
  if encoding == '' then
    encoding = vim.go.encoding
  end
  local has_match = ('utf-16,utf-32'):find(encoding, 1, true) ~= nil
  return has_match and encoding or 'utf-8'
end

-- Check the number of characters on the display
---@param string string
---@param column integer
---@return integer charwidth
function M.charwidth(string, column)
  return vim.api.nvim_strwidth(vim.fn.strcharpart(string, column, 1, 1))
end

-- Operator-pending or not
---@param mode? string
function M.is_operator(mode)
  if not mode then
    mode = vim.api.nvim_get_mode().mode
  end
  return mode:find('^no')
end

-- Set default highlights
---@param highlights table<string,vim.api.keyset.highlight>
function M.set_hl(highlights)
  vim.iter(highlights):each(function(name, value)
    local hl = type(value) == 'function' and value() or value
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
