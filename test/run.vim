e!
execute 'source '. expand('%:p:h') . '/include.vim'

while line('.') < line('$')
  normal 30j
  redraw
endwhile

normal gg
let @b=system('cat '. expand('%:p:r') . '.script')
let @a='@b:vert diffsplit ' . expand('%:p:r') . '.expected'
" Syntax highlighting doesn't work
echo "Press @a"
