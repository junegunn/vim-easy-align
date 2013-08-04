source include.vim

while line('.') < line('$')
  normal 30j
  redraw
endwhile

normal gg
let @b=system('cat '. expand('%:r') . '.script')
let @a='@b:vert diffsplit ' . expand('%:r') . '.expected'
" Syntax highlighting doesn't work
echo "Press @a"
