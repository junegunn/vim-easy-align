" Copyright (c) 2013 Junegunn Choi
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

let s:easy_align_delimiters_default = {
\  ' ': { 'pattern': ' ',  'left_margin': '',  'right_margin': '',  'stick_to_left': 0 },
\  '=': { 'pattern': '===\|<=>\|\(&&\|||\|<<\|>>\)=\|=\~\|=>\|[:+/*!%^=><&|-]\?=[#?]\?',
\                          'left_margin': ' ', 'right_margin': ' ', 'stick_to_left': 0 },
\  ':': { 'pattern': ':',  'left_margin': '',  'right_margin': ' ', 'stick_to_left': 1 },
\  ',': { 'pattern': ',',  'left_margin': '',  'right_margin': ' ', 'stick_to_left': 1 },
\  '|': { 'pattern': '|',  'left_margin': ' ', 'right_margin': ' ', 'stick_to_left': 0 },
\  '.': { 'pattern': '\.', 'left_margin': '',  'right_margin': '',  'stick_to_left': 0 },
\  '{': { 'pattern': '(\@<!{',
\                          'left_margin': ' ', 'right_margin': ' ', 'stick_to_left': 0 },
\  '}': { 'pattern': '}',  'left_margin': ' ', 'right_margin': '',  'stick_to_left': 0 }
\ }

let s:just = ['', '[R]']

let s:known_options = {
\ 'margin_left': [0, 1], 'margin_right': [0, 1], 'stick_to_left': [0],
\ 'left_margin': [0, 1], 'right_margin': [0, 1],
\ 'ignores': [3], 'ignore_unmatched': [0]
\ }

if exists("*strwidth")
  function! s:strwidth(str)
    return strwidth(a:str)
  endfunction
else
  function! s:strwidth(str)
    return len(split(a:str, '\zs'))
  endfunction
endif

function! s:highlighted_as(line, col, groups)
  if empty(a:groups) | return 0 | endif
  let hl = synIDattr(synID(a:line, a:col, 0), 'name')
  for grp in a:groups
    if hl =~# grp
      return 1
    endif
  endfor
  return 0
endfunction

function! s:ignored_syntax()
  if has('syntax') && exists('g:syntax_on')
    " Backward-compatibility
    return get(g:, 'easy_align_ignores',
          \ (get(g:, 'easy_align_ignore_comment', 1) == 0) ?
            \ ['String'] : ['String', 'Comment'])
  else
    return []
  endif
endfunction

function! s:echon(l, n, d)
  echon "\r"
  echon "\rEasyAlign". s:just[a:l] ." (" .a:n.a:d. ")"
endfunction

function! s:exit(msg)
  echon "\r". a:msg
  throw 'exit'
endfunction

function! s:ltrim(str)
  return substitute(a:str, '^\s*', '', '')
endfunction

function! s:rtrim(str)
  return substitute(a:str, '\s*$', '', '')
endfunction

function! s:fuzzy_lu(key)
  if has_key(s:known_options, a:key)
    return a:key
  endif

  let regexp  = '^' . substitute(substitute(a:key, '-', '_', 'g'), '\(.\)', '\1.*', 'g')
  let matches = filter(keys(s:known_options), 'v:val =~ regexp')

  if empty(matches)
    call s:exit("Unknown option key: ". a:key)
  elseif len(matches) == 1
    return matches[0]
  else
    call s:exit("Ambiguous option key: ". a:key ." (" .join(matches, ', '). ")")
  endif
endfunction

function! s:normalize_options(opts)
  let ret = {}
  for k in keys(a:opts)
    let v = a:opts[k]
    let k = s:fuzzy_lu(k)
    " Backward-compatibility
    if k == 'margin_left'  | let k = 'left_margin'  | endif
    if k == 'margin_right' | let k = 'right_margin' | endif
    let ret[k] = v
    unlet v
  endfor
  return s:validate_options(ret)
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

function! s:do_align(just, all_tokens, fl, ll, fc, lc, pattern, nth, ml, mr, stick_to_left, ignore_unmatched, ignores, recursive)
  let lines          = {}
  let max_just_len   = 0
  let max_delim_len  = 0
  let max_tokens     = 0
  let min_indent     = -1
  let pattern        = '\s*\(' .a:pattern. '\)\s' . (a:stick_to_left ? '*' : '\{-}')

  " Phase 1
  for line in range(a:fl, a:ll)
    if !has_key(a:all_tokens, line)
      " Split line into the tokens by the delimiters
      let raw_tokens = split(a:lc ?
                        \ strpart(getline(line), a:fc - 1, a:lc - a:fc + 1) :
                        \ strpart(getline(line), a:fc - 1),
                        \ pattern.'\zs')
      let concat = 0
      if empty(a:ignores)
        let tokens = raw_tokens
      else
        " Concat adjacent tokens that are split by ignorable delimiters
        let tokens = []
        let idx    = 0
        for token in raw_tokens
          let idx += len(token)
          if concat
            let tokens[len(tokens) - 1] .= token
          else
            call add(tokens, token)
          endif
          let concat = s:highlighted_as(line, idx + a:fc - 1, a:ignores)
        endfor
      endif

      " Preserve indentation - merge first two tokens
      if !empty(tokens) && match(tokens[0], '^\s*$') != -1
        let tokens = extend([join(tokens[0:1], '')], tokens[2:-1])
      endif

      " Skip comment line
      if concat && len(tokens) == 1 && a:ignore_unmatched
        let tokens = []
      endif

      " Remember tokens for subsequent recursive calls
      let a:all_tokens[line] = tokens
    else
      let tokens = a:all_tokens[line]
    endif

    " Skip empty lines
    if empty(tokens)
      continue
    endif

    " Calculate the maximum number of tokens for a line within the range
    let max_tokens = max([len(tokens), max_tokens])

    if a:nth > 0 " Positive field number
      if len(tokens) < a:nth
        continue
      endif
      let nth = a:nth - 1 " make it 0-based
    else " Negative field number
      let nth = len(tokens) + a:nth
      if match(tokens[len(tokens) - 1], pattern.'$') == -1
        let nth -= 1
      endif

      if nth < 0 || nth == len(tokens)
        continue
      endif
    endif

    let last   = tokens[nth]
    let prefix = (nth > 0 ? join(tokens[0 : nth - 1], '') : '')
    let token  = substitute(last, pattern.'$', '', '')

    let delim = get(matchlist(last, pattern.'$'), 1, '')
    if empty(delim) && a:just == 0 && a:ignore_unmatched
      continue
    endif

    let indent        = len(matchstr(tokens[0], '^\s\+'))
    if min_indent < 0 || indent < min_indent
      let min_indent  = indent
    endif
    let max_just_len  = max([s:strwidth(prefix.token), max_just_len])
    let max_delim_len = max([s:strwidth(delim), max_delim_len])
    let lines[line]   = [nth, prefix, token, delim]
  endfor

  " Phase 2
  for [line, elems] in items(lines)
    let tokens = a:all_tokens[line]
    let [nth, prefix, token, delim] = elems

    " Remove the leading whitespaces of the next token
    if len(tokens) > nth + 1
      let tokens[nth + 1] = s:ltrim(tokens[nth + 1])
    endif

    " Pad the token with spaces
    let pad = repeat(' ', max_just_len - s:strwidth(prefix) - s:strwidth(token))
    let rpad = ''
    if a:just == 0
      if a:stick_to_left
        let rpad = pad
      else
        let token = token . pad
      endif
    elseif a:just == 1
      let token = pad . token
    endif
    let tokens[nth] = token

    " Pad the delimiter
    let dpad = repeat(' ', max_delim_len - s:strwidth(delim))
    if a:stick_to_left
      let rpad = rpad . dpad
    else
      let delim = dpad . delim
    endif

    " Before and after the range (for blockwise visual mode)
    let cline   = getline(line)
    let before  = strpart(cline, 0, a:fc - 1)
    let after   = a:lc ? strpart(cline, a:lc) : ''

    " Determine the left and right margin around the delimiter
    let rest    = join(tokens[nth + 1 : -1], '')
    let ml      = empty(prefix . token) ? '' : a:ml
    let mr      = (empty(rest) ||
          \ (empty(rest) && stridx(after, a:mr) == 0)) ? '' : a:mr

    " Adjust indentation of the lines starting with a delimiter
    let lpad = ''
    if nth == 0
      let ipad = repeat(' ', min_indent - len(strpart(before.token, '^\s\+').ml))
      if a:just == 0
        let token = ipad . token
      else
        let lpad = ipad
      endif
    endif

    " Align the token
    let aligned = join([lpad, token, ml, delim, mr, rpad], '')
    let tokens[nth] = aligned

    " Update the line
    let newline = s:rtrim(before.join(tokens, '').after)
    call setline(line, newline)
  endfor

  if a:recursive && a:nth < max_tokens
    let just = a:recursive == 2 ? !a:just : a:just
    call s:do_align(just, a:all_tokens, a:fl, a:ll, a:fc, a:lc, a:pattern,
          \ a:nth + 1, a:ml, a:mr, a:stick_to_left, a:ignore_unmatched,
          \ a:ignores, a:recursive)
  endif
endfunction

function! s:interactive(just)
  let just = a:just
  let n    = ''
  let ch   = ''

  while 1
    call s:echon(just, n, '')

    let c  = getchar()
    let ch = nr2char(c)
    if c == 3 || c == 27 " CTRL-C / ESC
      throw 'exit'
    elseif c == '€kb' " Backspace
      if len(n) > 0
        let n = strpart(n, 0, len(n) - 1)
      endif
    elseif c == 13 " Enter key
      let just = (just + 1) % len(s:just)
    elseif ch == '-'
      if empty(n)      | let n = '-'
      elseif n == '-'  | let n = ''
      else             | break
      endif
    elseif ch == '*'
      if empty(n)      | let n = '*'
      elseif n == '*'  | let n = '**'
      elseif n == '**' | let n = ''
      else             | break
      endif
    elseif c >= 48 && c <= 57 " Numbers
      if n[0] == '*'   | break
      else             | let n = n . ch
      end
    else
      break
    endif
  endwhile
  return [just, n, ch]
endfunction

function! s:parse_args(args)
  let n      = ''
  let ch     = ''
  let args   = a:args
  let cand   = ''
  let option = {}

  " Poor man's option parser
  let idx = 0
  while 1
    let midx = match(args, '{.*}\s*$', idx)
    if midx == -1 | break | endif

    let cand = strpart(args, midx)
    try
      let o = eval(cand)
      if type(o) == 4
        let option = o
        let args = strpart(args, 0, midx)
        break
      endif
    catch
      " Ignore
    endtry
    let idx = midx + 1
  endwhile

  " Invalid option dictionary
  if len(substitute(cand, '\s', '', 'g')) > 2 && empty(option)
    call s:exit("Invalid option: ". cand)
  endif

  " Has /Regexp/?
  let matches = matchlist(args, '^\(.\{-}\)\s*/\(.*\)/\s*$')

  " Found regexp
  if !empty(matches)
    let regexp = matches[2]
    " Test regexp
    try   | call matchlist('', regexp)
    catch | call s:exit("Invalid regular expression: ". regexp)
    endtry
    " Unsupported regular expression
    if match(regexp, '\\zs') != -1
      call s:exit("Using \\zs is not allowed. Use stick_to_left option instead.")
    endif
    return [matches[1], regexp, option, 1]
  else
    let tokens = matchlist(args, '^\([1-9][0-9]*\|-[0-9]*\|\*\*\?\)\?\s*\(.\{-}\)\?$')
    return [tokens[1], tokens[2], option, 0]
  endif
endfunction

function! easy_align#align(just, expr) range
  let just   = a:just
  let recur  = 0
  let n      = ''
  let ch     = ''
  let option = {}
  let regexp = 0

  try
    if empty(a:expr)
      let [just, n, ch] = s:interactive(just)
    else
      let [n, ch, option, regexp] = s:parse_args(a:expr)
      if empty(ch)
        " Try swapping n and ch
        let [n, ch] = ['', n]
      endif
    endif
  catch 'exit'
    return
  endtry

  if n == '*'      | let [nth, recur] = [1, 1]
  elseif n == '**' | let [nth, recur] = [1, 2]
  elseif n == '-'  | let nth = -1
  elseif empty(n)  | let nth = 1
  elseif n == '0' || ( n != '-0' && n != string(str2nr(n)) )
    echon "\rInvalid field number: ". n
    return
  else
    let nth = n
  endif

  let delimiters = s:easy_align_delimiters_default
  if exists('g:easy_align_delimiters')
    let delimiters = extend(copy(delimiters), g:easy_align_delimiters)
  endif

  if regexp
    let dict = { 'pattern': ch }
  else
    if ch =~ '^\\\s\+$'
      let ch = ' '
    elseif ch =~ '^\\\\\s\+$'
      let ch = '\'
    endif
    if !has_key(delimiters, ch)
      echon "\rUnknown delimiter key: ". ch
      return
    endif
    let dict = delimiters[ch]
  endif

  try
    if !empty(option)
      let dict = extend(copy(dict), s:normalize_options(option))
    endif
  catch 'exit'
    return
  endtry

  let ml = get(dict, 'left_margin', ' ')
  let mr = get(dict, 'right_margin', ' ')
  if type(ml) == 0 | let ml = repeat(' ', ml) | endif
  if type(mr) == 0 | let mr = repeat(' ', mr) | endif

  call s:do_align(just, {}, a:firstline, a:lastline,
    \ visualmode() == '' ? min([col("'<"), col("'>")]) : 1,
    \ visualmode() == '' ? max([col("'<"), col("'>")]) : 0,
    \ get(dict, 'pattern', ch),
    \ nth,
    \ ml,
    \ mr,
    \ get(dict, 'stick_to_left', 0),
    \ get(dict, 'ignore_unmatched', get(g:, 'easy_align_ignore_unmatched', 1)),
    \ get(dict, 'ignores', s:ignored_syntax()),
    \ recur)
  call s:echon(just, n, regexp ? '/'.ch.'/' : ch)
endfunction

