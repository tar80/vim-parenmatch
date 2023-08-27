# vim-parenmatch

This project forked from [itchyny/vim-parenmatch](https://github.com/itchyny/vim-parenmatch).  
Lua script for Neovim and some options have been added.

## Options

With vim v9.0,

```vim
call parenmatch#setup_ignore_filetypes("help")
call parenmatch#setup_ignore_buftypes("nofile, popup")
```

With neovim v0.10,

~~"parenmatch.setup()" is deprecated.I'll delete it soon.~~  
leave the parenmatch.setup()

```lua
require('parenmatch.config').setup({
  highlight = {fg = "#DDDDDD", underline = false},
  ignore_filetypes = {"TelescopePrompt", "cmp-menu", "help"},
  ignore_buftypes = {"nofile"}

  --[[
  -- itmatch is a low-cost, low-performance version of matchit. use treesitter-node
  -- table format of itmatch.matcher:
  -- <filetype> = {
  --    s = { Keywords that are the starting point of a match },
  --    e = { Keywords that are the end point of a match }
  -- }
  ]]
  itmatch = {
    enable = true,
    matcher = {
        lua = { s = { 'function', 'if', 'while', 'repeat', 'for', 'do' }, e = { 'end', 'until' } },
        vim = {
            s = { [=[\<fu\%[nction]\>]=], 'if', [=[<\wh\%[ile]\>]=], 'for', 'try' },
            e = {
                [=[\<en\%[dif]\>]=],
                [=[\<endfor\?\>]=],
                [=[\<endf\%[unction]\>]=],
                [=[\<endw\%[hile]\>]=],
                [=[\<endt\%[ry]\>]=],
            },
        },
    }
})

```

### Usage

Stop highlighting parentheses.

```lua:
" all buffers
let g:parenmatch_disable = v:true

" current buffer
let b:parenmatch_disable = v:true
```

### Itmatch for neovim

Itmatch overrides and replaces "%" key. Only works if there is a specific keyword under the cursor, otherwise the standard behavior of the "%" key is used.  
Itmatch only references treesitter-node. Therefore, accurate positioning may not be possible.

### Credit

[itchyny/vim-parenmatch](https://github.com/itchyny/vim-parenmatch)
