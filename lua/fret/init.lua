---@module 'util'
local util = package.loaded['matchwith.util'] or require('fret.util')
local tbl = require('fret.tbl')
local api = vim.api
local fn = vim.fn

local UNIQ_ID = 'fret-nvim'
local L_SHIFT = 'JKLUIOPNMHY'
local R_SHIFT = 'FDSAREWQVCXZGTB'

local ns = api.nvim_create_namespace(UNIQ_ID)
local timer = util.set_timer()
local hlgroup = _G._fret_highlights
_G._fret_highlights = nil

---@class Fret
local Fret = {}
Fret.altkeys = { lshift = L_SHIFT, rshift = R_SHIFT }
Fret.mapped_trigger = false

---@class Session
local _session = {}

-- Clean up the keys database
local function _newkeys()
  return { level = {}, ignore = {}, detail = {}, mark_pos = {}, first_idx = {}, second_idx = {} }
end

---@type Session
local Session = { keys = _newkeys() }

-- Start new session
function _session.new(mapkey, direction, till)
  local self = {
    ns = ns,
    timer = timer,
    hlgroup = hlgroup,
    bufnr = api.nvim_get_current_buf(),
    winid = api.nvim_get_current_win(),
    hlmode = vim.g.fret_hlmode,
    notify = vim.g.fret_repeat_notify,
    enable_kana = vim.g.fret_enable_kana,
    enable_symbol = vim.g.fret_enable_symbol,
    timeout = vim.g.fret_timeout,
    vcount = vim.v.count1,
    mapkey = mapkey,
    reversive = direction == 'forward',
    operative = util.is_operator(),
    till = till,
    front_byteidx = 0,
    keys = _newkeys(),
  }
  local pos = api.nvim_win_get_cursor(self.winid)
  self['cur_row'] = pos[1]
  self['cur_col'] = pos[2]
  return setmetatable(self, { __index = _session })
end

-- Abort operation
---@operative boolean
local function _abort(operative)
  if operative then
    api.nvim_input('<Cmd>normal! u<CR>')
  end
end

-- Get and update line information
function _session.set_line_informations(self)
  local line = api.nvim_get_current_line()
  if line == '' then
    return
  end
  local winsaveview = fn.winsaveview()
  local info_width = fn.screenpos(self.winid, self.cur_row, 1).col - 1
  local win_width = api.nvim_win_get_width(self.winid)
  local leftcol = winsaveview.leftcol
  if leftcol > 0 then
    line = line:sub(leftcol + 1, win_width + leftcol - info_width)
    -- NOTE: whether listchars should be supported
    -- if api.nvim_get_option_value('list', {}) then
    --   local extends, precedes = util.expand_wrap_symbols()
    -- end
  end
  ---@type string|nil
  local indices
  -- NOTE: consider that cur_col is zero-based
  if self.reversive then
    indices = line:sub(1, self.cur_col - leftcol)
  else
    self['front_byteidx'] = vim.str_byteindex(line, vim.str_utfindex(line, self.cur_col + 1))
    indices = line:sub(self.front_byteidx - leftcol + 1)
  end
  self['leftcol'] = leftcol
  self['info_width'] = info_width
  return indices
end

-- Convert a character to a valid key
---@param char string
---@param name string Table name in string array
---@return string?
local function _valid_key(char, name)
  for k, v in pairs(tbl[name]) do
    if v:find(char, 1, true) then
      return k
    end
  end
end

-- Extract matched characters
---@param actual string
---@param enable_kana boolean
---@return string?,string,string?,string?,boolean?
local function _matcher(actual, enable_kana)
  local match, char, altchar, double
  if actual:match('%C') then
    match = actual:match('[%w%p%s]')
    if match then
      char = actual:lower()
    elseif enable_kana then
      match = actual:match('[^%g%s]')
      if match then
        char = _valid_key(actual, 'kana')
        if char then
          double = not tbl.hankanalist:find(actual, 1, true)
          altchar = tbl.altchar[char]
        else
          match = false
        end
      end
    end
  end
  return match, actual, char, altchar, double
end

-- Returns a function that extracts the first column of a wrapped line
function _session.start_at_extmark(self, indices)
  local enable_wrap = api.nvim_get_option_value('wrap', { win = self.winid })
  local start_at = self.front_byteidx
  local line_idx = 1
  if not enable_wrap then
    return function(_)
      self.keys.mark_pos[line_idx] = self.front_byteidx
      return line_idx
    end
  end
  local prev_col
  if self.reversive then
    prev_col = fn.screenpos(self.winid, self.cur_row, #indices).col
    return function(byteidx)
      local screen = fn.screenpos(self.winid, self.cur_row, self.front_byteidx + byteidx)
      local screen_col = util.zerobase(screen.col) - self.info_width
      if screen_col > prev_col then
        line_idx = line_idx + 1
      end
      prev_col = screen_col
      self.keys.mark_pos[line_idx] = self.front_byteidx + util.zerobase(byteidx)
      return line_idx
    end
  else
    prev_col = fn.screenpos(self.winid, self.cur_row, start_at).col
    return function(byteidx)
      local screen = fn.screenpos(self.winid, self.cur_row, self.front_byteidx + byteidx)
      local screen_col = util.zerobase(screen.col) - self.info_width
      if screen_col < prev_col then
        line_idx = line_idx + 1
        self.keys.mark_pos[line_idx] = self.front_byteidx + util.zerobase(byteidx)
      end
      prev_col = screen_col
      return line_idx
    end
  end
end

-- Store key information in Session.keys
function _session.store_key(self, actual, idx, byteidx, start_at, kana)
  local match, char, altchar, double
  local level = 0
  if idx > self.till then
    local vcount = self.keys.ignore[actual] or self.vcount
    if vcount ~= 0 then
      vcount = vcount - 1
      self.keys.ignore[actual] = vcount
    end
    match, actual, char, altchar, double = _matcher(actual, kana)
    if match and (vcount < 1) then
      ---@cast char -?
      level = self.keys.level[char] and (self.keys.level[char] + 1) or 1
      self.keys.level[char] = math.min(2, level)
    end
  end
  if not char then
    level = 0
  elseif level == 1 then
    self.keys.first_idx[char] = idx
    -- Add a key with a list containing the same vowel to the target
    if altchar and not self.keys.first_idx[altchar] then
      self.keys.first_idx[altchar] = idx
    end
  elseif char:match('[%d%p%s]') then
    if self.enable_symbol and level > 1 then
      level = 3
      local first = self.keys.first_idx[char]
      if first then
        self.keys.detail[first].level = level
        self.keys.first_idx[char] = nil
      end
    else
      level = 0
    end
  elseif level == 2 then
    self.keys.second_idx[char] = idx
    if altchar and not self.keys.second_idx[altchar] then
      self.keys.second_idx[altchar] = idx
    end
  elseif level == 3 then
    local second = self.keys.second_idx[char]
    if second then
      self.keys.detail[second].level = 3
      self.keys.second_idx[char] = nil
      if altchar then
        self.keys.second_idx[altchar] = nil
      end
    end
  end
  table.insert(self.keys.detail, {
    actual = actual,
    char = char,
    altchar = altchar,
    level = level,
    double = double,
    byteidx = byteidx,
    start_at = start_at,
  })
end

-- Add blank space for an inlay hint
---@param backward string
---@return string, string
local function _hint(backward)
  local forward = ' '
  if backward:find(':') ~= 1 then
    forward, backward = backward, forward
  end
  return forward, backward
end

-- Extract a hint label
---@param label table
---@return string
local function _hint_label(label)
  local v = ''
  for _, t in ipairs(label) do
    v = string.format('%s%s', v, t.value)
  end
  return v
end

function _session.get_inlay_hints(self, width)
  local inlay_hint = vim.lsp.inlay_hint
  if not inlay_hint then
    return {}
  end
  local line = util.zerobase(self.cur_row)
  local start, end_ = self.front_byteidx + 1, self.front_byteidx + width
  local iter = vim.iter(inlay_hint.get({
    bufnr = self.bufnr,
    range = { start = { character = start, line = line }, ['end'] = { character = end_, line = line } },
  }))
  if self.reversive then
    iter:rev()
  end
  local hints = {}
  iter:each(function(v)
    local byteidx = v.inlay_hint.position.character - self.front_byteidx + 1
    local actual = _hint_label(v.inlay_hint.label)
    actual = string.format('%s%s', _hint(actual))
    hints[byteidx] = { actual = actual, level = 5, bytes = #actual }
  end)
  return hints
end

-- Obtaining and setting key information
function _session.get_keys(self, indices)
  local new_indices = ''
  local char, bytes
  local pos = vim.str_utf_pos(indices)
  if self.reversive then
    table.sort(pos, function(x, y)
      return x > y
    end)
  end
  local iter = vim.iter(ipairs(pos))
  local start_at = self:start_at_extmark(indices)
  local i, limit = 1, 1000
  iter:each(function(idx, byteidx)
    bytes = byteidx + vim.str_utf_end(indices, byteidx)
    char = indices:sub(byteidx, bytes)
    self:store_key(char, idx, byteidx, start_at(byteidx), self.enable_kana)
    new_indices = string.format('%s%s', new_indices, char)
    if i > limit then
      iter:last()
    end
    i = i + 1
  end)
  return new_indices
end

-- Process for key input
function _session.key_in(self)
  self.timer.debounce(vim.g.fret_timeout, function()
    api.nvim_input('<Esc>')
  end)
  local input = fn.nr2char(fn.getchar())
  api.nvim_buf_clear_namespace(self.bufnr, self.ns, self.cur_row - 1, self.cur_row)
  if input:match('%C') then
    return input
  end
end

-- Repeatable key handling
function _session.repeatable(self, count)
  local till = ''
  if self.till ~= 0 then
    till = not self.reversive and 'l' or 'h'
  end
  local keystroke = string.format('%s%s%s%s', till, self.vcount, self.mapkey, self.keys.detail[count].actual)
  vim.cmd.normal({ keystroke, bang = true })
end

-- Operable key handring
function _session.operable(self, count)
  local char = self.keys.detail[count].actual
  local line = self.line
  local vcount = fn.count(fn.strcharpart(line, 0, count), char)
  local select = ''
  if self.operative then
    select = self.reversive and 'hv' or 'v'
  end
  local operator = vim.v.operator
  local keystroke = string.format('%s%s%s%s', select, vcount, self.mapkey, char)
  vim.cmd.normal({ keystroke, bang = true })
  if self.notify and self.operative then
    local msg = string.format('%s: %s%s%s%s', 'dotrepeat', operator, vcount, self.mapkey, char)
    util.notify(UNIQ_ID, msg, vim.log.levels.INFO, { title = UNIQ_ID })
  end
  return keystroke
end

-- Finish of key operation
function _session.finish(self)
  self.timer.stop()
  Session = { dotrepeat = self.dotrepeat, keys = _newkeys() }
end

-- Adjust marker letter width
---@param double boolean
---@param marker string A uppercase letter
---@return string alt_letter
local function _adjust_marker_width(double, marker)
  return double and string.format(' %s', marker) or marker
end

-- Map marks for related-mode
---@param char? string
---@return Iter?
local function _iter_marks(char)
  if not char then
    return
  end
  local r_symbol = '123456!"#$%&'
  local lower_symbol = [=[1234567890-^\@[;:],./\ ]=]
  local main, sub = Fret.altkeys.lshift, Fret.altkeys.rshift
  local rkeys = string.format('%s%s', sub, r_symbol)
  if rkeys:find(char, 1, true) then
    main, sub = sub, main
  end
  local s = string.format('%s%s', main, sub)
  if lower_symbol:find(char, 1, true) then
    s = s:lower()
  end
  local int = s:find(char, 1, true)
  local t = vim.split(s, '', { plain = true })
  if int then
    table.remove(t, int)
  end
  table.insert(t, 1, char)
  return vim.iter(ipairs(t))
end

-- Create and get line markers
function _session.get_markers(self, callback)
  local count = 1
  local markers = {}
  local forward = function(v)
    local hint = self.hints[v.byteidx]
    util.tbl_insert(markers, v.start_at, 1, { callback(v, count), self.hlgroup[v.level] })
    if hint then
      util.tbl_insert(markers, v.start_at, 1, { hint.actual, self.hlgroup[hint.level] })
    end
    count = count + 1
  end
  local backward = function(v)
    local hint = self.hints[v.byteidx]
    if hint then
      util.tbl_insert(markers, v.start_at, { hint.actual, self.hlgroup[hint.level] })
    end
    util.tbl_insert(markers, v.start_at, { callback(v, count), self.hlgroup[v.level] })
    count = count + 1
  end
  local iter = vim.iter(self.keys.detail)
  iter:each(self.reversive and forward or backward)
  return markers
end

-- Create a table of extmarks
function _session.create_line_marker(self, width, input, lower)
  self['hints'] = self.hints or self:get_inlay_hints(width)
  local iter_marks = _iter_marks(input)
  local normal = function(v)
    local mark
    if v.level == 0 then
      mark = v.actual
    elseif v.level == 1 then
      mark = _adjust_marker_width(v.double, v.char)
    elseif v.level == 2 then
      mark = _adjust_marker_width(v.double, v.char:upper())
    else
      mark = v.actual:upper()
    end
    return mark
  end
  ---@cast iter_marks -?
  local related = function(v, count)
    if (v.level > 1) and (v.char == lower or v.altchar == lower) then
      local _, key = iter_marks:next()
      if key then
        self.keys.first_idx[key] = count
        v.level = 4
        return _adjust_marker_width(v.double, key)
      end
    end
    v.level = 0
    return v.actual
  end
  return self:get_markers(not input and normal or related)
end

-- Attach extmarks on current line
function _session.attach_extmark(self, input, lower)
  local row = util.zerobase(self.cur_row)
  local width = api.nvim_strwidth(self.line)
  local markers = self:create_line_marker(width, input, lower)
  if not input or (vim.tbl_count(self.keys.first_idx) > 1) then
    for line_idx, marker_text in pairs(markers) do
      api.nvim_buf_set_extmark(self.bufnr, self.ns, row, self.keys.mark_pos[line_idx], {
        end_col = width,
        virt_text = marker_text,
        virt_text_pos = 'overlay',
        hl_mode = self.hlmode,
      })
    end
    vim.cmd.redraw()
  end
end

function _session.related(self, input, lower)
  self.keys.first_idx = {}
  self:attach_extmark(input, lower)
  local match_item = vim.tbl_count(self.keys.first_idx)
  if match_item == 0 then
    api.nvim_input('<Esc>')
  elseif match_item == 1 then
    self:operable(self.keys.first_idx[input])
  else
    vim.cmd(string.format('lua require("fret"):performing()'))
  end
end

-- Whether a uppercase or a kana character
---@param symbol boolean
---@param char string
---@return boolean
local function _upper_or_kana(symbol, char)
  return symbol and char:match('[%w%p%s]') or char:match('%u')
end

-- Move the cursor to the desired position
function _session.gain(self, input)
  local lower = input:lower()
  local count = self.keys.first_idx[lower]
  local subcount = self.keys.second_idx[lower]
  local is_lower = input:match('%U')
  local is_upper = _upper_or_kana(self.enable_symbol, input)
  -- Item that immediately moves the cursor to the key obtained by input
  if count and is_lower then
    if not self.operative then
      self:repeatable(count)
    else
      self['dotrepeat'] = self:operable(count)
    end
  elseif is_upper then
    if subcount then
      self['dotrepeat'] = self:operable(subcount)
    else
      -- Items that require two or more inputs to move the cursor
      self:related(input, lower)
    end
  else
    _abort(self.operative)
  end
end

-- Executing fret
function Fret.inst(self, mapkey, direction, till)
  if self.mapped_trigger then
    self.mapped_trigger = nil
    self.playing(mapkey, direction, till)
  else
    self.dotrepeat()
  end
end

-- Start operation
function Fret.playing(mapkey, direction, till)
  Session = _session.new(mapkey, direction, till)
  local indices = Session:set_line_informations()
  if not indices or (vim.str_utfindex(indices, #indices) <= Session.till) then
    return
  end
  Session['line'] = Session:get_keys(indices)
  Session:attach_extmark()
  local input = Session:key_in()
  if input then
    Session:gain(input)
  else
    _abort(Session.operative)
  end
  Session:finish()
end

-- Handling related-mode
function Fret.performing()
  local input = Session:key_in()
  if input then
    local count = Session.keys.first_idx[input]
    if count and input:match('[%w%p%s]') then
      Session['dotrepeat'] = Session:operable(count)
      return
    end
    input = input:match('[hjkl]') and input or '<Esc>'
    api.nvim_input(input)
  end
  _abort(Session.operative)
end

-- Handling dot-repeat
function Fret.dotrepeat()
  vim.cmd.normal({ Session.dotrepeat, bang = true })
end

function Fret.setup(opts)
  local ok = require('fret.config').set_options(opts)
  if not ok then
    util.notify(UNIQ_ID, 'Error: Requires arguments', vim.log.levels.ERROR, { title = UNIQ_ID })
  end
  return ok
end

return Fret
