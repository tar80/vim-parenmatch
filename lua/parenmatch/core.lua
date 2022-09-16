--------------------------------------------------------------------------------
-- Filename: core.lua
-- Author: tar80
-- License: MIT License
-- Last Change: 2022/09/11
--------------------------------------------------------------------------------

local core = {}
local paren_info = {}
local match_info = ""
local namespace = vim.api.nvim_create_namespace("parenmatch")
local timer = nil

function core.buf_disable(types, type)
  if vim.bo[type] == "" then
    return
  end

  vim.b.parenmatch = vim.tbl_contains(types, vim.bo[type])
end

function core.setup_highlight(value)
  vim.api.nvim_set_hl(0, "ParenMatch", value)
end

function core.load_matchpairs()
  local matchpairs = vim.bo.matchpairs

  if match_info == matchpairs then
    return
  end

  paren_info = {}
  match_info = matchpairs
  local parenlist = vim.fn.map(vim.fn.split(matchpairs, ","), 'split(v:val, ":")')
  local open, closed

  for _, v in ipairs(parenlist) do
    open = string.find(v[1], "%[]") and vim.fn.escape(v[1], "[]") or v[1]
    closed = string.find(v[2], "%[]") and vim.fn.escape(v[2], "[]") or v[2]
    paren_info[v[1]] = { open = open, closed = closed, flags = "nW", stop = "w$" }
    paren_info[v[2]] = { open = open, closed = closed, flags = "bnW", stop = "W0" }
  end
end

function core.update(arg)
  if vim.g.parenmatch or vim.b.parenmatch then
    return
  end

  local i = arg or 0

  if not arg then
    local mode = vim.api.nvim_get_mode().mode
    i = (mode == "i" or mode == "R") and 1 or 0
  end

  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

  local chr = vim.fn.matchstr(vim.fn.getline("."), ".", vim.fn.col(".") - i - 1)
  local paren = paren_info[chr]

  if paren == nil then
    return
  end

  -- Note:In insert mode, the character in front of the cursor is the target of the parenmatch.
  local vp = { vim.fn.line("."), vim.fn.col(".") - i } -- virtual position
  local ap -- actual position

  if i > 0 then
    ap = vim.fn.getcurpos()
    vim.fn.cursor(vp)
  end

  local pw = vim.fn.searchpairpos(paren.open, "", paren.closed, paren.flags, "", vim.fn.line(paren.stop), 10)

  if i > 0 then
    vim.fn.setpos(".", ap)
  end

  if pw[1] > 0 and vp[2] ~= 0 then
    vim.api.nvim_buf_add_highlight(0, namespace, "parenmatch", vp[1] - 1, vp[2] - 1, vp[2])
    vim.api.nvim_buf_add_highlight(0, namespace, "parenmatch", pw[1] - 1, pw[2] - 1, pw[2])
  end
end

function core.cursormoved()
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
      core.update()
    end)
  )
end

return core
