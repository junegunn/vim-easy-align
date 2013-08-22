e!

function! GFM()
  let syntaxes = {
  \ 'ruby':   'syntax/ruby.vim',
  \ 'yaml':   'syntax/yaml.vim',
  \ 'vim':    'syntax/vim.vim',
  \ 'sh':     'syntax/sh.vim',
  \ 'python': 'syntax/python.vim',
  \ 'java':   'syntax/java.vim',
  \ 'c':      'syntax/c.vim'
  \ }

  for [lang, syn] in items(syntaxes)
    unlet b:current_syntax
    silent! exec printf("syntax include @%s %s", lang, syn)
    exec printf("syntax region %sSnip matchgroup=Snip start='```%s' end='```' contains=@%s",
                \ lang, lang, lang)
  endfor
  let b:current_syntax='mkd'

  syntax sync fromstart
endfunction

silent! unlet g:easy_align_delimiters
silent! unlet g:easy_align_ignore_unmatched
silent! unlet g:easy_align_ignores

vnoremap <silent> <Enter> :EasyAlign<cr>

noremap  <silent> <C-k> <nop>
noremap  <silent> <C-j> <nop>
noremap  <silent> <C-h> <nop>
noremap  <silent> <C-l> <nop>
vnoremap <silent> <C-k> <nop>
vnoremap <silent> <C-j> <nop>
vnoremap <silent> <C-h> <nop>
vnoremap <silent> <C-l> <nop>

set nolazyredraw
set buftype=nofile
set colorcolumn=

silent! ScrollPositionHide

call GFM()

normal gg
let @b=system('cat '. expand('%:p:r') . '.script')
let @a='@b:vert diffsplit ' . expand('%:p:r') . '.expected'
" Syntax highlighting doesn't work if we do @a here
