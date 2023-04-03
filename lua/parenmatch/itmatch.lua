--------------------------------------------------------------------------------
-- Filename: itmatch.lua
-- Author: tar80
-- License: MIT License
--------------------------------------------------------------------------------

---@module "itmatch"
local itmatch = {}
local matcher = {}

local ts = vim.treesitter
local api = vim.api

local TITLE = 'itmatch'

if type(package.loaded['nvim-treesitter']) ~= 'table' then
  return vim.notify(string.format('[%s] Treesitter not loaded', TITLE), 3, { title = TITLE })
end

---matching keywords for each filetype
local function set_default()
  matcher = {
    lua = { s = { 'function', 'if', 'while', 'repeat', 'for', 'do' }, e = { 'end', 'until' } },
    vim = {
      s = { 'function', 'fu', 'if', 'while', 'wh', 'for', 'try' },
      e = { 'endfunction', 'endf', 'endif', 'en', 'endwhile', 'endw', 'endfor', 'endfo', 'endtry', 'endt' },
    },
  }
end

---@param mode string Current edit mode
---@return boolean # Is operator-command or not
local function is_operator(mode)
  return mode:find('^no') and true
end

---@param opts table user configration
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

---define which meta-table in tsnode to use
---@return table # Match definition of filetype
local function expand_tskey()
  local ft = vim.bo.filetype
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

local function detect_items(col, mode, words)
  local line = api.nvim_get_current_line()
  local keywords = vim.tbl_keys(words)
  local digit, int

  for _, v in ipairs(keywords) do
    int = line:sub(col + 1):find('[%s%(%[%{,]' .. v .. '[%s%(%[%{]')
    if int then
      digit = int
      break
    end
  end

  local input = digit and string.format('%s%s', digit, 'l') or string.format('%s%%', is_operator(mode) and 'v' or '')

  api.nvim_command(string.format('normal! %s', input))
end

local function match_node(row, col, mode, point, words)
  local node = ts.get_node and ts.get_node({ bufnr = 0, pos = { row - 1, col } })
    or ts.get_node_at_pos(0, row - 1, col, {})
  local pair_row, pair_col = node[point](node)

  if point == 'start' then
    pair_col = pair_col + 1
  end

  api.nvim_command(string.format('normal! %s%sgg0%sl', is_operator(mode) and 'v' or '', pair_row + 1, pair_col - 1))

  if point == 'start' and not vim.tbl_contains(vim.tbl_keys(words), vim.fn.expand('<cword>')) then
    api.nvim_feedkeys('w', 'n', false)
  end
end

---move cursor to match keyword
itmatch.alignment = function()
  local mode = vim.fn.mode(1)
  local vcount = vim.v.count1
  local row, col = unpack(api.nvim_win_get_cursor(0))
  local words = expand_tskey()
  local cword = vim.fn.expand('<cword>'):lower()
  local point = words[cword]

  if vcount > 1 then
    api.nvim_command(string.format('normal! %s%%', vcount))
  elseif not point then
    detect_items(col, mode, words)
  else
    match_node(row, col, mode, point, words)
  end
end

set_default()

vim.keymap.set({ 'n', 'x', 'o' }, '%', function()
  return '<Cmd>lua require("parenmatch.itmatch").alignment()<CR>'
end, { expr = true, desc = 'itmatch' })

return itmatch
