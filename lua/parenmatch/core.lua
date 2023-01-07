---@module "core"
local M = {}

local namespace = vim.api.nvim_create_namespace("parenmatch")
local timer = nil

---@type table parentheses information
local paren_info = {}

---@type string paren_info loaded flag
local match_info = ""

---@param types table ignore patterns
---@param type string
---|`filetype`
---|`buftype`
function M.buf_disable(types, type)
  if vim.bo[type] == "" then
    return
  end

  vim.b.parenmatch_disable = vim.tbl_contains(types, vim.bo[type])
end

---@param tbl table highlight information
function M.setup_highlight(tbl)
  vim.api.nvim_set_hl(0, "ParenMatch", tbl)
end

function M.load_matchpairs()
  local matchpairs = vim.bo.matchpairs

  if match_info == matchpairs then
    return
  end

  paren_info = {}
  match_info = matchpairs
  local parenlist = vim.tbl_map(function (v)
    return vim.split(v, ":", {plain = true})
  end, vim.split(matchpairs, ",", {plain = true}))
  local open, closed

  for _, v in ipairs(parenlist) do
    open = v[1] == "[" and "\\[" or v[1]
    closed = v[2] == "]" and "\\]" or v[2]
    paren_info[v[1]] = { open = open, closed = closed, flags = "nW", stop = "w$" }
    paren_info[v[2]] = { open = open, closed = closed, flags = "bnW", stop = "W0" }
  end
end

---@param arg? number adjust cursor position
function M.update(arg)
  if vim.g.parenmatch_disable or vim.b.parenmatch_disable then
    return
  end

  local i = arg or 0

  if not arg then
    local mode = vim.api.nvim_get_mode().mode
    i = (mode == "i" or mode == "R") and 1 or 0
  end

  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)


  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local chr = vim.fn.matchstr(vim.fn.getline("."), ".", col - i)
  local paren = paren_info[chr]

  if paren == nil then
    return
  end

  -- Note:In insert mode, the character in front of the cursor is the target of the parenmatch.
  local virtual = {row = row, col = col - i }
  -- actual position
  local ap

  if i > 0 then
    ap = vim.fn.getcurpos()
    vim.fn.cursor(virtual)
  end

  local pair_row, pair_col = unpack(vim.fn.searchpairpos(paren.open, "", paren.closed, paren.flags, "", vim.fn.line(paren.stop), 10))

  if i > 0 then
    vim.fn.setpos(".", ap)
  end

  if pair_row > 0 and virtual.col ~= 0 then
    vim.api.nvim_buf_add_highlight(0, namespace, "parenmatch", virtual.row - 1, virtual.col, virtual.col + 1)
    vim.api.nvim_buf_add_highlight(0, namespace, "parenmatch", pair_row - 1, pair_col - 1, pair_col)
  end
end

function M.cursormoved()
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

  if timer then
    timer:stop()
    timer:close()
  end

  timer = vim.loop.new_timer()
  timer:start(
    50,
    0,
    vim.schedule_wrap(function()
      M.update()
    end)
  )
end

return M
