---@module "config"
local M = {}

local TITLE = "[parenmatch] "

---@param tbl table existing elements
---@param addition table additional elements
---@return table # new table
local function tbl_append(tbl, addition)
  if type(tbl) ~= "table" or type(addition) ~= "table" then
    vim.notify(TITLE .. "Each arguments must be a table", 3)
  end

  for _, v in ipairs(addition) do
    if not vim.tbl_contains(tbl, v) then
      vim.list_extend(tbl, { v })
    end
  end

  return tbl
end

---@package
-- default settings
local function set_default()
  _G.Parenmatch.ignore_filetypes = {}
  _G.Parenmatch.ignore_buftypes = {}
end

---@package
---@alias T table optional user settings
---@param opts T
function M.set_options(opts)
  if not opts then
    return vim.notify(TITLE .. "Requires arguments", 3)
  end

  if opts.ignore_filetypes then
    _G.Parenmatch.ignore_filetypes = tbl_append(_G.Parenmatch.ignore_filetypes, opts.ignore_filetypes)
  end

  if opts.ignore_buftypes then
    _G.Parenmatch.ignore_buftypes = tbl_append(_G.Parenmatch.ignore_buftypes, opts.ignore_buftypes)
  end

  if opts.highlight then
    require("parenmatch.core").setup_highlight(opts.highlight)
  end
end

if not _G.Parenmatch.ignore_filetypes then
  set_default()
end

return M
