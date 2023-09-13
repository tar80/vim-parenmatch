--------------------------------------------------------------------------------
-- Filename: init.lua
-- Author: tar80
-- License: MIT License
--------------------------------------------------------------------------------

---@class Parenmatch
---@field highlight table Custome highlight for ParenMatch
---@field ignore_filetypes table User specified ignore filetypes
---@field ignore_buftypes table User specified ignore buffer types
---@field itmatch itmatch Itmatch options
---@field setup table
---@field clear_ns function
---@field set_hl function
---@field buf_disable function
---@field ignore_ft function
---@field ignore_bt function
---@field cursormoved function
---@field matchpairs function
---@field update function

---@class itmatch
---@field enable boolean
---@field matcher match_list

---@class match_list
---@field s table regular expression string to start with
---@field e table regular expression string to end with

_G.Parenmatch = {
  highlight = { underline = true },
  ignore_filetypes = {},
  ignore_buftypes = {},
}
local meta = {}
local paren_info = {}
local match_info = ''
local timer = nil
local ns = vim.api.nvim_create_namespace('parenmatch')

setmetatable(_G.Parenmatch, { __index = meta })

---@param opts Parenmatch Optional custom settings
function meta.setup(opts)
  require('parenmatch.config').setup(opts)
end

meta.clear_ns = function()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

meta.set_hl = function()
  vim.api.nvim_set_hl(0, 'ParenMatch', _G.Parenmatch.highlight)
end

---@param type 'filetype'|'buftype' User specified ignore types
meta.buf_disable = function(self, type)
  if vim.bo[type] == '' then
    return
  end

  vim.b.parenmatch_disable = vim.tbl_contains(self[string.format('ignore_%ss', type)], vim.bo[type])
end

meta.ignore_ft = function(self)
  if vim.b.parenmatch_disable or vim.tbl_isempty(_G.Parenmatch.ignore_buftypes) then
    return
  end

  self:buf_disable('filetype')
end

meta.ignore_bt = function(self)
  timer = vim.uv.new_timer()

  timer:start(
    100,
    0,
    vim.schedule_wrap(function()
      if vim.b.parenmatch_disable or vim.tbl_isempty(_G.Parenmatch.ignore_buftypes) then
        return
      end

      self:buf_disable('buftype')
    end)
  )
end

meta.cursormoved = function(self)
  self.clear_ns()

  if timer then
    timer:stop()
    timer:close()
  end

  timer = vim.uv.new_timer()
  timer:start(
    50,
    0,
    vim.schedule_wrap(function()
      self:update()
    end)
  )
end

meta.matchpairs = function()
  local matchpairs = vim.bo.matchpairs

  if match_info == matchpairs then
    return
  end

  paren_info = {}
  match_info = matchpairs
  local parenlist = vim.tbl_map(function(v)
    return vim.split(v, ':', { plain = true })
  end, vim.split(matchpairs, ',', { plain = true }))
  local open, closed

  for _, v in ipairs(parenlist) do
    open = v[1] == '[' and '\\[' or v[1]
    closed = v[2] == ']' and '\\]' or v[2]
    paren_info[v[1]] = { open = open, closed = closed, flags = 'nW', stop = 'w$' }
    paren_info[v[2]] = { open = open, closed = closed, flags = 'bnW', stop = 'W0' }
  end
end

---@param adjust? integer Cursor position adjustment by vim-mode
meta.update = function(self, adjust)
  if vim.g.parenmatch_disable or vim.b.parenmatch_disable then
    return
  end

  local int = adjust or 0

  if not adjust then
    local mode = vim.api.nvim_get_mode().mode
    int = (mode == 'i' or mode == 'R') and 1 or 0
  end

  self.clear_ns()

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  col = math.max(0, col - int)
  local getline = vim.api.nvim_get_current_line()
  local chr = vim.fn.matchstr(getline, '.', col)
  local paren = paren_info[chr]

  if paren == nil then
    return
  end

  -- NOTE: In insert mode, the character in front of the cursor is the target of the parenmatch.
  local virtual_pos = { row = row, col = col }
  local actual_pos

  if int > 0 then
    actual_pos = vim.fn.getcurpos()
    vim.api.nvim_win_set_cursor(0, { virtual_pos.row, virtual_pos.col })
  end

  local pair_pos_row, pair_pos_col =
    unpack(vim.fn.searchpairpos(paren.open, '', paren.closed, paren.flags, '', vim.fn.line(paren.stop), 10))

  if int > 0 then
    vim.fn.setpos('.', actual_pos)
  end

  if pair_pos_row > 0 and virtual_pos.col >= 0 then
    vim.api.nvim_buf_add_highlight(0, ns, 'parenmatch', virtual_pos.row - 1, virtual_pos.col, virtual_pos.col + 1)
    vim.api.nvim_buf_add_highlight(0, ns, 'parenmatch', pair_pos_row - 1, pair_pos_col - 1, pair_pos_col)
  end
end

if vim.fn.has('vim_starting') == 0 then
  meta.set_hl()
  meta.matchpairs()
end

return meta
