" =============================================================================
" Filename: plugin/parenmatch.vim
" Author: itchyny, tar80
" License: MIT License
" Last Change: 2022/09/10
" =============================================================================

if exists('g:loaded_parenmatch') || v:version < 703 || !exists('*matchaddpos')
  finish
endif

let g:loaded_parenmatch = 1

let s:save_cpo = &cpo
set cpo&vim

let s:nvim = has('nvim')
let s:func = {
  \ '0': {
    \ 'highlight': 'call parenmatch#highlight',
    \ 'setup': 'call parenmatch#setup',
    \ 'update': 'call parenmatch#update',
    \ 'cursormoved': 'call parenmatch#cursormoved',
    \ },
  \ '1': {
    \ 'highlight': 'lua _G.Parenmatch:set_hl',
    \ 'setup': 'lua _G.Parenmatch.matchpairs',
    \ 'update': 'lua _G.Parenmatch:update',
    \ 'cursormoved': 'lua _G.Parenmatch:cursormoved',
    \ },
  \ }[s:nvim]

if s:nvim
  lua require('parenmatch')
endif

augroup parenmatch
  autocmd!
  if has('vim_starting')
    execute printf("autocmd VimEnter * %s() |
          \ %s() |
          \ autocmd parenmatch WinEnter,BufEnter,BufWritePost <buffer> %s()", s:func.highlight, s:func.setup, s:func.update)
  else
    if s:nvim == 0
      execute printf("%s()", s:func.highlight)
      execute printf("%s()", s:func.setup)
    endif

    execut printf("autocmd WinEnter,BufEnter,BufWritePost <buffer> %s()", s:func.update)
  endif

  execute printf("autocmd ColorScheme * %s()", s:func.highlight)
  execute printf("autocmd CursorMoved,CursorMovedI * %s()", s:func.cursormoved)
  execute printf("autocmd InsertEnter * %s(1)", s:func.update)
  execute printf("autocmd InsertLeave * %s(0)", s:func.update)
  execute printf("autocmd WinEnter,BufWinEnter,FileType * %s()", s:func.setup)
  execute printf("autocmd OptionSet matchpairs %s()", s:func.setup)
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
unlet s:func
unlet s:nvim
