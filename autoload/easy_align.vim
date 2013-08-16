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
\ 'margin_left': [0, 1], 'margin_right':     [0, 1], 'stick_to_left':   [0],
\ 'left_margin': [0, 1], 'right_margin':     [0, 1], 'indentation':     [1],
\ 'ignores':     [3   ], 'ignore_unmatched': [0   ], 'delimiter_align': [1]
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

function! s:split_line(line, nth, just, recur, fc, lc, pattern, stick_to_left, ignore_unmatched, ignores)
  let pjust  = a:just
  let just   = a:just
  let string = a:lc ?
    \ strpart(getline(a:line), a:fc - 1, a:lc - a:fc + 1) :
    \ strpart(getline(a:line), a:fc - 1)
  let idx     = 0
  " Do not allow \zs
  " 1: whole match
  " 2: token
  " 3: delimiter
  let pattern = '^\(\(.\{-}\s*\)\(' .a:pattern. '\)\s' . (a:stick_to_left ? '*' : '\{-}') . '\)'
  let tokens  = []
  let delims  = []

  " Phase 1: split
  let ignorable = 0
  let token = ''
  while 1
    let matches = matchlist(string, pattern, idx)
    " No match
    if empty(matches) | break | endif

    " Match, but empty delimiter
    if empty(matches[1])
      let char = strpart(string, idx, 1)
      if empty(char) | break | endif
      let [match, part, delim] = [char, char, '']
    " Match
    else
      let [match, part, delim] = matches[1 : 3]
    endif

    let ignorable = s:highlighted_as(a:line, idx + len(part) + a:fc, a:ignores)
    if ignorable
      let token .= match
    else
      call add(tokens, token . match)
      call add(delims, delim)
      let [pjust, just] = [just, a:recur == 2 ? !just : just]
      let token = ''
    endif

    let idx += len(match)

    " If the string is non-empty and ends with the delimiter,
    " append an empty token to the list
    if idx == len(string)
      call add(tokens, '')
      call add(delims, '')
      break
    endif
  endwhile

  let leftover = token . strpart(string, idx)
  if !empty(leftover)
    let ignorable = s:highlighted_as(a:line, len(string) + a:fc - 1, a:ignores)
    call add(tokens, leftover)
    call add(delims, '')
    let [pjust, just] = [just, a:recur == 2 ? !just : just]
  endif

  " Preserve indentation - merge first two tokens
  if len(tokens) > 1 && empty(s:rtrim(tokens[0]))
    let tokens[1] = tokens[0] . tokens[1]
    call remove(tokens, 0)
    call remove(delims, 0)
    let pjust = just
  endif

  " Skip comment line
  if ignorable && len(tokens) == 1 && a:ignore_unmatched
    let tokens = []
    let delims = []
  " Append an empty item to enable right justification of the last token
  " - if the last token is not ignorable or ignorable but not the only token
  elseif pjust == 1 && (!ignorable || len(tokens) > 1) && a:nth >= 0 " includes -0
    call add(tokens, '')
    call add(delims, '')
  endif

  return [tokens, delims]
endfunction

function! s:do_align(just, all_tokens, all_delims, fl, ll, fc, lc, pattern, nth,
      \ ml, mr, da, indentation, stick_to_left, ignore_unmatched, ignores, recursive)
  let lines          = {}
  let max_just_len   = 0
  let max_delim_len  = 0
  let max_tokens     = 0
  let min_indent     = -1
  let max_indent     = 0

  " Phase 1
  for line in range(a:fl, a:ll)
    if !has_key(a:all_tokens, line)
      " Split line into the tokens by the delimiters
      let [tokens, delims] = s:split_line(line, a:nth, a:just, a:recursive, a:fc, a:lc, a:pattern, a:stick_to_left, a:ignore_unmatched, a:ignores)

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
    let max_tokens = max([len(tokens), max_tokens])

    if a:nth > 0 " Positive field number
      if len(tokens) < a:nth
        continue
      endif
      let nth = a:nth - 1 " make it 0-based
    else " -0 or Negative field number
      if a:nth == 0 && a:just == 1
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
    if empty(delim) && !exists('tokens[nth + 1]') && a:ignore_unmatched
      continue
    endif

    let indent        = len(matchstr(tokens[0], '^\s\+'))
    if min_indent < 0 || indent < min_indent
      let min_indent  = indent
    endif
    let max_indent    = max([indent, max_indent])
    let max_just_len  = max([s:strwidth(prefix.token), max_just_len])
    let max_delim_len = max([s:strwidth(delim), max_delim_len])
    let lines[line]   = [nth, prefix, token, delim]
  endfor

  " Phase 1-5: indentation handling (only on a:nth == 1)
  if a:nth == 1
    if a:indentation ==? 'd'
      let indent = repeat(' ', max_indent)
    elseif a:indentation ==? 's'
      let indent = repeat(' ', min_indent)
    elseif a:indentation ==? 'n'
      let indent = ''
    elseif a:indentation !=? 'k'
      call s:exit('Invalid indentation: ' . a:indentation)
    end

    if a:indentation !=? 'k'
      let max_just_len = 0
      for [line, elems] in items(lines)
        let [nth, prefix, token, delim] = elems

        let token = substitute(token, '^\s*', indent, '')
        let max_just_len = max([max_just_len, s:strwidth(token)])

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
    let dpadl = max_delim_len - s:strwidth(delim)
    if a:da ==? 'l'
      let [dl, dr] = ['', repeat(' ', dpadl)]
    elseif a:da ==? 'c'
      let dl = repeat(' ', dpadl / 2)
      let dr = repeat(' ', dpadl - dpadl / 2)
    elseif a:da ==? 'r'
      let [dl, dr] = [repeat(' ', dpadl), '']
    else
      call s:exit('Invalid delimiter_align: ' . a:da)
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
      let ipad = repeat(' ', min_indent - len(token.ml))
      if a:just == 0
        let token = ipad . token
      else
        let lpad = ipad
      endif
    endif

    " Align the token
    let aligned = join([lpad, token, ml, dl, delim, dr, mr, rpad], '')
    let tokens[nth] = aligned

    " Update the line
    let newline = s:rtrim(before.join(tokens, '').after)
    call setline(line, newline)
  endfor

  if a:recursive && a:nth < max_tokens
    let just = a:recursive == 2 ? !a:just : a:just
    call s:do_align(just, a:all_tokens, a:all_delims, a:fl, a:ll, a:fc, a:lc, a:pattern,
          \ a:nth + 1, a:ml, a:mr, a:da, a:indentation, a:stick_to_left,
          \ a:ignore_unmatched, a:ignores, a:recursive)
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
    let midx = match(args, '\s*{.*}\s*$', idx)
    if midx == -1 | break | endif

    let cand = strpart(args, midx)
    try
      let [l, r, c, k, s, d, n] = ['l', 'r', 'c', 'k', 's', 'd', 'n']
      let [L, R, C, K, S, D, N] = ['l', 'r', 'c', 'k', 's', 'd', 'n']
      let o = eval(cand)
      if type(o) == 4
        let option = o
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
    " Resolving command-line ambiguity
    if !empty(a:expr)
      " '\ ' => ' '
      if ch =~ '^\\\s\+$'
        let ch = ' '
      " '\\' => '\'
      elseif ch =~ '^\\\\\s*$'
        let ch = '\'
      endif
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

  let bvisual = visualmode() == ''

  if recur && bvisual
    echon "\rRecursive alignment is currently not supported in blockwise-visual mode"
    return
  endif

  try
    call s:do_align(just, {}, {}, a:firstline, a:lastline,
    \ bvisual ? min([col("'<"), col("'>")]) : 1,
    \ bvisual ? max([col("'<"), col("'>")]) : 0,
    \ get(dict, 'pattern', ch),
    \ nth,
    \ ml,
    \ mr,
    \ get(dict, 'delimiter_align', get(g:, 'easy_align_delimiter_align', 'r')),
    \ get(dict, 'indentation', get(g:, 'easy_align_indentation', 'k')),
    \ get(dict, 'stick_to_left', 0),
    \ get(dict, 'ignore_unmatched', get(g:, 'easy_align_ignore_unmatched', 1)),
    \ get(dict, 'ignores', s:ignored_syntax()),
    \ recur)
    call s:echon(just, n, regexp ? '/'.ch.'/' : ch)
  catch 'exit'
  endtry
endfunction

