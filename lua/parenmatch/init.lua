--------------------------------------------------------------------------------
-- Filename: init.lua
-- Author: tar80
-- License: MIT License
--------------------------------------------------------------------------------

if vim.g.loaded_parenmatch then
  return
end

vim.g.loaded_parenmatch = true

---@class Parenmatch
---@field ignore_filetypes table
---@field ignore_buftypes table
_G.Parenmatch = {}

local config = require("parenmatch.config")
local core = require("parenmatch.core")

local pm = {}
local default_highlight = { underline = true }

---@param opts any user configration
function pm.setup(opts)
  config.set_options(opts)
end

local augroup = vim.api.nvim_create_augroup("parenmatch", {})

local function autocmd_setup()
  -- reset augroup
    augroup = vim.api.nvim_create_augroup("parenmatch", {})

    vim.api.nvim_create_autocmd("FileType", {
      group = augroup,
      pattern = "*",
      callback = function()
        if vim.b.parenmatch_disable then
          return
  end

        if Parenmatch.ignore_filetypes ~= {} then
          core.buf_disable(Parenmatch.ignore_filetypes, "filetype")
    end

        -- if not vim.b.parenmatch_disable then
          --todo:add function filetype 
        -- end
      end,
      desc = "Ignore filetypes",
    })
    vim.api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      pattern = "*",
      callback = function()
        local timer_ = vim.loop.new_timer()
        timer_:start(
          10,
          0,
          vim.schedule_wrap(function()
            if vim.b.parenmatch_disable or Parenmatch.ignore_buftypes == {} then
              return
            end

            core.buf_disable(Parenmatch.ignore_buftypes, "buftype")
          end)
        )
      end,
      desc = "Ignore buftypes",
    })
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
      core.setup_highlight(default_highlight)
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

core.load_matchpairs()

return pm
