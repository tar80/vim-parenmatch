--------------------------------------------------------------------------------
-- Filename: itmatch.lua
-- Author: tar80
-- License: MIT License
--------------------------------------------------------------------------------

---@alias move_target 'end_'|'start'

---@module "itmatch"
local itmatch = {}
local matcher = {}

local ts = vim.treesitter
local api = vim.api

local TITLE = 'itmatch'

if type(package.loaded['nvim-treesitter']) ~= 'table' then
  return vim.notify(string.format('[%s] Treesitter not loaded', TITLE), 3, { title = TITLE })
end

---@desc Matching keywords for each filetypes
local function set_default()
  matcher = {
    lua = { s = { 'function', 'if', 'while', 'repeat', 'for', 'do' }, e = { 'end', 'until' } },
    vim = {
      s = { [=[\<fu\%[nction]\>]=], 'if', [=[<\wh\%[ile]\>]=], 'for', 'try' },
      e = {
        [=[\<en\%[dif]\>]=],
        [=[\<endfor\?\>]=],
        [=[\<endf\%[unction]\>]=],
        [=[\<endw\%[hile]\>]=],
        [=[\<endt\%[ry]\>]=],
      },
    },
  }
end

---@param mode string Current edit mode
---@return boolean # Is operator-command or not
local function is_operator(mode)
  return type(mode:find('^no')) == 'number'
end

---@param opts Parenmatch Optional custom settings
---@param append function `config.tbl_append(base_tbl, addition_tbl)`
itmatch.setup = function(opts, append)
  if not opts then
    set_default()
    return
  end

  for key, value in pairs(opts) do
    if not matcher[key] then
      matcher[key] = opts[key]
    else
      if value.s then
        matcher[key].s = append(matcher[key].s, value.s)
      end

      if value.e then
        matcher[key].e = append(matcher[key].e, value.e)
      end
    end
  end
end

---@class match_words
---@field [string] move_target

---@desc define which meta-table in tsnode to use
---@return match_words # Filetype match difinitions
local function expand_tskey()
  ---@type string
  local ft = vim.bo.filetype
  ---@type match_list
  local contents = matcher[ft]
  local t = {}

  if contents then
    for k, v in pairs(contents) do
      if k == 's' then
        vim.tbl_map(function(key)
          t[key] = 'end_'
        end, v)
      elseif k == 'e' then
        vim.tbl_map(function(key)
          t[key] = 'start'
        end, v)
      end
    end
  end

  return t
end

---@param words match_words
---@param cword string A Word under cursor position
---@return move_target
local function find_word(words, cword)
  local point = words[cword]

  if not point then
    ---@type string[]
    local keywords = vim.tbl_keys(words)
    ---@type number|nil
    local match

    for _, v in ipairs(keywords) do
      match = vim.regex(v):match_str(cword)

      if match then
        point = words[v]
        break
      end
    end
  end

  return point
end

---@param col number Column at the cursor position
---@param mode string Current vim-mode
---@param words match_words
local function detect_items(col, mode, words)
  ---@type string
  local line = api.nvim_get_current_line()
  ---@type string[]
  local keywords = vim.tbl_keys(words)
  ---@type integer|nil, integer|nil
  local digit, int

  for _, v in ipairs(keywords) do
    int = line:sub(col + 1):find('[%s%(%[%{,]' .. v .. '[%s%(%[%{]')
    if int then
      digit = int
      break
    end
  end

  local input = digit and string.format('%s%s', digit, 'l') or string.format('%s%%', is_operator(mode) and 'v' or '')

  vim.cmd.normal({ input, bang = true })
end

---@param row number Row at the cursor position
---@param col number Column at the cursor position
---@param mode string Current vim-mode
---@param point 'end_'|'start'
---@param words match_words
---@param cword string A Word under cursor position
local function match_node(row, col, mode, point, words, cword)
  ---@type userdata|nil
  local node = ts.get_node and ts.get_node({ bufnr = 0, pos = { row - 1, col } })
    or ts.get_node_at_pos(0, row - 1, col, {})

  if not node then
    return
  end

  local pair_row, pair_col = node[point](node)

  if point == 'start' then
    pair_col = pair_col + 1
  end

  vim.cmd(string.format('normal! %s%sgg0%sl', is_operator(mode) and 'v' or '', pair_row + 1, pair_col - 1))
  ---@type string
  local line = api.nvim_get_current_line()
  ---@type number
  col = api.nvim_win_get_cursor(0)[2]
  ---@string
  local cursor_char = vim.fn.matchstr(line, '.', col)

  if point == 'start' and not vim.tbl_contains(vim.tbl_keys(words), vim.fn.expand('<cword>')) then
    api.nvim_feedkeys('w', 'n', false)
  end
end

---@desc Move cursor to match keyword
itmatch.alignment = function()
  ---@type string
  local mode = vim.fn.mode(1)
  ---@type number
  local vcount = vim.v.count1
  ---@type number, number
  local row, col = unpack(api.nvim_win_get_cursor(0))
  local words = expand_tskey()
  ---@type string
  local cword = vim.fn.expand('<cword>')
  local point = find_word(words, cword:lower())

  if vcount > 1 then
    vim.cmd(string.format('normal! %s%%', vcount))
  elseif not point then
    detect_items(col, mode, words)
  else
    match_node(row, col, mode, point, words, cword)
  end
end

set_default()

vim.keymap.set({ 'n', 'x', 'o' }, '%', function()
  return '<Cmd>lua require("parenmatch.itmatch").alignment()<CR>'
end, { expr = true, desc = 'itmatch' })

return itmatch
