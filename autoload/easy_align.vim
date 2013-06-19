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

function! s:do_align(just, fl, ll, fc, lc, pattern, nth, ml, mr, stick_to_left, recursive)
  let lines          = {}
  let max_just_len   = 0
  let max_delim_len  = 0
  let max_tokens     = 0
  let pattern        = '\s*\(' .a:pattern. '\)\s' . (a:stick_to_left ? '*' : '\{-}')
  let ignore_comment = has('syntax') && exists('g:syntax_on') &&
                       \ get(g:, 'easy_align_ignore_comment', 1)
  for line in range(a:fl, a:ll)
    let tokens = split(a:lc ?
                      \ strpart(getline(line), a:fc - 1, a:lc - a:fc + 1) :
                      \ strpart(getline(line), a:fc - 1),
                      \ pattern.'\zs')
    if empty(tokens)
      continue
    endif

    if ignore_comment
      execute "normal! ". line ."G^"
      if synIDattr(synID(line, a:fc == 1 ? col('.') : a:fc, 0), 'name') =~? 'comment' &&
         \ synIDattr(synID(line, a:lc ? min([a:lc, col('$') - 1]) : (col('$') - 1), 0), 'name') =~? 'comment'
        continue
      endif
    endif

    " Preserve indentation
    if match(tokens[0], '^\s*$') != -1
      let tokens = extend([join(tokens[0:1], '')], tokens[2:-1])
    endif
    let max_tokens = max([len(tokens), max_tokens])
    if a:nth > 0
      if len(tokens) < a:nth
        continue
      endif
      let nth = a:nth - 1 " 0-based
    else
      if match(tokens[len(tokens) - 1], pattern.'$') == -1
        let nth = len(tokens) + a:nth - 1
      else
        let nth = len(tokens) + a:nth
      endif

      if nth < 0 || nth == len(tokens)
        continue
      endif
    endif

    let last   = tokens[nth]
    let prefix = (nth > 0 ? join(tokens[0 : nth - 1], '') : '')
    let token  = substitute(last, pattern.'$', '', '')
    let suffix = substitute(join(tokens[nth + 1: -1], ''), '^\s*', '', '')

    if match(last, pattern.'$') == -1
      if a:just == 0 && get(g:, 'easy_align_ignore_unmatched', 1)
        continue
      else
        let delim = ''
      endif
    else
      let delim = matchlist(last, pattern)[1]
    endif

    let max_just_len  = max([s:strwidth(token.prefix), max_just_len])
    let max_delim_len = max([s:strwidth(delim), max_delim_len])
    let lines[line]   = [prefix, token, delim, suffix]
  endfor

  for [line, tokens] in items(lines)
    let [prefix, token, delim, suffix] = tokens

    let pad = repeat(' ', max_just_len - s:strwidth(prefix) - s:strwidth(token))
    if a:just == 0
      if a:stick_to_left
        let suffix = pad . suffix
      else
        let token = token . pad
      endif
    elseif a:just == 1
      let token = pad . token
    endif

    let delim   = repeat(' ', max_delim_len - s:strwidth(delim)). delim
    let cline   = getline(line)
    let before  = strpart(cline, 0, a:fc - 1)
    let after   = a:lc ? strpart(cline, a:lc) : ''

    let ml      = empty(prefix . token) ? '' : a:ml
    let mr      = (empty(suffix . after) || (empty(suffix) && stridx(after, a:mr) == 0)) ? '' : a:mr
    let aligned = join([prefix, token, ml, delim, mr, suffix], '')
    let aligned = empty(after) ? substitute(aligned, '\s*$', '', '') : aligned

    call setline(line, before.aligned.after)
  endfor

  if a:recursive && a:nth < max_tokens
    call s:do_align(a:just, a:fl, a:ll, a:fc, a:lc, a:pattern, a:nth + 1, a:ml, a:mr, a:stick_to_left, a:recursive)
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
      if c == 3 || c == 27
        return
      elseif c == '€kb'
        if len(n) > 0
          let n = strpart(n, 0, len(n) - 1)
        endif
      elseif c == 13
        let just = (just + 1) % len(s:just)
      elseif index(['-', '*'], ch) != -1
        if empty(n)
          let n = ch
        else
          break
        endif
      elseif c == 48
        if n == '-'
          let n = '-0'
        else
          break
        endif
      elseif c > 48 && c <= 57
        if n != '*'
          let n = n . ch
        else
          break
        endif
      else
        break
      endif
    endwhile
  elseif a:0 == 1
    let tokens = matchlist(a:1, '^\([1-9][0-9]*\|-[0-9]*\|\*\)\?\(.\)$')
    if empty(tokens)
      echo "Invalid arguments: ". a:1
      return
    endif
    let [n, ch] = tokens[1:2]
  elseif a:0 == 2
    let n  = a:1
    let ch = a:2
  else
    echo "Invalid number of arguments: ". a:0 ." (expected 0, 1, or 2)"
    return
  endif

  if n == '*'
    let n = 1
    let recursive = 1
  elseif n == '-'
    let n = -1
  elseif empty(n)
    let n = 1
  elseif n != '-0' && n != string(str2nr(n))
    echon "\rInvalid field number: ". n
    return
  endif

  let delimiters = extend(copy(s:easy_align_delimiters_default),
                   \ get(g:, 'easy_align_delimiters', {}))

  if has_key(delimiters, ch)
    let dict = delimiters[ch]
    call s:do_align(just, a:firstline, a:lastline,
                  \ visualmode() == '' ? min([col("'<"), col("'>")]) : 1,
                  \ visualmode() == '' ? max([col("'<"), col("'>")]) : 0,
                  \ get(dict, 'pattern', ch),
                  \ n,
                  \ get(dict, 'margin_left', ' '),
                  \ get(dict, 'margin_right', ' '),
                  \ get(dict, 'stick_to_left', 0), recursive)
    call s:echon(just, (recursive ? '*' : n), ch)
  else
    echon "\rUnknown delimiter: ". ch
  endif
endfunction

