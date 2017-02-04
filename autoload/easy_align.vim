" Copyright (c) 2014 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists("g:loaded_easy_align")
  finish
endif
let g:loaded_easy_align = 1

let s:cpo_save = &cpo
set cpo&vim

let s:easy_align_delimiters_default = {
\  ' ': { 'pattern': ' ',  'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0 },
\  '=': { 'pattern': '===\|<=>\|\(&&\|||\|<<\|>>\)=\|=\~[#?]\?\|=>\|[:+/*!%^=><&|.?-]\?=[#?]\?',
\                          'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  ':': { 'pattern': ':',  'left_margin': 0, 'right_margin': 1, 'stick_to_left': 1 },
\  ',': { 'pattern': ',',  'left_margin': 0, 'right_margin': 1, 'stick_to_left': 1 },
\  '|': { 'pattern': '|',  'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  '.': { 'pattern': '\.', 'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0 },
\  '#': { 'pattern': '#\+', 'delimiter_align': 'l', 'ignore_groups': ['!Comment']  },
\  '"': { 'pattern': '"\+', 'delimiter_align': 'l', 'ignore_groups': ['!Comment']  },
\  '&': { 'pattern': '\\\@<!&\|\\\\',
\                          'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  '{': { 'pattern': '(\@<!{',
\                          'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  '}': { 'pattern': '}',  'left_margin': 1, 'right_margin': 0, 'stick_to_left': 0 }
\ }

let s:mode_labels = { 'l': '', 'r': '[R]', 'c': '[C]' }

let s:known_options = {
\ 'margin_left':   [0, 1], 'margin_right':     [0, 1], 'stick_to_left':   [0],
\ 'left_margin':   [0, 1], 'right_margin':     [0, 1], 'indentation':     [1],
\ 'ignore_groups': [3   ], 'ignore_unmatched': [0   ], 'delimiter_align': [1],
\ 'mode_sequence': [1   ], 'ignores':          [3],    'filter':          [1],
\ 'align':         [1   ]
\ }

let s:option_values = {
\ 'indentation':      ['shallow', 'deep', 'none', 'keep', -1],
\ 'delimiter_align':  ['left', 'center', 'right', -1],
\ 'ignore_unmatched': [0, 1, -1],
\ 'ignore_groups':    [[], ['String'], ['Comment'], ['String', 'Comment'], -1]
\ }

let s:shorthand = {
\ 'margin_left':   'lm', 'margin_right':     'rm', 'stick_to_left':   'stl',
\ 'left_margin':   'lm', 'right_margin':     'rm', 'indentation':     'idt',
\ 'ignore_groups': 'ig', 'ignore_unmatched': 'iu', 'delimiter_align': 'da',
\ 'mode_sequence': 'a',  'ignores':          'ig', 'filter':          'f',
\ 'align':         'a'
\ }

if exists("*strdisplaywidth")
  function! s:strwidth(str)
    return strdisplaywidth(a:str)
  endfunction
else
  function! s:strwidth(str)
    return len(split(a:str, '\zs')) + len(matchstr(a:str, '^\t*')) * (&tabstop - 1)
  endfunction
endif

function! s:ceil2(v)
  return a:v % 2 == 0 ? a:v : a:v + 1
endfunction

function! s:floor2(v)
  return a:v % 2 == 0 ? a:v : a:v - 1
endfunction

function! s:highlighted_as(line, col, groups)
  if empty(a:groups) | return 0 | endif
  let hl = synIDattr(synID(a:line, a:col, 0), 'name')
  for grp in a:groups
    if grp[0] == '!'
      if hl !~# grp[1:-1]
        return 1
      endif
    elseif hl =~# grp
      return 1
    endif
  endfor
  return 0
endfunction

function! s:ignored_syntax()
  if has('syntax') && exists('g:syntax_on')
    " Backward-compatibility
    return get(g:, 'easy_align_ignore_groups',
          \ get(g:, 'easy_align_ignores',
            \ (get(g:, 'easy_align_ignore_comment', 1) == 0) ?
              \ ['String'] : ['String', 'Comment']))
  else
    return []
  endif
endfunction

function! s:echon_(tokens)
  " http://vim.wikia.com/wiki/How_to_print_full_screen_width_messages
  let xy = [&ruler, &showcmd]
  try
    set noruler noshowcmd

    let winlen = winwidth(winnr()) - 2
    let len = len(join(map(copy(a:tokens), 'v:val[1]'), ''))
    let ellipsis = len > winlen ? '..' : ''

    echon "\r"
    let yet = 0
    for [hl, msg] in a:tokens
      if empty(msg) | continue | endif
      execute "echohl ". hl
      let yet += len(msg)
      if yet > winlen - len(ellipsis)
        echon msg[ 0 : (winlen - len(ellipsis) - yet - 1) ] . ellipsis
        break
      else
        echon msg
      endif
    endfor
  finally
    echohl None
    let [&ruler, &showcmd] = xy
  endtry
endfunction

function! s:echon(l, n, r, d, o, warn)
  let tokens = [
  \ ['Function', s:live ? ':LiveEasyAlign' : ':EasyAlign'],
  \ ['ModeMsg', get(s:mode_labels, a:l, a:l)],
  \ ['None', ' ']]

  if a:r == -1 | call add(tokens, ['Comment', '(']) | endif
  call add(tokens, [a:n =~ '*' ? 'Repeat' : 'Number', a:n])
  call extend(tokens, a:r == 1 ?
  \ [['Delimiter', '/'], ['String', a:d], ['Delimiter', '/']] :
  \ [['Identifier', a:d == ' ' ? '\ ' : (a:d == '\' ? '\\' : a:d)]])
  if a:r == -1 | call extend(tokens, [['Normal', '_'], ['Comment', ')']]) | endif
  call add(tokens, ['Statement', empty(a:o) ? '' : ' '.string(a:o)])
  if !empty(a:warn)
    call add(tokens, ['WarningMsg', ' ('.a:warn.')'])
  endif

  call s:echon_(tokens)
  return join(map(tokens, 'v:val[1]'), '')
endfunction

function! s:exit(msg)
  call s:echon_([['ErrorMsg', a:msg]])
  throw 'exit'
endfunction

function! s:ltrim(str)
  return substitute(a:str, '^\s\+', '', '')
endfunction

function! s:rtrim(str)
  return substitute(a:str, '\s\+$', '', '')
endfunction

function! s:trim(str)
  return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! s:fuzzy_lu(key)
  if has_key(s:known_options, a:key)
    return a:key
  endif
  let key = tolower(a:key)

  " stl -> ^s.*_t.*_l.*
  let regexp1 = '^' .key[0]. '.*' .substitute(key[1 : -1], '\(.\)', '_\1.*', 'g')
  let matches = filter(keys(s:known_options), 'v:val =~ regexp1')
  if len(matches) == 1
    return matches[0]
  endif

  " stl -> ^s.*t.*l.*
  let regexp2 = '^' . substitute(substitute(key, '-', '_', 'g'), '\(.\)', '\1.*', 'g')
  let matches = filter(keys(s:known_options), 'v:val =~ regexp2')

  if empty(matches)
    call s:exit("Unknown option key: ". a:key)
  elseif len(matches) == 1
    return matches[0]
  else
    " Avoid ambiguity introduced by deprecated margin_left and margin_right
    if sort(matches) == ['margin_left', 'margin_right', 'mode_sequence']
      return 'mode_sequence'
    endif
    if sort(matches) == ['ignore_groups', 'ignores']
      return 'ignore_groups'
    endif
    call s:exit("Ambiguous option key: ". a:key ." (" .join(matches, ', '). ")")
  endif
endfunction

function! s:shift(modes, cycle)
  let item = remove(a:modes, 0)
  if a:cycle || empty(a:modes)
    call add(a:modes, item)
  endif
  return item
endfunction

function! s:normalize_options(opts)
  let ret = {}
  for k in keys(a:opts)
    let v = a:opts[k]
    let k = s:fuzzy_lu(k)
    " Backward-compatibility
    if k == 'margin_left'   | let k = 'left_margin'    | endif
    if k == 'margin_right'  | let k = 'right_margin'   | endif
    if k == 'mode_sequence' | let k = 'align'          | endif
    let ret[k] = v
    unlet v
  endfor
  return s:validate_options(ret)
endfunction

function! s:compact_options(opts)
  let ret = {}
  for k in keys(a:opts)
    let ret[s:shorthand[k]] = a:opts[k]
  endfor
  return ret
endfunction

function! s:validate_options(opts)
  for k in keys(a:opts)
    let v = a:opts[k]
    if index(s:known_options[k], type(v)) == -1
      call s:exit("Invalid type for option: ". k)
    endif
    unlet v
  endfor
  return a:opts
endfunction

function! s:split_line(line, nth, modes, cycle, fc, lc, pattern, stick_to_left, ignore_unmatched, ignore_groups)
  let mode = ''

  let string = a:lc ?
    \ strpart(getline(a:line), a:fc - 1, a:lc - a:fc + 1) :
    \ strpart(getline(a:line), a:fc - 1)
  let idx     = 0
  let nomagic = match(a:pattern, '\\v') > match(a:pattern, '\C\\[mMV]')
  let pattern = '^.\{-}\s*\zs\('.a:pattern.(nomagic ? ')' : '\)')
  let tokens  = []
  let delims  = []

  " Phase 1: split
  let ignorable = 0
  let token = ''
  let phantom = 0
  while 1
    let matchidx = match(string, pattern, idx)
    " No match
    if matchidx < 0 | break | endif
    let matchend = matchend(string, pattern, idx)
    let spaces = matchstr(string, '\s'.(a:stick_to_left ? '*' : '\{-}'), matchend + (matchidx == matchend))

    " Match, but empty
    if len(spaces) + matchend - idx == 0
      let char = strpart(string, idx, 1)
      if empty(char) | break | endif
      let [match, part, delim] = [char, char, '']
    " Match
    else
      let match = strpart(string, idx, matchend - idx + len(spaces))
      let part  = strpart(string, idx, matchidx - idx)
      let delim = strpart(string, matchidx, matchend - matchidx)
    endif

    let ignorable = s:highlighted_as(a:line, idx + len(part) + a:fc, a:ignore_groups)
    if ignorable
      let token .= match
    else
      let [pmode, mode] = [mode, s:shift(a:modes, a:cycle)]
      call add(tokens, token . match)
      call add(delims, delim)
      let token = ''
    endif

    let idx += len(match)

    " If the string is non-empty and ends with the delimiter,
    " append an empty token to the list
    if idx == len(string)
      let phantom = 1
      break
    endif
  endwhile

  let leftover = token . strpart(string, idx)
  if !empty(leftover)
    let ignorable = s:highlighted_as(a:line, len(string) + a:fc - 1, a:ignore_groups)
    call add(tokens, leftover)
    call add(delims, '')
  elseif phantom
    call add(tokens, '')
    call add(delims, '')
  endif
  let [pmode, mode] = [mode, s:shift(a:modes, a:cycle)]

  " Preserve indentation - merge first two tokens
  if len(tokens) > 1 && empty(s:rtrim(tokens[0]))
    let tokens[1] = tokens[0] . tokens[1]
    call remove(tokens, 0)
    call remove(delims, 0)
    let mode = pmode
  endif

  " Skip comment line
  if ignorable && len(tokens) == 1 && a:ignore_unmatched
    let tokens = []
    let delims = []
  " Append an empty item to enable right/center alignment of the last token
  " - if the last token is not ignorable or ignorable but not the only token
  elseif a:ignore_unmatched != 1          &&
        \ (mode ==? 'r' || mode ==? 'c')  &&
        \ (!ignorable || len(tokens) > 1) &&
        \ a:nth >= 0 " includes -0
    call add(tokens, '')
    call add(delims, '')
  endif

  return [tokens, delims]
endfunction

function! s:do_align(todo, modes, all_tokens, all_delims, fl, ll, fc, lc, nth, recur, dict)
  let mode       = a:modes[0]
  let lines      = {}
  let min_indent = -1
  let max = { 'pivot_len2': 0, 'token_len': 0, 'just_len': 0, 'delim_len': 0,
        \ 'indent': 0, 'tokens': 0, 'strip_len': 0 }
  let d = a:dict
  let [f, fx] = s:parse_filter(d.filter)

  " Phase 1
  for line in range(a:fl, a:ll)
    let snip = a:lc > 0 ? getline(line)[a:fc-1 : a:lc-1] : getline(line)
    if f == 1 && snip !~ fx
      continue
    elseif f == -1 && snip =~ fx
      continue
    endif

    if !has_key(a:all_tokens, line)
      " Split line into the tokens by the delimiters
      let [tokens, delims] = s:split_line(
            \ line, a:nth, copy(a:modes), a:recur == 2,
            \ a:fc, a:lc, d.pattern,
            \ d.stick_to_left, d.ignore_unmatched, d.ignore_groups)

      " Remember tokens for subsequent recursive calls
      let a:all_tokens[line] = tokens
      let a:all_delims[line] = delims
    else
      let tokens = a:all_tokens[line]
      let delims = a:all_delims[line]
    endif

    " Skip empty lines
    if empty(tokens)
      continue
    endif

    " Calculate the maximum number of tokens for a line within the range
    let max.tokens = max([max.tokens, len(tokens)])

    if a:nth > 0 " Positive N-th
      if len(tokens) < a:nth
        continue
      endif
      let nth = a:nth - 1 " make it 0-based
    else " -0 or Negative N-th
      if a:nth == 0 && mode !=? 'l'
        let nth = len(tokens) - 1
      else
        let nth = len(tokens) + a:nth
      endif
      if empty(delims[len(delims) - 1])
        let nth -= 1
      endif

      if nth < 0 || nth == len(tokens)
        continue
      endif
    endif

    let prefix = nth > 0 ? join(tokens[0 : nth - 1], '') : ''
    let delim  = delims[nth]
    let token  = s:rtrim( tokens[nth] )
    let token  = s:rtrim( strpart(token, 0, len(token) - len(s:rtrim(delim))) )
    if empty(delim) && !exists('tokens[nth + 1]') && d.ignore_unmatched
      continue
    endif

    let indent = s:strwidth(matchstr(tokens[0], '^\s*'))
    if min_indent < 0 || indent < min_indent
      let min_indent  = indent
    endif
    if mode ==? 'c'
      let token .= substitute(matchstr(token, '^\s*'), '\t', repeat(' ', &tabstop), 'g')
    endif
    let [pw, tw] = [s:strwidth(prefix), s:strwidth(token)]
    let max.indent    = max([max.indent,    indent])
    let max.token_len = max([max.token_len, tw])
    let max.just_len  = max([max.just_len,  pw + tw])
    let max.delim_len = max([max.delim_len, s:strwidth(delim)])

    if mode ==? 'c'
      let pivot_len2 = pw * 2 + tw
      if max.pivot_len2 < pivot_len2
        let max.pivot_len2 = pivot_len2
      endif
      let max.strip_len = max([max.strip_len, s:strwidth(s:trim(token))])
    endif
    let lines[line]   = [nth, prefix, token, delim]
  endfor

  " Phase 1-5: indentation handling (only on a:nth == 1)
  if a:nth == 1
    let idt = d.indentation
    if idt ==? 'd'
      let indent = max.indent
    elseif idt ==? 's'
      let indent = min_indent
    elseif idt ==? 'n'
      let indent = 0
    elseif idt !=? 'k'
      call s:exit('Invalid indentation: ' . idt)
    end

    if idt !=? 'k'
      let max.just_len   = 0
      let max.token_len  = 0
      let max.pivot_len2 = 0

      for [line, elems] in items(lines)
        let [nth, prefix, token, delim] = elems

        let tindent = matchstr(token, '^\s*')
        while 1
          let len = s:strwidth(tindent)
          if len < indent
            let tindent .= repeat(' ', indent - len)
            break
          elseif len > indent
            let tindent = tindent[0 : -2]
          else
            break
          endif
        endwhile

        let token = tindent . s:ltrim(token)
        if mode ==? 'c'
          let token = substitute(token, '\s*$', repeat(' ', indent), '')
        endif
        let [pw, tw] = [s:strwidth(prefix), s:strwidth(token)]
        let max.token_len = max([max.token_len, tw])
        let max.just_len  = max([max.just_len,  pw + tw])
        if mode ==? 'c'
          let pivot_len2 = pw * 2 + tw
          if max.pivot_len2 < pivot_len2
            let max.pivot_len2 = pivot_len2
          endif
        endif

        let lines[line][2] = token
      endfor
    endif
  endif

  " Phase 2
  for [line, elems] in items(lines)
    let tokens = a:all_tokens[line]
    let delims = a:all_delims[line]
    let [nth, prefix, token, delim] = elems

    " Remove the leading whitespaces of the next token
    if len(tokens) > nth + 1
      let tokens[nth + 1] = s:ltrim(tokens[nth + 1])
    endif

    " Pad the token with spaces
    let [pw, tw] = [s:strwidth(prefix), s:strwidth(token)]
    let rpad = ''
    if mode ==? 'l'
      let pad = repeat(' ', max.just_len - pw - tw)
      if d.stick_to_left
        let rpad = pad
      else
        let token = token . pad
      endif
    elseif mode ==? 'r'
      let pad = repeat(' ', max.just_len - pw - tw)
      let indent = matchstr(token, '^\s*')
      let token = indent . pad . s:ltrim(token)
    elseif mode ==? 'c'
      let p1  = max.pivot_len2 - (pw * 2 + tw)
      let p2  = max.token_len - tw
      let pf1 = s:floor2(p1)
      if pf1 < p1 | let p2 = s:ceil2(p2)
      else        | let p2 = s:floor2(p2)
      endif
      let strip = s:ceil2(max.token_len - max.strip_len) / 2
      let indent = matchstr(token, '^\s*')
      let token = indent. repeat(' ', pf1 / 2) .s:ltrim(token). repeat(' ', p2 / 2)
      let token = substitute(token, repeat(' ', strip) . '$', '', '')

      if d.stick_to_left
        if empty(s:rtrim(token))
          let center = len(token) / 2
          let [token, rpad] = [strpart(token, 0, center), strpart(token, center)]
        else
          let [token, rpad] = [s:rtrim(token), matchstr(token, '\s*$')]
        endif
      endif
    endif
    let tokens[nth] = token

    " Pad the delimiter
    let dpadl = max.delim_len - s:strwidth(delim)
    let da = d.delimiter_align
    if da ==? 'l'
      let [dl, dr] = ['', repeat(' ', dpadl)]
    elseif da ==? 'c'
      let dl = repeat(' ', dpadl / 2)
      let dr = repeat(' ', dpadl - dpadl / 2)
    elseif da ==? 'r'
      let [dl, dr] = [repeat(' ', dpadl), '']
    else
      call s:exit('Invalid delimiter_align: ' . da)
    endif

    " Before and after the range (for blockwise visual mode)
    let cline  = getline(line)
    let before = strpart(cline, 0, a:fc - 1)
    let after  = a:lc ? strpart(cline, a:lc) : ''

    " Determine the left and right margin around the delimiter
    let rest   = join(tokens[nth + 1 : -1], '')
    let nomore = empty(rest.after)
    let ml     = (empty(prefix . token) || empty(delim) && nomore) ? '' : d.ml
    let mr     = nomore ? '' : d.mr

    " Adjust indentation of the lines starting with a delimiter
    let lpad = ''
    if nth == 0
      let ipad = repeat(' ', min_indent - s:strwidth(token.ml))
      if mode ==? 'l'
        let token = ipad . token
      else
        let lpad = ipad
      endif
    endif

    " Align the token
    let aligned = join([lpad, token, ml, dl, delim, dr, mr, rpad], '')
    let tokens[nth] = aligned

    " Update the line
    let a:todo[line] = before.join(tokens, '').after
  endfor

  if a:nth < max.tokens && (a:recur || len(a:modes) > 1)
    call s:shift(a:modes, a:recur == 2)
    return [a:todo, a:modes, a:all_tokens, a:all_delims,
          \ a:fl, a:ll, a:fc, a:lc, a:nth + 1, a:recur, a:dict]
  endif
  return [a:todo]
endfunction

function! s:input(str, default, vis)
  if a:vis
    normal! gv
    redraw
    execute "normal! \<esc>"
  else
    " EasyAlign command can be called without visual selection
    redraw
  endif
  let got = input(a:str, a:default)
  return got
endfunction

function! s:atoi(str)
  return (a:str =~ '^[0-9]\+$') ? str2nr(a:str) : a:str
endfunction

function! s:shift_opts(opts, key, vals)
  let val = s:shift(a:vals, 1)
  if type(val) == 0 && val == -1
    call remove(a:opts, a:key)
  else
    let a:opts[a:key] = val
  endif
endfunction

function! s:interactive(range, modes, n, d, opts, rules, vis, bvis)
  let mode = s:shift(a:modes, 1)
  let n    = a:n
  let d    = a:d
  let ch   = ''
  let opts = s:compact_options(a:opts)
  let vals = deepcopy(s:option_values)
  let regx = 0
  let warn = ''
  let undo = 0

  while 1
    " Live preview
    let rdrw = 0
    if undo
      silent! undo
      let undo = 0
      let rdrw = 1
    endif
    if s:live && !empty(d)
      let output = s:process(a:range, mode, n, d, s:normalize_options(opts), regx, a:rules, a:bvis)
      let &undolevels = &undolevels " Break undo block
      call s:update_lines(output.todo)
      let undo = !empty(output.todo)
      let rdrw = 1
    endif
    if rdrw
      if a:vis
        normal! gv
      endif
      redraw
      if a:vis | execute "normal! \<esc>" | endif
    endif
    call s:echon(mode, n, -1, regx ? '/'.d.'/' : d, opts, warn)

    let check = 0
    let warn = ''

    try
      let c = getchar()
    catch /^Vim:Interrupt$/
      let c = 27
    endtry
    let ch = nr2char(c)
    if c == 3 || c == 27 " CTRL-C / ESC
      if undo
        silent! undo
      endif
      throw 'exit'
    elseif c == "\<bs>"
      if !empty(d)
        let d = ''
        let regx = 0
      elseif len(n) > 0
        let n = strpart(n, 0, len(n) - 1)
      endif
    elseif c == 13 " Enter key
      let mode = s:shift(a:modes, 1)
      if has_key(opts, 'a')
        let opts.a = mode . strpart(opts.a, 1)
      endif
    elseif ch == '-'
      if empty(n)      | let n = '-'
      elseif n == '-'  | let n = ''
      else             | let check = 1
      endif
    elseif ch == '*'
      if empty(n)      | let n = '*'
      elseif n == '*'  | let n = '**'
      elseif n == '**' | let n = ''
      else             | let check = 1
      endif
    elseif empty(d) && ((c == 48 && len(n) > 0) || c > 48 && c <= 57) " Numbers
      if n[0] == '*'   | let check = 1
      else             | let n = n . ch
      end
    elseif ch == "\<C-D>"
      call s:shift_opts(opts, 'da', vals['delimiter_align'])
    elseif ch == "\<C-I>"
      call s:shift_opts(opts, 'idt', vals['indentation'])
    elseif ch == "\<C-L>"
      let lm = s:input("Left margin: ", get(opts, 'lm', ''), a:vis)
      if empty(lm)
        let warn = 'Set to default. Input 0 to remove it'
        silent! call remove(opts, 'lm')
      else
        let opts['lm'] = s:atoi(lm)
      endif
    elseif ch == "\<C-R>"
      let rm = s:input("Right margin: ", get(opts, 'rm', ''), a:vis)
      if empty(rm)
        let warn = 'Set to default. Input 0 to remove it'
        silent! call remove(opts, 'rm')
      else
        let opts['rm'] = s:atoi(rm)
      endif
    elseif ch == "\<C-U>"
      call s:shift_opts(opts, 'iu', vals['ignore_unmatched'])
    elseif ch == "\<C-G>"
      call s:shift_opts(opts, 'ig', vals['ignore_groups'])
    elseif ch == "\<C-P>"
      if s:live
        if !empty(d)
          let ch = d
          break
        else
          let s:live = 0
        endif
      else
        let s:live = 1
      endif
    elseif c == "\<Left>"
      let opts['stl'] = 1
      let opts['lm']  = 0
    elseif c == "\<Right>"
      let opts['stl'] = 0
      let opts['lm']  = 1
    elseif c == "\<Down>"
      let opts['lm']  = 0
      let opts['rm']  = 0
    elseif c == "\<Up>"
      silent! call remove(opts, 'stl')
      silent! call remove(opts, 'lm')
      silent! call remove(opts, 'rm')
    elseif ch == "\<C-A>" || ch == "\<C-O>"
      let modes = tolower(s:input("Alignment ([lrc...][[*]*]): ", get(opts, 'a', mode), a:vis))
      if match(modes, '^[lrc]\+\*\{0,2}$') != -1
        let opts['a'] = modes
        let mode      = modes[0]
        while mode != s:shift(a:modes, 1)
        endwhile
      else
        silent! call remove(opts, 'a')
      endif
    elseif ch == "\<C-_>" || ch == "\<C-X>"
      if s:live && regx && !empty(d)
        break
      endif

      let prompt = 'Regular expression: '
      let ch = s:input(prompt, '', a:vis)
      if !empty(ch) && s:valid_regexp(ch)
        let regx = 1
        let d = ch
        if !s:live | break | endif
      else
        let warn = 'Invalid regular expression: '.ch
      endif
    elseif ch == "\<C-F>"
      let f = s:input("Filter (g/../ or v/../): ", get(opts, 'f', ''), a:vis)
      let m = matchlist(f, '^[gv]/\(.\{-}\)/\?$')
      if empty(f)
        silent! call remove(opts, 'f')
      elseif !empty(m) && s:valid_regexp(m[1])
        let opts['f'] = f
      else
        let warn = 'Invalid filter expression'
      endif
    elseif ch =~ '[[:print:]]'
      let check = 1
    else
      let warn = 'Invalid character'
    endif

    if check
      if empty(d)
        if has_key(a:rules, ch)
          let d = ch
          if !s:live
            if a:vis
              execute "normal! gv\<esc>"
            endif
            break
          endif
        else
          let warn = 'Unknown delimiter key: '.ch
        endif
      else
        if regx
          let warn = 'Press <CTRL-X> to finish'
        else
          if d == ch
            break
          else
            let warn = 'Press '''.d.''' again to finish'
          endif
        end
      endif
    endif
  endwhile
  if s:live
    let copts = call('s:summarize', output.summarize)
    let s:live = 0
    let g:easy_align_last_command = s:echon('', n, regx, d, copts, '')
    let s:live = 1
  end
  return [mode, n, ch, opts, regx]
endfunction

function! s:valid_regexp(regexp)
  try
    call matchlist('', a:regexp)
  catch
    return 0
  endtry
  return 1
endfunction

function! s:test_regexp(regexp)
  let regexp = empty(a:regexp) ? @/ : a:regexp
  if !s:valid_regexp(regexp)
    call s:exit('Invalid regular expression: '. regexp)
  endif
  return regexp
endfunction

let s:shorthand_regex =
  \ '\s*\%('
  \   .'\(lm\?[0-9]\+\)\|\(rm\?[0-9]\+\)\|\(iu[01]\)\|\(\%(s\%(tl\)\?[01]\)\|[<>]\)\|'
  \   .'\(da\?[clr]\)\|\(\%(ms\?\|a\)[lrc*]\+\)\|\(i\%(dt\)\?[kdsn]\)\|\([gv]/.*/\)\|\(ig\[.*\]\)'
  \ .'\)\+\s*$'

function! s:parse_shorthand_opts(expr)
  let opts = {}
  let expr = substitute(a:expr, '\s', '', 'g')
  let regex = '^'. s:shorthand_regex

  if empty(expr)
    return opts
  elseif expr !~ regex
    call s:exit("Invalid expression: ". a:expr)
  else
    let match = matchlist(expr, regex)
    for m in filter(match[ 1 : -1 ], '!empty(v:val)')
      for key in ['lm', 'rm', 'l', 'r', 'stl', 's', '<', '>', 'iu', 'da', 'd', 'ms', 'm', 'ig', 'i', 'g', 'v', 'a']
        if stridx(tolower(m), key) == 0
          let rest = strpart(m, len(key))
          if key == 'i' | let key = 'idt' | endif
          if key == 'g' || key == 'v'
            let rest = key.rest
            let key = 'f'
          endif

          if key == 'idt' || index(['d', 'f', 'm', 'a'], key[0]) >= 0
            let opts[key] = rest
          elseif key == 'ig'
            try
              let arr = eval(rest)
              if type(arr) == 3
                let opts[key] = arr
              else
                throw 'Not an array'
              endif
            catch
              call s:exit("Invalid ignore_groups: ". a:expr)
            endtry
          elseif key =~ '[<>]'
            let opts['stl'] = key == '<'
          else
            let opts[key] = str2nr(rest)
          endif
          break
        endif
      endfor
    endfor
  endif
  return s:normalize_options(opts)
endfunction

function! s:parse_args(args)
  if empty(a:args)
    return ['', '', {}, 0]
  endif
  let n    = ''
  let ch   = ''
  let args = a:args
  let cand = ''
  let opts = {}

  " Poor man's option parser
  let idx = 0
  while 1
    let midx = match(args, '\s*{.*}\s*$', idx)
    if midx == -1 | break | endif

    let cand = strpart(args, midx)
    try
      let [l, r, c, k, s, d, n] = ['l', 'r', 'c', 'k', 's', 'd', 'n']
      let [L, R, C, K, S, D, N] = ['l', 'r', 'c', 'k', 's', 'd', 'n']
      let o = eval(cand)
      if type(o) == 4
        let opts = o
        if args[midx - 1 : midx] == '\ '
          let midx += 1
        endif
        let args = strpart(args, 0, midx)
        break
      endif
    catch
      " Ignore
    endtry
    let idx = midx + 1
  endwhile

  " Invalid option dictionary
  if len(substitute(cand, '\s', '', 'g')) > 2 && empty(opts)
    call s:exit("Invalid option: ". cand)
  else
    let opts = s:normalize_options(opts)
  endif

  " Shorthand option notation
  let sopts = matchstr(args, s:shorthand_regex)
  if !empty(sopts)
    let args = strpart(args, 0, len(args) - len(sopts))
    let opts = extend(s:parse_shorthand_opts(sopts), opts)
  endif

  " Has /Regexp/?
  let matches = matchlist(args, '^\(.\{-}\)\s*/\(.*\)/\s*$')

  " Found regexp
  if !empty(matches)
    return [matches[1], s:test_regexp(matches[2]), opts, 1]
  else
    let tokens = matchlist(args, '^\([1-9][0-9]*\|-[0-9]*\|\*\*\?\)\?\s*\(.\{-}\)\?$')
    " Try swapping n and ch
    let [n, ch] = empty(tokens[2]) ? reverse(tokens[1:2]) : tokens[1:2]

    " Resolving command-line ambiguity
    " '\ ' => ' '
    " '\'  => ' '
    if ch =~ '^\\\s*$'
      let ch = ' '
    " '\\' => '\'
    elseif ch =~ '^\\\\\s*$'
      let ch = '\'
    endif

    return [n, ch, opts, 0]
  endif
endfunction

function! s:parse_filter(f)
  let m = matchlist(a:f, '^\([gv]\)/\(.\{-}\)/\?$')
  if empty(m)
    return [0, '']
  else
    return [m[1] == 'g' ? 1 : -1, m[2]]
  endif
endfunction

function! s:interactive_modes(bang)
  return get(g:,
    \ (a:bang ? 'easy_align_bang_interactive_modes' : 'easy_align_interactive_modes'),
    \ (a:bang ? ['r', 'l', 'c'] : ['l', 'r', 'c']))
endfunction

function! s:alternating_modes(mode)
  return a:mode ==? 'r' ? 'rl' : 'lr'
endfunction

function! s:update_lines(todo)
  for [line, content] in items(a:todo)
    call setline(line, s:rtrim(content))
  endfor
endfunction

function! s:parse_nth(n)
  let n = a:n
  let recur = 0
  if n == '*'      | let [nth, recur] = [1, 1]
  elseif n == '**' | let [nth, recur] = [1, 2]
  elseif n == '-'  | let nth = -1
  elseif empty(n)  | let nth = 1
  elseif n == '0' || ( n != '-0' && n != string(str2nr(n)) )
    call s:exit('Invalid N-th parameter: '. n)
  else
    let nth = n
  endif
  return [nth, recur]
endfunction

function! s:build_dict(delimiters, ch, regexp, opts)
  if a:regexp
    let dict = { 'pattern': a:ch }
  else
    if !has_key(a:delimiters, a:ch)
      call s:exit('Unknown delimiter key: '. a:ch)
    endif
    let dict = copy(a:delimiters[a:ch])
  endif
  call extend(dict, a:opts)

  let ml = get(dict, 'left_margin', ' ')
  let mr = get(dict, 'right_margin', ' ')
  if type(ml) == 0 | let ml = repeat(' ', ml) | endif
  if type(mr) == 0 | let mr = repeat(' ', mr) | endif
  call extend(dict, { 'ml': ml, 'mr': mr })

  let dict.pattern = get(dict, 'pattern', a:ch)
  let dict.delimiter_align =
    \ get(dict, 'delimiter_align', get(g:, 'easy_align_delimiter_align', 'r'))[0]
  let dict.indentation =
    \ get(dict, 'indentation', get(g:, 'easy_align_indentation', 'k'))[0]
  let dict.stick_to_left =
    \ get(dict, 'stick_to_left', 0)
  let dict.ignore_unmatched =
    \ get(dict, 'ignore_unmatched', get(g:, 'easy_align_ignore_unmatched', 2))
  let dict.ignore_groups =
    \ get(dict, 'ignore_groups', get(dict, 'ignores', s:ignored_syntax()))
  let dict.filter =
    \ get(dict, 'filter', '')
  return dict
endfunction

function! s:build_mode_sequence(expr, recur)
  let [expr, recur] = [a:expr, a:recur]
  let suffix = matchstr(a:expr, '\*\+$')
  if suffix == '*'
    let expr = expr[0 : -2]
    let recur = 1
  elseif suffix == '**'
    let expr = expr[0 : -3]
    let recur = 2
  endif
  return [tolower(expr), recur]
endfunction

function! s:process(range, mode, n, ch, opts, regexp, rules, bvis)
  let [nth, recur] = s:parse_nth((empty(a:n) && exists('g:easy_align_nth')) ? g:easy_align_nth : a:n)
  let dict = s:build_dict(a:rules, a:ch, a:regexp, a:opts)
  let [mode_sequence, recur] = s:build_mode_sequence(
    \ get(dict, 'align', recur == 2 ? s:alternating_modes(a:mode) : a:mode),
    \ recur)

  let ve = &virtualedit
  set ve=all
  let args = [
    \ {}, split(mode_sequence, '\zs'),
    \ {}, {}, a:range[0], a:range[1],
    \ a:bvis             ? min([virtcol("'<"), virtcol("'>")]) : 1,
    \ (!recur && a:bvis) ? max([virtcol("'<"), virtcol("'>")]) : 0,
    \ nth, recur, dict ]
  let &ve = ve
  while len(args) > 1
    let args = call('s:do_align', args)
  endwhile

  " todo: lines to update
  " summarize: arguments to s:summarize
  return { 'todo': args[0], 'summarize': [ a:opts, recur, mode_sequence ] }
endfunction

function s:summarize(opts, recur, mode_sequence)
  let copts = s:compact_options(a:opts)
  let nbmode = s:interactive_modes(0)[0]
  if !has_key(copts, 'a') && (
    \  (a:recur == 2 && s:alternating_modes(nbmode) != a:mode_sequence) ||
    \  (a:recur != 2 && (a:mode_sequence[0] != nbmode || len(a:mode_sequence) > 1))
    \ )
    call extend(copts, { 'a': a:mode_sequence })
  endif
  return copts
endfunction

function! s:align(bang, live, visualmode, first_line, last_line, expr)
  " Heuristically determine if the user was in visual mode
  if empty(a:visualmode)
    let vis  = a:first_line == line("'<") && a:last_line == line("'>")
    let bvis = vis && visualmode() == "\<C-V>"
  " Visual-mode explicitly given
  else
    let vis  = 1
    let bvis = a:visualmode == "\<C-V>"
  end
  let range = [a:first_line, a:last_line]
  let modes = s:interactive_modes(a:bang)
  let mode  = modes[0]
  let s:live = a:live

  let rules = s:easy_align_delimiters_default
  if exists('g:easy_align_delimiters')
    let rules = extend(copy(rules), g:easy_align_delimiters)
  endif

  let [n, ch, opts, regexp] = s:parse_args(a:expr)

  let bypass_fold = get(g:, 'easy_align_bypass_fold', 0)
  let ofm = &l:foldmethod
  try
    if bypass_fold | let &l:foldmethod = 'manual' | endif

    if empty(n) && empty(ch) || s:live
      let [mode, n, ch, opts, regexp] = s:interactive(range, copy(modes), n, ch, opts, rules, vis, bvis)
    endif

    if !s:live
      let output = s:process(range, mode, n, ch, s:normalize_options(opts), regexp, rules, bvis)
      call s:update_lines(output.todo)
      let copts = call('s:summarize', output.summarize)
      let g:easy_align_last_command = s:echon('', n, regexp, ch, copts, '')
    endif
  finally
    if bypass_fold | let &l:foldmethod = ofm | endif
  endtry
endfunction

function! easy_align#align(bang, live, visualmode, expr) range
  try
    call s:align(a:bang, a:live, a:visualmode, a:firstline, a:lastline, a:expr)
  catch /^\%(Vim:Interrupt\|exit\)$/
    if empty(a:visualmode)
      echon "\r"
      echon "\r"
    else
      normal! gv
    endif
  endtry
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

