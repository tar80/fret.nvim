local tbl = require('fret.tbl')
local api = vim.api
local fn = vim.fn

local timer
local Fret = {}
local Score = {}
local session, keys, stored = {}, {}, {}
local hlgroup = vim.g._fret_highlights
Fret.altkeys = { lshift = 'JKLUIOPNMHY', rshift = 'FDSAREWQVCXZGTB' }

local ns = api.nvim_create_namespace('fret-nvim')

local function timer_stop()
  if not timer then
    return
  end

  timer:stop()
  timer:close()
  timer = nil
end

local function timer_start()
  if session.timer == 0 then
    return
  end

  timer = vim.loop.new_timer()

  timer:start(
    vim.g.fret_timeout,
    0,
    vim.schedule_wrap(function()
      timer_stop()
      return api.nvim_input('<Esc>')
    end)
  )
end

local function is_operator(mode)
  return mode:find('^no')
end

local function column_limited()
  local line = api.nvim_get_current_line()
  local col = api.nvim_win_get_width(0) - 1

  if not vim.wo.wrap and #line > col then
    local f = tonumber(vim.wo.foldcolumn)
    local s = vim.wo.signcolumn == 'yes' and 2 or 0
    local n = (vim.wo.number or vim.wo.relativenumber) and tonumber(vim.wo.numberwidth) or 0

    line = line:sub(1, col - f - s - n)
  end

  return line
end

Score.new = function(key, direction, till)
  local self = setmetatable({}, { __index = Score })
  self['key'] = key
  self['reverse'] = direction == 'backward'
  self['till'] = not self.reverse and -till or till
  self['truncate'] = not self.reverse and (2 + till) or (1 + till)
  self['kana'] = vim.g.fret_enable_kana
  self['timer'] = vim.g.fret_timeout
  self['vcount'] = vim.v.count1
  self['cursor'] = api.nvim_win_get_cursor(0)
  self['line'] = column_limited()
  self['indices'] = ''
  self['has_multibyte'] = false
  self['front_count'] = 0
  self['front_byteidx'] = 0
  self['match_chars'] = {}

  return self
end

local function control_hlsearch()
  local state = vim.o.hlsearch

  if state then
    vim.api.nvim_command('nohlsearch')
  end

  return function()
    if state then
      vim.api.nvim_command('set hlsearch')
    end
  end
end

local function define_highlight(char, level, mode)
  local hl = { [0] = hlgroup['0'], [1] = hlgroup['1'], [2] = hlgroup['2'] }

  ---when executing operator-command, or number/symbol is highlight only for the first candidate
  if level > 1 then
    level = is_operator(mode) and 0 or level
    level = char:match('[%d%p]') and 0 or level
  end

  return hl[level]
end

---NOTE: nvim_buf_add_highlight() has a problem, and the bold display shifts the character width
--- but mathaddpos() is not suitable because there are 8 upper limit
Score.attach_highlight = function(self, mode)
  local row = self.cursor[1]

  for _, v in ipairs(keys) do
    api.nvim_buf_add_highlight(
      0,
      ns,
      define_highlight(v.char, v.level, mode),
      row - 1,
      self.front_byteidx + v.byteidx - v.bytes,
      self.front_byteidx + v.byteidx
    )
  end

  api.nvim_command('redraw')
end

local function convert_valid_key(char, list)
  for k, v in pairs(tbl[list]) do
    if v:find(char, 1, true) then
      return k
    end
  end
end

Score.matcher = function(self, actual)
  local match, kanamoji, char, altchar, charwidth
  local patterns = { gen = '[%w%p%s]', kana = '[^%g%s]' }

  if actual:match('%C') then
    match = actual:match(patterns['gen'])

    if match then
      char = actual:lower()
    elseif self.has_multibyte and self.kana then
      kanamoji = actual:match(patterns['kana'])
      match = kanamoji

      if match then
        ---NOTE: <%s> is for debug
        char = convert_valid_key(actual, 'kana') or string.format('<%s>', actual)
        charwidth = not tbl.hankanalist:find(actual, 1, true) and 'double'
        altchar = tbl.altchar[char]
      end
    end
  end

  return match, char, actual, altchar, charwidth
end

Score.sort = function(self, chars)
  local t = {}

  if not self.has_multibyte then
    local chars_t = vim.split(chars, '', { plain = true })

    for i, v in ipairs(chars_t) do
      table.insert(t, (not self.reverse and #t + 1 or 1), { v, i, 1 })
    end
  else
    local c, idx, byteidx, bytes
    local i, j = 1, 0
    local chars_len = #chars

    ---@see https://zenn.dev/vim_jp/articles/get-charpos-in-neovim
    while i <= chars_len do
      idx = vim.str_utfindex(chars, i)

      if idx ~= j then
        j = idx
        c = fn.strcharpart(chars, idx - 1, 1)
        byteidx = vim.str_byteindex(chars, idx)
        bytes = #c

        ---NOTE: Replace non-target multibyte characters with control characters
        ---  Does not have to be "^A"
        if bytes ~= 1 then
          if not (self.kana and tbl.kanalist:find(c, 1, true)) then
            c = ''
          end
        end

        table.insert(t, (not self.reverse and (#t + 1) or 1), { c, byteidx, bytes })
      end

      i = i + 1
    end
  end

  return t
end

Score.newkey = function(self, idx, vcount, chars)
  local level = 0
  local char, byteidx, bytes = unpack(chars[idx])
  local match, actual, altchar, charwidth

  if idx >= self.truncate then
    match, char, actual, altchar, charwidth = self:matcher(char)

    if match and (vcount < 1) then
      level = 1

      for i = 1, #keys do
        if keys[i].char == char then
          level = keys[i].level + 1

          if level > 1 then
            break
          end
        end
      end
    end
  end

  if level == 1 then
    self.match_chars[char] = idx

    ---add a key with a list containing the same vowel to the target
    if altchar and not self.match_chars[altchar] then
      self.match_chars[altchar] = idx
    end
  end

  table.insert(keys, {
    char = char,
    actual = actual,
    altchar = altchar,
    level = level,
    charwidth = charwidth,
    byteidx = byteidx,
    bytes = bytes,
  })
end

---NOTE: Do not include characters adjacent to the cursor position for highlighting when using t/T key
local adjust_vcount = function(self)
  local int = 0

  if self.till ~= 0 then
    int = not self.reverse and 2 or 1
  end

  return function(i, n)
    return n and (n - 1) or (self.vcount - (i == int and 0 or 1))
  end
end

Score.setkeys = function(self, indices)
  local t = self:sort(indices)
  local c, s = '', ''
  local n = 0
  local ignore = {}
  local vcount = adjust_vcount(self)

  for i = 1, #t do
    c = t[i][1]
    s = string.format('%s%s', s, c)
    n = ignore[c]

    if n ~= 0 then
      ignore[c] = vcount(i, n)
    end

    self:newkey(i, ignore[c], t)
  end

  self.indices = s
end

Score.get_indices = function(self, col)
  local range = not self.reverse and { col + 1 } or { 1, col }
  local chars = self.line:sub(unpack(range)) or ''

  if chars ~= '' then
    self.has_multibyte = #chars ~= api.nvim_strwidth(chars)
    self.front_count = not self.reverse and vim.str_utfindex(self.line, col) or 0
    self.front_byteidx = not self.reverse and vim.str_byteindex(self.line, self.front_count) or 0
  end

  return chars
end

Score.repeatable = function(self, count)
  local till = ''

  if self.till ~= 0 then
    till = not self.reverse and 'l' or 'h'
  end

  api.nvim_command(string.format('normal! %s%s%s%s', till, self.vcount, self.key, keys[count].actual))
end

Score.operable = function(self, count, mode)
  if not self.reverse then
    count = self.front_count + count
    mode = is_operator(mode) and 'v' or ''
  else
    ---NOTE: Keep in mind that for backward, the text will play in reverse order
    count = #keys - count + 1
    mode = is_operator(mode) and 'hv' or ''
  end

  ---NOTE: nvim_strwidth() not support tabstop. And I didn't find nvim_api corresponding to strcharpart()
  local width = fn.strdisplaywidth(fn.strcharpart(self.line, 0, count + self.till))

  api.nvim_command(string.format('normal! %s%s|', mode, width))
end

Score.finish = function(self, mode, proc)
  timer_stop()

  if proc == 'related' then
    return
  end

  if is_operator(mode) then
    if proc == 'abort' then
      api.nvim_input('<Cmd>normal! u<CR>')
    else
      self.kana = false
      self.timer = 0
      self.cursor = {}
      self.line = ''
      self.indices = ''
      self.match_chars = {}
      stored = vim.deepcopy(session)
    end
  end

  keys = {}
  session = {}
end

local function map_marker(char)
  local markers = Fret.altkeys.lshift:find(char, 1, true) and Fret.altkeys.lshift or Fret.altkeys.rshift
  local num = markers:find(char, 1, true)
  local t = vim.split(markers, '', { plain = true })

  if num then
    table.remove(t, num)
  end

  table.insert(t, 1, char)

  return t
end

local function marker_string(charwidth, marker)
  return charwidth == 'double' and string.format('%s ', marker) or marker
end

local function attach_extmark(input, lower, row)
  local byteidx, id = 0, 1
  local markers = map_marker(input)
  local marker
  local target = function(w, a)
    return string.format('%s%s', w, a or ''):find(lower, 1, true)
  end

  for i = session.truncate, #keys do
    if keys[i].level == 2 and target(keys[i].char, keys[i].altchar) then
      marker = marker_string(keys[i].charwidth, markers[id])
      byteidx = session.front_byteidx + keys[i].byteidx
      session.match_chars[markers[id]] = i

      api.nvim_buf_set_extmark(0, ns, row - 1, byteidx - keys[i].bytes, {
        id = not _G.fret_debug and id or nil,
        end_row = row - 1,
        end_col = byteidx,
        virt_text = { { marker, hlgroup['3'] } },
        virt_text_pos = 'overlay',
      })

      id = id + 1

      if not markers[id] then
        break
      end
    end
  end
end

Score.related = function(self, input, lower, mode)
  local row, _ = unpack(self.cursor)
  session.match_chars = {}

  api.nvim_buf_add_highlight(0, ns, hlgroup['0'], row - 1, self.front_byteidx, -1)
  attach_extmark(input, lower, row)

  if vim.tbl_isempty(self.match_chars) then
    api.nvim_buf_clear_namespace(0, ns, row - 1, row)

    return ''
  end

  if vim.tbl_count(self.match_chars) == 1 then
    api.nvim_buf_clear_namespace(0, ns, row - 1, row)
    self:operable(self.match_chars[input], mode)

    return ''
  end

  api.nvim_command('redraw')
  api.nvim_input(self.key)

  return 'related'
end

Score.gain = function(self, input, mode)
  local count = self.match_chars[input]

  ---items whose move to that position with a type
  if input:match('[^%u]') and count then
    if not is_operator(mode) then
      self:repeatable(count)
    else
      self:operable(count, mode)
    end

  ---items that require 2 or more types
  elseif not is_operator(mode) and input:match('%u') then
    local lower = input:lower()

    if not count or self.indices:find(lower, count + 1, true) then
      return self:related(input, lower, mode)
    end
  else
    return 'abort'
  end
end

Score.key_in = function(row)
  timer_start()

  local input = fn.nr2char(fn.getchar())

  api.nvim_buf_clear_namespace(0, ns, row - 1, row)

  if input:match('%C') then
    return input
  end
end

local function playing(key, direction, till, mode)
  session = Score.new(key, direction, till)
  local row, col = unpack(session.cursor)
  local indices = session:get_indices(col)

  session:setkeys(indices)

  if vim.str_utfindex(session.indices, #session.indices) < session.truncate then
    return
  end

  session:attach_highlight(mode)

  local input = Score.key_in(row)
  local proc = 'abort'

  if input then
    session['input'] = input
    proc = session:gain(input, mode)
  end

  Score:finish(mode, proc)
end

local function performing(mode)
  local row, _ = unpack(session.cursor)
  local input = Score.key_in(row)

  if input then
    local count = session.match_chars[input]

    if count then
      session:operable(count, mode)
    elseif input:match('[^%u]') then
      api.nvim_input(input:match('[aiAI]') and '<Esc>' or input)
    end
  end

  Score:finish(mode)
end

local function dotrepeat(mode)
  session = stored
  session['cursor'] = api.nvim_win_get_cursor(0)
  session['line'] = api.nvim_get_current_line()

  local _, col = unpack(session.cursor)
  local indices = session:get_indices(col)

  session:setkeys(indices)
  session:gain(session.input, mode)
  Score:finish(mode)
end

Fret.inst = function(key, direction, till)
  local mode = fn.mode(1)
  local ok, related = pcall(next, session.match_chars)
  local hlsearch = control_hlsearch()

  if ok and related then
    performing(mode)
  elseif session.mapped_trigger then
    playing(key, direction, till, mode)
  else
    dotrepeat(mode)
  end

  hlsearch()
end

Fret.keymap = function(mapkey, key, direction, till)
  vim.keymap.set({ 'n', 'x', 'o' }, mapkey, function()
    session.mapped_trigger = true

    return string.format('<Cmd>lua require("fret").inst("%s", "%s", %s)<CR>', key, direction, till)
  end, { expr = true, desc = string.format('fret-%s go %s search', key, direction) })
end

Fret.setup = function(opts)
  return require('fret.config').setup(opts)
end

if _G.fret_debug then
  Fret._debug = function(key, direction, till, callback)
    keys = {}
    session = Score.new(key, direction, till)
    local chars = session:get_indices(session.cursor[2])
    session:setkeys(chars)
    return callback(session)
  end

  Fret._clear_namespace = function()
    api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end

  Fret._clear_data = function()
    keys = {}
    session = {}
  end

  Fret._read_data = function()
    return { session = session, keys = keys }
  end

  Fret._get_markers = function(char)
    return table.concat(map_marker(char), '')
  end

  Fret._attach_extmark = function(input)
    attach_extmark(input, input:lower(), session.cursor[1])
  end
end

return Fret
