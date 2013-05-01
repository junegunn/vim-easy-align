if exists("g:easy_align_loaded")
  finish
endif
let g:easy_align_loaded = 1
let g:easy_align_delimiters_merged = {
\  ' ': { 'pattern': ' ',  'margin_left': '',  'margin_right': '',  'stick_to_left': 0 },
\  '=': { 'pattern': '<=>\|\(&&\|||\|<<\|>>\)=\|=\~\|=>\|[:+/*!%^=><&|-]\?=',
\                          'margin_left': ' ', 'margin_right': ' ', 'stick_to_left': 0 },
\  ':': { 'pattern': ':',  'margin_left': '',  'margin_right': ' ', 'stick_to_left': 1 },
\  ',': { 'pattern': ',',  'margin_left': '',  'margin_right': ' ', 'stick_to_left': 1 },
\  '|': { 'pattern': '|',  'margin_left': ' ', 'margin_right': ' ', 'stick_to_left': 0 },
\  '.': { 'pattern': '\.', 'margin_left': '',  'margin_right': '',  'stick_to_left': 0 }
\ }

if !exists("g:easy_align_delimiters")
  let g:easy_align_delimiters = {}
endif

call extend(g:easy_align_delimiters_merged, g:easy_align_delimiters)

function! s:do_align(fl, ll, fc, lc, pattern, nth, ml, mr, stick_to_left, recursive)
  let lines         = {}
  let just_len      = 0
  let max_delim_len = 0
  let max_tokens    = 0
  let pattern       = '\s*\(' .a:pattern. '\)\s*'
  for line in range(a:fl, a:ll)
    let tokens = split(a:lc ?
                      \ strpart(getline(line), a:fc - 1, a:lc - a:fc + 1) :
                      \ strpart(getline(line), a:fc - 1),
                      \ pattern.'\zs')
    if empty(tokens)
      continue
    endif

    let max_tokens = max([len(tokens), max_tokens])
    let nth        = match(tokens[0], '^\s*$') != -1 ? a:nth + 1 : a:nth

    if len(tokens) < nth
      continue
    endif

    let last   = tokens[nth - 1]
    let prefix = (nth > 1 ? join(tokens[0 : nth - 2], '') : '') . substitute(last, pattern.'$', '', '')
    let suffix = join(tokens[nth : -1], '')

    if match(last, pattern.'$') == -1
      continue
    endif

    let delim         = matchlist(tokens[nth - 1], pattern)[1]
    let just_len      = max([len(prefix), just_len])
    let max_delim_len = max([len(delim), max_delim_len])
    let lines[line]   = [prefix, suffix, delim]
  endfor

  for [line, tokens] in items(lines)
    let [prefix, suffix, delim] = tokens

    let pad = repeat(' ', just_len - len(prefix))
    if a:stick_to_left
      let suffix = pad . suffix
    else
      let prefix = prefix . pad
    endif

    let delim   = repeat(' ', max_delim_len - len(delim)). delim
    let cline   = getline(line)
    let before  = strpart(cline, 0, a:fc - 1)
    let after   = a:lc ? strpart(cline, a:lc) : ''

    let ml      = empty(prefix) ? '' : a:ml
    let mr      = (empty(suffix . after) || (empty(suffix) && stridx(after, a:mr) == 0)) ? '' : a:mr
    let aligned = join([prefix, ml, delim, mr, suffix], '')
    let aligned = empty(after) ? substitute(aligned, '\s*$', '', '') : aligned

    call setline(line, before.aligned.after)
  endfor

  if a:recursive && a:nth < max_tokens
    call s:do_align(a:fl, a:ll, a:fc, a:lc, a:pattern, a:nth + 1, a:ml, a:mr, a:stick_to_left, a:recursive)
  endif
endfunction

function! easy_align#align(...) range
  let recursive = 0
  let n         = ''
  let ch        = ''

  if a:0 == 0
    echon "\reasy-align ()"
    while 1
      let c  = getchar()
      let ch = nr2char(c)
      if c == 3 || c == 27
        return
      elseif c >= 48 && c <= 57
        if n == '*'
          echon "\rField number(*) already specified"
          return
        endif
        let n = n . nr2char(c)
        echon "\reasy-align (". n .")"
      elseif ch == '*'
        if !empty(n)
          echon "\rField number(". n .") already specified"
          return
        endif
        let n = '*'
        echon "\reasy-align (*)"
      else
        break
      endif
    endwhile
  elseif a:0 == 1
    let tokens = matchlist(a:1, '^\([1-9][0-9]*\|\*\)\?\(.\)$')
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
  elseif empty(n)
    let n = 1
  elseif n != string(str2nr(n))
    echon "\rInvalid field number: ". n
    return
  endif

  if has_key(g:easy_align_delimiters_merged, ch)
    let dict = g:easy_align_delimiters_merged[ch]
    call s:do_align(a:firstline, a:lastline,
                  \ visualmode() == '' ? min([col("'<"), col("'>")]) : 1,
                  \ visualmode() == '' ? max([col("'<"), col("'>")]) : 0,
                  \ get(dict, 'pattern', ch),
                  \ n,
                  \ get(dict, 'margin_left', ' '),
                  \ get(dict, 'margin_right', ' '),
                  \ get(dict, 'stick_to_left', 0), recursive)
    echon "\reasy-align (". (recursive ? '*' : n) . ch .")"
  else
    echon "\rUnknown delimiter: ". ch
  endif
endfunction

