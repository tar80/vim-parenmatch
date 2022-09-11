--------------------------------------------------------------------------------
-- Filename: init.lua
-- Author: tar80
-- License: MIT License
-- Last Change: 2022/09/10
--------------------------------------------------------------------------------

if vim.g.loaded_parenmatch then
  return
end

vim.g.loaded_parenmatch = true

local core = require("parenmatch.core")

local parenmatch = {}
local options = {}
local defaults = {
  highlight = { underline = true },
  ignore_filetypes = {},
  ignore_buftypes = {},
}

function parenmatch.setup(opts)
  options = vim.tbl_deep_extend("force", options, opts or {})
  core.setup_highlight(options.highlight)
  core.load_matchpairs()

  if #options.ignore_filetypes > 0 then
    core.setup_ignore_filetypes(options.ignore_filetypes)
  end

  if #options.ignore_buftypes > 0 then
    core.setup_ignore_buftypes(options.ignore_buftypes)
  end
end

local augroup = vim.api.nvim_create_augroup("parenmatch", {})

local function autocmd_setup()

  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FileType" }, {
    group = augroup,
    pattern = "*",
    callback = function()
      core.load_matchpairs()
    end,
    desc = "Load matchpairs",
  })

  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "BufWritePost" }, {
    group = augroup,
    pattern = "*",
    callback = function()
      core.update()
    end,
    desc = "Update highlighting to matchpairs",
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    pattern = "*",
    callback = function()
      core.setup_highlight(options.highlight)
    end,
    desc = "Apply parenmatch highlight to colorscheme",
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    pattern = "*",
    callback = core.cursormoved,
    desc = "Update highlighting to matchpairs",
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = augroup,
    pattern = "matchpairs",
    callback = core.load_matchpairs,
    desc = "Load matchpairs",
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = augroup,
    pattern = "*",
    callback = function()
      core.update(1)
    end,
    desc = "Update highlighting to matchpairs",
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    pattern = "*",
    callback = function()
      core.update(0)
    end,
    desc = "Update highlighting to matchpairs",
  })
end

parenmatch.setup(defaults)

if vim.fn.has("vim_starting") == 1 then
  vim.api.nvim_create_autocmd("UIEnter", {
    group = augroup,
    pattern = "*",
    once = true,
    callback = function()
      autocmd_setup()
    end,
    desc = "Set parenmatch autocmd",
  })
else
  autocmd_setup()
end

defaults = nil
return parenmatch
