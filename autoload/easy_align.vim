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
\  ' ': { 'pattern': ' ',  'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0 },
\  '=': { 'pattern': '===\|<=>\|\(&&\|||\|<<\|>>\)=\|=\~[#?]\?\|=>\|[:+/*!%^=><&|.-]\?=[#?]\?',
\                          'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  ':': { 'pattern': ':',  'left_margin': 0, 'right_margin': 1, 'stick_to_left': 1 },
\  ',': { 'pattern': ',',  'left_margin': 0, 'right_margin': 1, 'stick_to_left': 1 },
\  '|': { 'pattern': '|',  'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  '.': { 'pattern': '\.', 'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0 },
\  '{': { 'pattern': '(\@<!{',
\                          'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  '}': { 'pattern': '}',  'left_margin': 1, 'right_margin': 0, 'stick_to_left': 0 }
\ }

let s:mode_labels = { 'l': '', 'r': '[R]', 'c': '[C]' }

let s:known_options = {
\ 'margin_left':   [0, 1], 'margin_right':     [0, 1], 'stick_to_left':   [0],
\ 'left_margin':   [0, 1], 'right_margin':     [0, 1], 'indentation':     [1],
\ 'ignore_groups': [3   ], 'ignore_unmatched': [0   ], 'delimiter_align': [1],
\ 'mode_sequence': [1   ], 'ignores': [3]
\ }

let s:option_values = {
\ 'indentation':      ['shallow', 'deep', 'none', 'keep'],
\ 'delimiter_align':  ['left', 'center', 'right'],
\ 'ignore_unmatched': [0, 1],
\ 'ignore_groups':    [[], ['String'], ['Comment'], ['String', 'Comment']]
\ }

let s:shorthand = {
\ 'margin_left':   'lm', 'margin_right':     'rm', 'stick_to_left':   'stl',
\ 'left_margin':   'lm', 'right_margin':     'rm', 'indentation':     'idt',
\ 'ignore_groups': 'ig', 'ignore_unmatched': 'iu', 'delimiter_align': 'da',
\ 'mode_sequence': 'm',  'ignores': 'ig'
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
  \ ['Function', ':EasyAlign'],
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
endfunction

function! s:exit(msg)
  call s:echon_([['ErrorMsg', a:msg]])
  throw 'exit'
endfunction

function! s:ltrim(str)
  return substitute(a:str, '^\s*', '', '')
endfunction

function! s:rtrim(str)
  return substitute(a:str, '\s*$', '', '')
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
    if k == 'margin_left'  | let k = 'left_margin'  | endif
    if k == 'margin_right' | let k = 'right_margin' | endif
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
      call add(tokens, '')
      call add(delims, '')
      break
    endif
  endwhile

  let leftover = token . strpart(string, idx)
  if !empty(leftover)
    let ignorable = s:highlighted_as(a:line, len(string) + a:fc - 1, a:ignore_groups)
    call add(tokens, leftover)
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
  elseif (mode ==? 'r' || mode ==? 'c') && (!ignorable || len(tokens) > 1) && a:nth >= 0 " includes -0
    call add(tokens, '')
    call add(delims, '')
  endif

  return [tokens, delims]
endfunction

function! s:max(old, new)
  for k in keys(a:new)
    if a:new[k] > a:old[k]
      let a:old[k] = a:new[k] " max() doesn't work with Floats
    endif
  endfor
endfunction

function! s:do_align(modes, all_tokens, all_delims, fl, ll, fc, lc, pattern, nth,
      \ ml, mr, da, indentation, stick_to_left, ignore_unmatched, ignore_groups, recur)
  let mode       = a:modes[0]
  let lines      = {}
  let min_indent = -1
  let max = { 'pivot_len': 0.0, 'token_len': 0, 'just_len': 0, 'delim_len': 0,
        \ 'indent': 0, 'tokens': 0, 'strip_len': 0 }

  " Phase 1
  for line in range(a:fl, a:ll)
    if !has_key(a:all_tokens, line)
      " Split line into the tokens by the delimiters
      let [tokens, delims] = s:split_line(
            \ line, a:nth, copy(a:modes), a:recur == 2,
            \ a:fc, a:lc, a:pattern,
            \ a:stick_to_left, a:ignore_unmatched, a:ignore_groups)

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
    call s:max(max, { 'tokens': len(tokens) })

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
    if empty(delim) && !exists('tokens[nth + 1]') && a:ignore_unmatched
      continue
    endif

    let indent        = len(matchstr(tokens[0], '^\s\+'))
    if min_indent < 0 || indent < min_indent
      let min_indent  = indent
    endif
    if mode ==? 'c' | let token .= matchstr(token, '^\s*') | endif
    let [pw, tw] = [s:strwidth(prefix), s:strwidth(token)]
    call s:max(max, { 'indent': indent, 'token_len': tw, 'just_len': pw + tw,
                     \ 'delim_len': s:strwidth(delim) })
    if mode ==? 'c'
      call s:max(max, { 'pivot_len': pw + tw / 2.0,
                       \ 'strip_len': s:strwidth(s:trim(token)) })
    endif
    let lines[line]   = [nth, prefix, token, delim]
  endfor

  " Phase 1-5: indentation handling (only on a:nth == 1)
  if a:nth == 1
    if a:indentation ==? 'd'
      let indent = repeat(' ', max.indent)
    elseif a:indentation ==? 's'
      let indent = repeat(' ', min_indent)
    elseif a:indentation ==? 'n'
      let indent = ''
    elseif a:indentation !=? 'k'
      call s:exit('Invalid indentation: ' . a:indentation)
    end

    if a:indentation !=? 'k'
      let max.just_len  = 0
      let max.token_len = 0
      let max.pivot_len = 0

      for [line, elems] in items(lines)
        let [nth, prefix, token, delim] = elems

        let token = substitute(token, '^\s*', indent, '')
        if mode ==? 'c'
          let token = substitute(token, '\s*$', indent, '')
        endif
        let [pw, tw] = [s:strwidth(prefix), s:strwidth(token)]
        call s:max(max, { 'token_len': tw, 'just_len': pw + tw })
        if mode ==? 'c'
          call s:max(max, { 'pivot_len': pw + tw / 2.0 })
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
      if a:stick_to_left
        let rpad = pad
      else
        let token = token . pad
      endif
    elseif mode ==? 'r'
      let pad = repeat(' ', max.just_len - pw - tw)
      let token = pad . token
    elseif mode ==? 'c'
      let p1  = max.pivot_len - (pw + tw / 2.0)
      let p2  = (max.token_len - tw) / 2.0
      let pf1 = floor(p1)
      if pf1 < p1 | let p2 = ceil(p2)
      else        | let p2 = floor(p2)
      endif
      let strip = float2nr(ceil((max.token_len - max.strip_len) / 2.0))
      let token = repeat(' ', float2nr(pf1)) .token. repeat(' ', float2nr(p2))
      let token = substitute(token, repeat(' ', strip) . '$', '', '')

      if a:stick_to_left
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
    let newline = s:rtrim(before.join(tokens, '').after)
    call setline(line, newline)
  endfor

  if a:nth < max.tokens && (a:recur || len(a:modes) > 1)
    call s:shift(a:modes, a:recur == 2)
    call s:do_align(
          \ a:modes, a:all_tokens, a:all_delims,
          \ a:fl, a:ll, a:fc, a:lc, a:pattern,
          \ a:nth + 1, a:ml, a:mr, a:da, a:indentation, a:stick_to_left,
          \ a:ignore_unmatched, a:ignore_groups, a:recur)
  endif
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
  call inputsave()
  let got = input(a:str, a:default)
  call inputrestore()
  return got
endfunction

function! s:atoi(str)
  return (a:str =~ '^[0-9]\+$') ? str2nr(a:str) : a:str
endfunction

function! s:interactive(modes, vis, opts, delims)
  let mode = s:shift(a:modes, 1)
  let n    = ''
  let ch   = ''
  let opts = s:compact_options(a:opts)
  let vals = deepcopy(s:option_values)
  let regx = 0
  let warn = ''

  while 1
    call s:echon(mode, n, -1, '', opts, warn)
    let check = 0
    let warn = ''

    let c  = getchar()
    let ch = nr2char(c)
    if c == 3 || c == 27 " CTRL-C / ESC
      throw 'exit'
    elseif c == "\<bs>"
      if len(n) > 0
        let n = strpart(n, 0, len(n) - 1)
      endif
    elseif c == 13 " Enter key
      let mode = s:shift(a:modes, 1)
      if has_key(opts, 'm')
        let opts.m = mode . strpart(opts.m, 1)
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
    elseif (c == 48 && len(n) > 0) || c > 48 && c <= 57 " Numbers
      if n[0] == '*'   | let check = 1
      else             | let n = n . ch
      end
    elseif ch == "\<C-D>"
      let opts['da'] = s:shift(vals['delimiter_align'], 1)
    elseif ch == "\<C-I>"
      let opts['idt'] = s:shift(vals['indentation'], 1)
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
      let opts['iu'] = s:shift(vals['ignore_unmatched'], 1)
    elseif ch == "\<C-G>"
      let opts['ig'] = s:shift(vals['ignore_groups'], 1)
    elseif c == "\<Left>"
      let opts['stl'] = 1
      let opts['lm']  = 0
    elseif c == "\<Right>"
      let opts['stl'] = 0
      let opts['lm']  = 1
    elseif c == "\<Up>" || c == "\<Down>"
      silent! call remove(opts, 'stl')
      silent! call remove(opts, 'lm')
    elseif ch == "\<C-O>"
      let modes = tolower(s:input("Mode sequence: ", get(opts, 'm', mode), a:vis))
      if match(modes, '^[lrc]\+\*\{0,2}$') != -1
        let opts['m'] = modes
        let mode      = modes[0]
        while mode != s:shift(a:modes, 1)
        endwhile
      else
        silent! call remove(opts, 'm')
      endif
    elseif ch == "\<C-_>" || ch == "\<C-X>"
      let prompt = 'Regular expression: '
      let ch = s:input(prompt, '', a:vis)
      if !empty(ch) && s:valid_regexp(ch)
        let regx = 1
        break
      else
        let warn = 'Invalid regular expression: '.ch
      endif
    elseif ch =~ '[[:print:]]'
      let check = 1
    else
      let warn = 'Invalid character'
    endif

    if check
      if has_key(a:delims, ch)
        break
      else
        let warn = 'Unknown delimiter key: '.ch
      endif
    endif
  endwhile
  return [mode, n, ch, s:normalize_options(opts), regx]
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
  if !s:valid_regexp(a:regexp)
    call s:exit('Invalid regular expression: '. a:regexp)
  endif
  return a:regexp
endfunction

function! s:parse_args(args)
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

  " Has /Regexp/?
  let matches = matchlist(args, '^\(.\{-}\)\s*/\(.*\)/\s*$')

  " Found regexp
  if !empty(matches)
    return [matches[1], s:test_regexp(matches[2]), opts, 1]
  else
    let tokens = matchlist(args, '^\([1-9][0-9]*\|-[0-9]*\|\*\*\?\)\?\s*\(.\{-}\)\?$')
    return [tokens[1], tokens[2], opts, 0]
  endif
endfunction

function! s:modes(bang)
  return get(g:,
    \ (a:bang ? 'easy_align_bang_interactive_modes' : 'easy_align_interactive_modes'),
    \ (a:bang ? ['r', 'l', 'c'] : ['l', 'r', 'c']))
endfunction

function! s:alternating_modes(mode)
  return a:mode ==? 'r' ? ['r', 'l'] : ['l', 'r']
endfunction

function! easy_align#align(bang, expr) range
  try
    call s:align(a:bang, a:firstline, a:lastline, a:expr)
  catch 'exit'
  endtry
endfunction

function! s:align(bang, first_line, last_line, expr)
  let modes  = s:modes(a:bang)
  let mode   = modes[0]
  let recur  = 0
  let n      = ''
  let ch     = ''
  let opts   = {}
  let regexp = 0
  " Heuristically determine if the user was in visual mode
  let vis    = a:first_line == line("'<") && a:last_line == line("'>")

  let delimiters = s:easy_align_delimiters_default
  if exists('g:easy_align_delimiters')
    let delimiters = extend(copy(delimiters), g:easy_align_delimiters)
  endif

  if empty(a:expr)
    let [mode, n, ch, opts, regexp] = s:interactive(copy(modes), vis, opts, delimiters)
  else
    let [n, ch, opts, regexp] = s:parse_args(a:expr)
    if empty(n) && empty(ch)
      let [mode, n, ch, opts, regexp] = s:interactive(copy(modes), vis, opts, delimiters)
    elseif empty(ch)
      " Try swapping n and ch
      let [n, ch] = ['', n]
    endif
  endif

  if n == '*'      | let [nth, recur] = [1, 1]
  elseif n == '**' | let [nth, recur] = [1, 2]
  elseif n == '-'  | let nth = -1
  elseif empty(n)  | let nth = 1
  elseif n == '0' || ( n != '-0' && n != string(str2nr(n)) )
    call s:exit('Invalid N-th parameter: '. n)
  else
    let nth = n
  endif

  if regexp
    let dict = { 'pattern': ch }
  else
    " Resolving command-line ambiguity
    if !empty(a:expr)
      " '\ ' => ' '
      " '\'  => ' '
      if ch =~ '^\\\s*$'
        let ch = ' '
      " '\\' => '\'
      elseif ch =~ '^\\\\\s*$'
        let ch = '\'
      endif
    endif
    if !has_key(delimiters, ch)
      call s:exit('Unknown delimiter key: '. ch)
    endif
    let dict = copy(delimiters[ch])
  endif

  call extend(dict, opts)

  let ml = get(dict, 'left_margin', ' ')
  let mr = get(dict, 'right_margin', ' ')
  if type(ml) == 0 | let ml = repeat(' ', ml) | endif
  if type(mr) == 0 | let mr = repeat(' ', mr) | endif

  let bvisual = vis && char2nr(visualmode()) == 22 " ^V

  if recur && bvisual
    call s:exit('Recursive alignment is not supported in blockwise-visual mode')
  endif

  let aseq = get(dict, 'mode_sequence',
        \ recur == 2 ? s:alternating_modes(mode) : [mode])
  let mode_expansion = matchstr(aseq, '\*\+$')
  if mode_expansion == '*'
    let aseq = aseq[0 : -2]
    let recur = 1
  elseif mode_expansion == '**'
    let aseq = aseq[0 : -3]
    let recur = 2
  endif
  let aseq_list = type(aseq) == 1 ? split(tolower(aseq), '\s*') : map(copy(aseq), 'tolower(v:val)')
  let aseq_str = join(aseq_list, '')

  call s:do_align(
    \ aseq_list,
    \ {}, {}, a:first_line, a:last_line,
    \ bvisual ? min([col("'<"), col("'>")]) : 1,
    \ bvisual ? max([col("'<"), col("'>")]) : 0,
    \ get(dict, 'pattern', ch),
    \ nth,
    \ ml,
    \ mr,
    \ get(dict, 'delimiter_align', get(g:, 'easy_align_delimiter_align', 'r'))[0],
    \ get(dict, 'indentation', get(g:, 'easy_align_indentation', 'k'))[0],
    \ get(dict, 'stick_to_left', 0),
    \ get(dict, 'ignore_unmatched', get(g:, 'easy_align_ignore_unmatched', 1)),
    \ get(dict, 'ignore_groups', get(dict, 'ignores', s:ignored_syntax())),
    \ recur)

  let copts = s:compact_options(opts)
  let nbmode = s:modes(0)[0]
  if !has_key(copts, 'm') && (
    \  (recur == 2 && join(s:alternating_modes(nbmode), '') != aseq_str) ||
    \  (recur != 2 && (aseq_str[0] != nbmode || len(aseq_str) > 1))
    \ )
    call extend(copts, { 'm': aseq_str })
  endif
  call s:echon('', n, regexp, ch, copts, '')
endfunction

