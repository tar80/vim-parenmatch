---@module "config"
local M = {}

local TITLE = '[parenmatch] '


---@param opts Parenmatch existing elements
---@param addition table additional elements
---@return Parenmatch # new table
local function tbl_append(opts, addition)
  if type(opts) ~= 'table' or type(addition) ~= 'table' then
    vim.notify(TITLE .. 'Each arguments must be a table', 3)
  end

  for _, v in ipairs(addition) do
    if not vim.tbl_contains(opts, v) then
      vim.list_extend(opts, { v })
    end
  end

  return opts
end

---@param opts Parenmatch Optional custom settings
function M.setup(opts)
  if not opts then
    return vim.notify(TITLE .. 'Requires arguments', 3)
  end

  if opts.ignore_filetypes then
    _G.Parenmatch.ignore_filetypes = tbl_append(_G.Parenmatch.ignore_filetypes, opts.ignore_filetypes)

    vim.api.nvim_create_autocmd('FileType', {
      group = 'parenmatch',
      pattern = '*',
      callback = function()
        if vim.b.parenmatch_disable then
          return
        end

        if not vim.tbl_isempty(_G.Parenmatch.ignore_filetypes) then
          _G.Parenmatch:buf_disable('filetype')
        end
      end,
      desc = 'Ignore filetypes',
    })
  end

  if opts.ignore_buftypes then
    _G.Parenmatch.ignore_buftypes = tbl_append(_G.Parenmatch.ignore_buftypes, opts.ignore_buftypes)

    vim.api.nvim_create_autocmd('BufEnter', {
      group = 'parenmatch',
      pattern = '*',
      callback = function()
        local timer = vim.uv.new_timer()
        timer:start(
          10,
          0,
          vim.schedule_wrap(function()
            if vim.b.parenmatch_disable or Parenmatch.ignore_buftypes == {} then
              return
            end

            _G.Parenmatch:buf_disable('buftype')
          end)
        )
      end,
      desc = 'Ignore buftypes',
    })
  end

  if opts.highlight then
    _G.Parenmatch.highlight = opts.highlight
    _G.Parenmatch.set_hl()
  end

  if opts.itmatch.enable then
    local itmatch = require('parenmatch.itmatch')

    if opts.itmatch.matcher then
      itmatch.setup(opts.itmatch.matcher, tbl_append)
    end
  end
end

return M
