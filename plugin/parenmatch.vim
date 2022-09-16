" =============================================================================
" Filename: plugin/parenmatch.vim
" Author: itchyny, tar80
" License: MIT License
" Last Change: 2022/09/10
" =============================================================================

if has('nvim') || exists('g:loaded_parenmatch') || v:version < 703 || !exists('*matchaddpos')
  finish
endif

let g:loaded_parenmatch = 1

let s:save_cpo = &cpo
set cpo&vim

augroup parenmatch
  autocmd!
  if has('vim_starting')
    autocmd VimEnter * call parenmatch#highlight() |
          \ call parenmatch#setup() |
          \ autocmd parenmatch WinEnter,BufEnter,BufWritePost <buffer> call parenmatch#update()
  else
    call parenmatch#highlight()
    call parenmatch#setup()
    autocmd WinEnter,BufEnter,BufWritePost <buffer> call parenmatch#update()
  endif
  autocmd ColorScheme * call parenmatch#highlight()
  autocmd CursorMoved,CursorMovedI * call parenmatch#cursormoved()
  autocmd InsertEnter * call parenmatch#update(1)
  autocmd InsertLeave * call parenmatch#update(0)
  autocmd WinEnter,BufWinEnter,FileType * call parenmatch#setup()
  autocmd OptionSet matchpairs call parenmatch#setup()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
