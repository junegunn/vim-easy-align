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
\  ' ': { 'pattern': ' ',  'margin_left': '',  'margin_right': '',  'stick_to_left': 0 },
\  '=': { 'pattern': '===\|<=>\|\(&&\|||\|<<\|>>\)=\|=\~\|=>\|[:+/*!%^=><&|-]\?=[#?]\?',
\                          'margin_left': ' ', 'margin_right': ' ', 'stick_to_left': 0 },
\  ':': { 'pattern': ':',  'margin_left': '',  'margin_right': ' ', 'stick_to_left': 1 },
\  ',': { 'pattern': ',',  'margin_left': '',  'margin_right': ' ', 'stick_to_left': 1 },
\  '|': { 'pattern': '|',  'margin_left': ' ', 'margin_right': ' ', 'stick_to_left': 0 },
\  '.': { 'pattern': '\.', 'margin_left': '',  'margin_right': '',  'stick_to_left': 0 },
\  '{': { 'pattern': '(\@<!{',
\                          'margin_left': ' ', 'margin_right': ' ', 'stick_to_left': 0 },
\  '}': { 'pattern': '}',  'margin_left': ' ', 'margin_right': '',  'stick_to_left': 0 }
\ }

let s:just = ['', '[R]']

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

function! s:do_align(just, all_tokens, fl, ll, fc, lc, pattern, nth, ml, mr, stick_to_left, ignore_unmatched, ignores, recursive)
  let lines          = {}
  let max_just_len   = 0
  let max_delim_len  = 0
  let max_tokens     = 0
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
      if concat && len(tokens) == 1
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
      let tokens[nth + 1] = substitute(tokens[nth + 1], '^\s*', '', '')
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

    " Align the token
    let aligned = join([token, ml, delim, mr, rpad], '')
    let tokens[nth] = aligned

    " Update the line
    let newline = substitute(before.join(tokens, '').after, '\s*$', '', '')
    call setline(line, newline)
  endfor

  if a:recursive && a:nth < max_tokens
    let just = a:recursive == 2 ? !a:just : a:just
    call s:do_align(just, a:all_tokens, a:fl, a:ll, a:fc, a:lc, a:pattern,
          \ a:nth + 1, a:ml, a:mr, a:stick_to_left, a:ignore_unmatched,
          \ a:ignores, a:recursive)
  endif
endfunction

function! s:echon(l, n, d)
  echon "\r"
  echon "\rEasyAlign". s:just[a:l] ." (" .a:n.a:d. ")"
endfunction

function! easy_align#align(just, ...) range
  let just      = a:just
  let recursive = 0
  let n         = ''
  let ch        = ''

  if a:0 == 0
    while 1
      call s:echon(just, n, '')

      let c  = getchar()
      let ch = nr2char(c)
      if c == 3 || c == 27 " CTRL-C / ESC
        return
      elseif c == '�kb' " Backspace
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
  elseif a:0 == 1
    let tokens = matchlist(a:1, '^\([1-9][0-9]*\|-[0-9]*\|\*\*\?\)\?\(.\)$')
    if empty(tokens)
      echo "Invalid arguments: ". a:1
      return
    endif
    let [n, ch] = tokens[1:2]
  elseif a:0 == 2
    let [n, ch] = a:000
  else
    echo "Invalid number of arguments: ". a:0 ." (expected 0, 1, or 2)"
    return
  endif

  if n == '*'      | let [nth, recursive] = [1, 1]
  elseif n == '**' | let [nth, recursive] = [1, 2]
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

  if has_key(delimiters, ch)
    let dict = delimiters[ch]
    call s:do_align(just, {}, a:firstline, a:lastline,
                  \ visualmode() == '' ? min([col("'<"), col("'>")]) : 1,
                  \ visualmode() == '' ? max([col("'<"), col("'>")]) : 0,
                  \ get(dict, 'pattern', ch),
                  \ nth,
                  \ get(dict, 'margin_left', ' '),
                  \ get(dict, 'margin_right', ' '),
                  \ get(dict, 'stick_to_left', 0),
                  \ get(dict, 'ignore_unmatched', get(g:, 'easy_align_ignore_unmatched', 1)),
                  \ get(dict, 'ignores', s:ignored_syntax()),
                  \ recursive)
    call s:echon(just, n, ch)
  else
    echon "\rUnknown delimiter: ". ch
  endif
endfunction

