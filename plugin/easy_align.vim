if exists("g:easy_align_plugin_loaded")
  finish
endif
let g:easy_align_plugin_loaded = 1

command! -nargs=* -range EasyAlign <line1>,<line2>call easy_align#align(<f-args>)
