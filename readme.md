# vim-parenmatch

This project forked from [itchyny/vim-parenmatch](https://github.com/itchyny/vim-parenmatch).  
Lua script for Neovim and some options have been added.

## Options

With vim v9.0,

```vim
call parenmatch#setup_ignore_filetypes("help")
call parenmatch#setup_ignore_buftypes("nofile, popup")
```

With neovim v0.8,

```lua
require('parenmatch').setup({
  highlight = {fg = "#DDDDDD", underline = false},
  ignore_filetypes = {"TelescopePrompt", "cmp-menu", "help"},
  ignore_buftypes = {"nofile"}
})
```

### License

MIT Copyright (c) 2022 tar80
