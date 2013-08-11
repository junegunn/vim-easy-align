e!
execute 'source '. expand('%:p:h') . '/include.vim'

normal gg
let @b=system('cat '. expand('%:p:r') . '.script')
let @a='@b:vert diffsplit ' . expand('%:p:r') . '.expected'
" Syntax highlighting doesn't work if we do @a here
