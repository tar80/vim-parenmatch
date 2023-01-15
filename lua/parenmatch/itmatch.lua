--------------------------------------------------------------------------------
-- Filename: itmatch.lua
-- Author: tar80
-- License: MIT License
--------------------------------------------------------------------------------

---@module "itmatch"
local itmatch = {}
local matcher = {}

if type(package.loaded["nvim-treesitter"]) ~= "table" then
  return vim.notify("[itmatch] Treesitter not loaded", 3)
end

---@package
---define which meta-table in tsnode to use
local function expand_tskey()
  local ft = vim.bo.filetype
  local contents = matcher[ft]
  local results = {}

  if not contents then
    return false
  end

  for k, v in pairs(contents) do
    if k == "s" then
      vim.tbl_map(function(key)
        results[key] = "end_"
      end, v)
    elseif k == "e" then
      vim.tbl_map(function(key)
        results[key] = "start"
      end, v)
    end
  end

  return results
end

---@package
---move cursor to match keyword
local function cursor_to_match()
  local focus_target = expand_tskey() or {}
  local cword = vim.fn.expand("<cword>")
  local mt = focus_target[cword:lower()]

  if not mt then
    vim.fn.feedkeys("%", "n")
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local ts = vim.treesitter
  local node = ts.get_node_at_pos(0, row - 1, col, {})
  local pair_row, pair_col = node[mt](node)

  if mt == "start" then
    pair_col = pair_col + 1
  end

  vim.fn.cursor(pair_row + 1, pair_col)

  if mt == "start" and not vim.tbl_contains(vim.tbl_keys(focus_target), vim.fn.expand("<cword>")) then
    vim.fn.feedkeys("w", "n")
  end
end

---@package
---matching keywords for each filetype
local function set_default()
  matcher = {
    lua = { s = { "function", "if", "while", "repeat", "for", "do" }, e = { "end", "until" } },
    vim = {
      s = { "function", "fu", "if", "while", "wh", "for", "try" },
      e = { "endfunction", "endf", "endif", "en", "endwhile", "endw", "endfor", "endfo", "endtry", "endt" },
    },
  }
end

---@param opts table user configration
---@param append function `config.tbl_append(base_tbl, addition_tbl)`
itmatch.setup = function(opts, append)
  if not opts then
    return set_default()
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
  print(vim.inspect(matcher))
end

set_default()

vim.keymap.set({"n", "v"}, "%", function()
  cursor_to_match()
end, { silent = true })

return itmatch
