" =============================================================================
" Filename: autoload/parenmatch.vim
" Author: itchyny, tar80
" License: MIT License
" Last Change: 2022/09/11
" =============================================================================

if has('nvim') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let s:ignore_filetypes = {}
function! parenmatch#setup_ignore_filetypes(...) abort
  if a:0 == 0 | echo "Parenmatch: Arguments required. Please specify filetypes." | return | endif
  let s:ignore_filetypes = a:000
  augroup parenmatchIgnore
    autocmd! Filetype
    autocmd FileType * call s:filetype_ignore()
  augroup End
endfunction

let s:ignore_buftypes = {}
function! parenmatch#setup_ignore_buftypes(...) abort
  if a:0 == 0 | echo "Parenmatch: Arguments required. Please specify filetypes." | return | endif
  let s:ignore_buftypes = a:000
  augroup parenmatchIgnore
    autocmd! BufEnter
    if has('timers')
      autocmd BufEnter * let timer = timer_start(10, 's:buftype_ignore')
    else
      autocmd BufEnter * call s:buftype_ignore(v:null)
    endif
  augroup End
endfunction

function! s:filetype_ignore() abort
  if &l:filetype == "" | return | endif
  let b:parenmatch = match(s:ignore_filetypes, &l:filetype) == -1
endfunction

function! s:buftype_ignore(timer) abort
  if &l:buftype == "" || (exists("b:parenmatch") && b:parenmatch == 0) | return | endif
  if match(s:ignore_buftypes, &l:buftype) != -1 | let b:parenmatch = 0  | endif
endfunction

function! parenmatch#highlight() abort
  if !get(g:, 'parenmatch_highlight', 1) | return | endif
  highlight ParenMatch term=underline cterm=underline gui=underline
endfunction

let s:paren = {}
function! parenmatch#update(...) abort
  if !get(b:, 'parenmatch', get(g:, 'parenmatch', 1)) | return | endif
  let i = a:0 ? a:1 : mode() ==# 'i' || mode() ==# 'R'
  let c = matchstr(getline('.'), '.', col('.') - i - 1)
  if get(w:, 'parenmatch')
    silent! call matchdelete(w:parenmatch)
  endif
  if !has_key(s:paren, c) | return | endif
  let [open, closed, flags, stop] = s:paren[c]
  let q = [line('.'), col('.') - i]
  if i | let p = getcurpos() | call cursor(q) | endif
  let r = searchpairpos(open, '', closed, flags, '', line(stop), 10)
  if i | call setpos('.', p) | endif
  if r[0] > 0 | let w:parenmatch = matchaddpos('ParenMatch', [q, r]) | endif
endfunction

let s:matchpairs = ''
function! parenmatch#setup() abort
  if s:matchpairs ==# &l:matchpairs
    return
  endif
  let s:matchpairs = &l:matchpairs
  let s:paren = {}
  for [open, closed] in map(split(&l:matchpairs, ','), 'split(v:val, ":")')
    let open_ = stridx(open, '[]') ? escape(open, '[]') : open
    let closed_ = stridx(closed, '[]') ? escape(closed, '[]') : closed
    let s:paren[open] = [ open_, closed_, 'nW', 'w$' ]
    let s:paren[closed] = [ open_, closed_, 'bnW', 'w0' ]
  endfor
endfunction

if has('timers')
  let s:timer = 0
  function! parenmatch#cursormoved() abort
    if get(w:, 'parenmatch')
      silent! call matchdelete(w:parenmatch)
      let w:parenmatch = 0
    endif
    call timer_stop(s:timer)
    let s:timer = timer_start(50, 's:lazy_update')
  endfunction
  function! s:lazy_update(...) abort
    call parenmatch#update()
  endfunction
else
  function! parenmatch#cursormoved() abort
    call parenmatch#update()
  endfunction
endif

let &cpo = s:save_cpo
unlet s:save_cpo
