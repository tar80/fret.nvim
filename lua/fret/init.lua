local helper = require('fret.helper')
local util = require('fret.util')
local timer = require('fret.timer')
local beacon = require('fret.beacon')
local compat = require('fret.compat')
local tbl = require('fret.tbl')
local api = vim.api
local fn = vim.fn

local UNIQUE_NAME = 'fret.nvim'

---@class Fret
local Fret = {
  ns = api.nvim_create_namespace(UNIQUE_NAME),
  timer = timer.set_timer(),
  mapped_trigger = false,
  altkeys = {},
  beacon = {},
  hlgroup = {},
}

-- Clean up the keys database
local function _newkeys()
  return { level = {}, ignore = {}, detail = {}, mark_pos = {}, first_idx = {}, second_idx = {} }
end

---@class Session
local _session = {}
_session.__index = _session

---@class Session
local Session = { keys = _newkeys() }

-- Start new session
---@param mapkey string
---@param direction 'forward'|'backward'
---@param till integer
function _session.new(mapkey, direction, till)
  local winid = api.nvim_get_current_win()
  local pos = api.nvim_win_get_cursor(winid)
  local instance = {
    bufnr = api.nvim_get_current_buf(),
    winid = winid,
    cur_row = pos[1],
    cur_col = pos[2],
    conceallevel = vim.wo[winid].conceallevel,
    hlmode = vim.g.fret_hlmode,
    notify = vim.g.fret_repeat_notify,
    enable_beacon = vim.g.fret_enable_beacon,
    enable_kana = vim.g.fret_enable_kana,
    enable_symbol = vim.g.fret_enable_symbol,
    enable_fold = vim.g.fret_smart_fold,
    timeout = vim.g.fret_timeout,
    samekey_repeat = vim.g.fret_samekey_repeat,
    vcount = vim.v.count1,
    mapkey = mapkey,
    reversive = direction == 'forward',
    operative = helper.is_operator(),
    till = till,
    front_byteidx = 0,
    keys = _newkeys(),
    utf_encoding = 'utf-32',
  }
  if vim.b.fret_session_repeat then
    vim.b.fret_session_repeat = false
    instance.enable_symbol = false
    instance.ignore_extmark = true
  end
  return setmetatable(instance, _session)
end

-- Adjust the number for zero-based
---@param idx integer
---@return integer zero-based index
local function zerobase(idx)
  return idx - 1
end

-- Abort operation
---@operative boolean
local function abort(operative)
  if operative then
    api.nvim_input('<Cmd>normal! u<CR>')
  end
end

-- Open the fold. If it is folded
---@param session Session
---@return true?
local function fold_open(session)
  if session.enable_fold and (fn.foldclosed(session.cur_row) ~= -1) then
    vim.cmd.foldopen()
    return true
  end
end

-- Close the fold. If it was opened by fret
---@param is_fold boolean
local function fold_close(is_fold)
  if is_fold then
    vim.cmd.foldclose()
  end
end

-- Get and update line information
function _session.set_line_informations(self)
  local line = api.nvim_get_current_line()
  if line == '' then
    return
  end
  local winsaveview = fn.winsaveview()
  ---@type integer
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
  ---@type string?
  local indices
  -- NOTE: consider that cur_col is zero-based
  if self.reversive then
    indices = line:sub(1, self.cur_col - leftcol)
  else
    self['front_byteidx'] = compat.str_byteindex(
      line,
      self.utf_encoding,
      compat.str_utfindex(line, self.utf_encoding, self.cur_col - leftcol + 1, false),
      false
    )
    indices = line:sub(self.front_byteidx + 1)
  end
  self['leftcol'] = leftcol
  self['info_width'] = info_width
  return indices
end

-- Convert a character to a valid key
---@param chr string
---@param name string Table name in string array
---@return string?
local function valid_key(chr, name)
  for k, v in pairs(tbl[name]) do
    if v:find(chr, 1, true) then
      return k
    end
  end
end

-- Get matched character details
---@param actual string
---@param enable_kana boolean
---@return string?,string,string?,string?,boolean?
local function get_match_details(actual, enable_kana)
  local match, chr, altchr, double
  if actual:match('%C') then
    match = actual:match('[%w%p%s]')
    if match then
      chr = actual:lower()
    else
      match = actual:match('[^%g%s]')
      if match then
        chr = valid_key(actual, 'glyph')
        if chr then
          double = (vim.api.nvim_strwidth(actual) > 1)
        elseif enable_kana then
          chr = valid_key(actual, 'kana')
          if chr then
            double = not tbl.hankanalist:find(actual, 1, true)
            altchr = tbl.altchar[chr]
          else
            match = false
          end
        end
      end
    end
  end
  return match, actual, chr, altchr, double
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
      local screen_col = zerobase(screen.col) - self.info_width
      if screen_col > prev_col then
        line_idx = line_idx + 1
      end
      prev_col = screen_col
      self.keys.mark_pos[line_idx] = self.front_byteidx + zerobase(byteidx)
      return line_idx
    end
  else
    prev_col = fn.screenpos(self.winid, self.cur_row, start_at).col
    return function(byteidx)
      local screen = fn.screenpos(self.winid, self.cur_row, self.front_byteidx + byteidx)
      local screen_col = zerobase(screen.col) - self.info_width
      if screen_col < prev_col then
        line_idx = line_idx + 1
        self.keys.mark_pos[line_idx] = self.front_byteidx + zerobase(byteidx)
      end
      prev_col = screen_col
      return line_idx
    end
  end
end

-- Store key information in Session.keys
function _session.store_key(self, actual, idx, byteidx, start_at, kana)
  local match, chr, altchr, double
  local level = 0
  if idx > self.till then
    local vcount = self.keys.ignore[actual] or self.vcount
    if vcount ~= 0 then
      vcount = vcount - 1
      self.keys.ignore[actual] = vcount
    end
    match, actual, chr, altchr, double = get_match_details(actual, kana)
    if match and (vcount < 1) then
      ---@cast chr -?
      level = self.keys.level[chr] and (self.keys.level[chr] + 1) or 1
      self.keys.level[chr] = math.min(2, level)
    end
  end
  if not chr then
    level = 0
  elseif level == 1 then
    self.keys.first_idx[chr] = idx
    -- Add a key with a list containing the same vowel to the target
    if altchr and not self.keys.first_idx[altchr] then
      self.keys.first_idx[altchr] = idx
    end
  elseif chr:match('[%d%p%s]') then
    if self.enable_symbol and level > 1 then
      level = 3
      local first = self.keys.first_idx[chr]
      if first then
        self.keys.detail[first].level = level
        self.keys.first_idx[chr] = nil
      end
    else
      level = 0
    end
  elseif level == 2 then
    self.keys.second_idx[chr] = idx
    if altchr and not self.keys.second_idx[altchr] then
      self.keys.second_idx[altchr] = idx
    end
  elseif level == 3 then
    local second = self.keys.second_idx[chr]
    if second then
      self.keys.detail[second].level = 3
      self.keys.second_idx[chr] = nil
      if altchr then
        self.keys.second_idx[altchr] = nil
      end
    end
  end
  table.insert(self.keys.detail, {
    actual = actual,
    chr = chr,
    altchr = altchr,
    level = level,
    double = double,
    byteidx = byteidx,
    start_at = start_at,
  })
end

-- Add blank space for an inlay hint
---@param backward string
---@return string, string
local function adjust_inlay_hint_width(backward)
  local forward = ' '
  if backward:find(':') ~= 1 then
    forward, backward = backward, forward
  end
  return forward, backward
end

-- Extract a hint label
---@param label table
---@return string
local function get_inlay_hint_label(label)
  local v = ''
  for _, t in ipairs(label) do
    v = string.format('%s%s', v, t.value)
  end
  return v
end

function _session.is_concealed(self)
  if self.conceallevel == 0 then
    return function()
      return false
    end
  end
  local row = zerobase(self.cur_row)
  if self.reversive then
    return function(byteidx)
      local skip = false
      local capture = vim.treesitter.get_captures_at_pos(0, row, byteidx - 1)[1]
      if capture and capture.metadata.conceal == '' then
        skip = true
      end
      return skip
    end
  else
    return function(byteidx)
      local skip = false
      local capture = vim.treesitter.get_captures_at_pos(0, row, self.front_byteidx + byteidx - 1)[1]
      if capture and capture.metadata.conceal == '' then
        skip = true
      end
      return skip
    end
  end
end

function _session.get_inlay_hints(self, width)
  local inlay_hint = vim.lsp.inlay_hint
  if not inlay_hint then
    return {}
  end
  local line = zerobase(self.cur_row)
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
    local actual = get_inlay_hint_label(v.inlay_hint.label)
    actual = string.format('%s%s', adjust_inlay_hint_width(actual))
    hints[byteidx] = { actual = actual, level = 5, bytes = #actual }
  end)
  return hints
end

-- Obtaining and setting key information
function _session.get_keys(self, indices)
  local new_indices = ''
  local chr, bytes
  local pos = vim.str_utf_pos(indices)
  if self.reversive then
    table.sort(pos, function(x, y)
      return x > y
    end)
  end

  ---NOTE: If the line length exceeds 1000 characters, the iteration is aborted.
  local i, limit = 1, 1000
  local iter = vim.iter(ipairs(pos))
  local start_at = self:start_at_extmark(indices)
  local concealment_status = self:is_concealed()
  local skip_idx = 0
  iter:each(function(idx, byteidx)
    if concealment_status(byteidx) then
      skip_idx = skip_idx + 1
      i = i + 1
      return
    end
    idx = idx - skip_idx
    bytes = byteidx + vim.str_utf_end(indices, byteidx)
    chr = indices:sub(byteidx, bytes)
    self:store_key(chr, idx, byteidx, start_at(byteidx), self.enable_kana)
    new_indices = string.format('%s%s', new_indices, chr)
    i = i + 1
    if i > limit then
      iter:last()
    end
  end)
  return new_indices
end

-- Process for key input
function _session.key_in(self)
  Fret.timer.debounce(vim.g.fret_timeout, function()
    api.nvim_input('<Esc>')
    fold_close(self.is_fold)
  end)
  local input = fn.nr2char(fn.getchar() --[[@as integer]])
  api.nvim_buf_clear_namespace(self.bufnr, Fret.ns, self.cur_row - 1, self.cur_row)
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
  if not self.operative then
    self:post_process(count)
  end
end

-- Operable key handring
function _session.operable(self, count)
  local chr = self.keys.detail[count].actual
  local line = self.line
  local vcount = fn.count(fn.strcharpart(line, 0, count), chr)
  local select = ''
  if self.operative then
    select = self.reversive and 'hv' or 'v'
  end
  local operator = vim.v.operator
  local keystroke = string.format('%s%s%s%s', select, vcount, self.mapkey, chr)
  vim.cmd.normal({ keystroke, bang = true })
  if not self.operative then
    self:post_process(count)
  end
  if self.notify and self.operative then
    local msg = string.format('%s: %s%s%s%s', 'dotrepeat', operator, vcount, self.mapkey, chr)
    vim.notify(msg, vim.log.levels.INFO, { title = UNIQUE_NAME })
  end
  return keystroke
end

-- Finish of key operation
function _session.finish(self)
  Fret.timer.stop()
  ---@class Session
  Session = { dotrepeat = self.dotrepeat, lastmap = self.mapkey, lastchr = self.last_chr, keys = _newkeys() }
end

function _session.post_process(self, count)
  if self.samekey_repeat then
    self.last_chr = self.keys.detail[count].chr
    vim.api.nvim_input('<Plug>(fret-cue)')
  elseif self.enable_beacon then
    if type(Fret.beacon.instance) ~= 'table' then
      Fret.beacon.instance = beacon.new(Fret.beacon.hl, Fret.beacon.interval, Fret.beacon.blend, Fret.beacon.decay)
    end
    Fret.beacon.instance:around_cursor(self.winid)
  end
end

-- Adjust marker letter width
---@param double boolean
---@param marker string A uppercase letter
---@return string alt_letter
local function _adjust_marker_width(double, marker)
  return double and string.format(' %s', marker) or marker
end

-- Map marks for related-mode
---@param chr? string
---@return Iter?
local function _iter_marks(chr)
  if not chr then
    return
  end
  local r_symbol = '123456!"#$%&'
  local lower_symbol = [=[1234567890-^\@[;:],./\ ]=]
  local main, sub = Fret.altkeys.lshift, Fret.altkeys.rshift
  local rkeys = string.format('%s%s', sub, r_symbol)
  if rkeys:find(chr, 1, true) then
    main, sub = sub, main
  end
  local s = string.format('%s%s', main, sub)
  if lower_symbol:find(chr, 1, true) then
    s = s:lower()
  end
  local int = s:find(chr, 1, true)
  local t = vim.split(s, '', { plain = true })
  if int then
    table.remove(t, int)
  end
  table.insert(t, 1, chr)
  return vim.iter(ipairs(t))
end

-- Create and get line markers
function _session.get_markers(self, callback)
  local count = 1
  local markers = {}
  local forward = function(v)
    local hint = self.hints[v.byteidx]
    util.tbl_insert(markers, v.start_at, 1, { callback(v, count), Fret.hlgroup[v.level] })
    if hint then
      util.tbl_insert(markers, v.start_at, 1, { hint.actual, Fret.hlgroup[hint.level] })
    end
    count = count + 1
  end
  local backward = function(v)
    local hint = self.hints[v.byteidx]
    if hint then
      util.tbl_insert(markers, v.start_at, { hint.actual, Fret.hlgroup[hint.level] })
    end
    util.tbl_insert(markers, v.start_at, { callback(v, count), Fret.hlgroup[v.level] })
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
      mark = _adjust_marker_width(v.double, v.chr)
    elseif v.level == 2 then
      mark = _adjust_marker_width(v.double, v.chr:upper())
    else
      mark = v.actual:upper()
    end
    return mark
  end
  ---@cast iter_marks -?
  local related = function(v, count)
    if (v.level > 1) and (v.chr == lower or v.altchr == lower) then
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
  local row = zerobase(self.cur_row)
  local width = api.nvim_strwidth(self.line)
  local markers = self:create_line_marker(width, input, lower)
  if not input or (vim.tbl_count(self.keys.first_idx) > 1) then
    for line_idx, marker_text in pairs(markers) do
      api.nvim_buf_set_extmark(self.bufnr, Fret.ns, row, self.keys.mark_pos[line_idx] + self.leftcol, {
        end_col = width + self.leftcol,
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
    fold_close(self.is_fold)
  elseif match_item == 1 then
    self:operable(self.keys.first_idx[input])
  else
    vim.cmd('lua require("fret"):performing()')
  end
end

-- Whether a uppercase or a kana character
---@param symbol boolean
---@param chr string
---@return boolean
local function _upper_or_kana(symbol, chr)
  return symbol and chr:match('[%w%p%s]') or chr:match('%u')
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
    abort(self.operative)
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
  Session['is_fold'] = fold_open(Session)
  local indices = Session:set_line_informations()
  if not indices or (compat.str_utfindex(indices, Session.utf_encoding, #indices, false) <= Session.till) then
    return
  end
  Session['line'] = Session:get_keys(indices)
  if not Session.ignore_extmark then
    Session:attach_extmark()
  end
  local input = Session:key_in()
  if input then
    Session:gain(input)
  else
    abort(Session.operative)
    fold_close(Session.is_fold)
  end
  Session:finish()
end

local _keycode_esc = vim.keycode('<Esc>')

-- Handling related-mode
function Fret.performing()
  local input = Session:key_in()
  if input then
    local count = Session.keys.first_idx[input]
    if count and input:match('[%w%p%s]') then
      Session['dotrepeat'] = Session:operable(count)
      return
    end
    input = input:match('[hjkl]') and input or _keycode_esc
    api.nvim_feedkeys(input, 'mi', false)
    fold_close(Session.is_fold)
  end
  abort(Session.operative)
end

-- Handling dot-repeat
function Fret.dotrepeat()
  vim.cmd.normal({ Session.dotrepeat, bang = true })
end

function Fret.same_key_repeat()
  local input = Session.lastchr
  if input and input:match('%U') then
    local keycode = fn.getchar(0) --[[@as integer]]
    if keycode ~= 0 then
      local repeat_key = fn.nr2char(keycode)
      if repeat_key == input:lower() then
        vim.b.fret_session_repeat = true
        vim.api.nvim_input(Session.lastmap .. input)
      else
        vim.api.nvim_input(repeat_key)
      end
    end
  end
end

function Fret.setup(opts)
  local conf = require('fret.config').set_options(opts)
  if not conf then
    vim.notify('Error: Requires arguments', vim.log.levels.ERROR, { title = UNIQUE_NAME })
    return
  end

  Fret.altkeys.lshift = conf.altkeys.lshift
  Fret.altkeys.rshift = conf.altkeys.rshift
  Fret.beacon = conf.beacon
  Fret.hlgroup = conf.hlgroup

  local augroup = api.nvim_create_augroup(UNIQUE_NAME, { clear = true })
  helper.set_hl(conf.hl_detail[vim.go.background])
  helper.autocmd({ 'ColorScheme' }, {
    desc = 'Fret reset highlights',
    group = augroup,
    callback = function()
      helper.set_hl(conf.hl_detail[vim.go.background])
    end,
  }, true)
end

return Fret
