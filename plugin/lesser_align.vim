if exists("g:lesser_align_plugin_loaded")
  finish
endif
let g:lesser_align_plugin_loaded = 1

command! -nargs=0 -range LesserAlign <line1>,<line2>call lesser_align#align()
