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

local augroup = vim.api.nvim_create_augroup("parenmatch", {})
local id_ignore_filetype = 0
local id_ignore_buftype = 0

function parenmatch.setup(opts)
  options = vim.tbl_deep_extend("force", options, opts or {})
  core.setup_highlight(options.highlight)
  core.load_matchpairs()

  if #options.ignore_filetypes > 0 then
    if id_ignore_filetype ~= 0 then
      vim.api.nvim_del_autocmd(id_ignore_filetype)
    end

    id_ignore_filetype = vim.api.nvim_create_autocmd("FileType", {
      group = "parenmatch",
      pattern = "*",
      callback = function()
        core.buf_disable(options.ignore_filetypes, "filetype")
      end,
      desc = "Ignore filetypes",
    })
  end

  if #options.ignore_buftypes > 0 then
    if id_ignore_buftype ~= 0 then
      vim.api.nvim_del_autocmd(id_ignore_buftype)
    end

    id_ignore_buftype = vim.api.nvim_create_autocmd("BufEnter", {
      group = "parenmatch",
      pattern = "*",
      callback = function()
        local timer_ = vim.loop.new_timer()
        timer_:start(
          10,
          0,
          vim.schedule_wrap(function()
            if vim.b.parenmatch then
              return
            end

            core.buf_disable(options.ignore_buftypes, "buftype")
          end)
        )
      end,
      desc = "Ignore buftypes",
    })
  end
end

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
    buffer = 0,
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
