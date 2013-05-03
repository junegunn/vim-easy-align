if exists("g:easy_align_loaded")
  finish
endif
let g:easy_align_loaded = 1

let s:easy_align_delimiters_default = {
\  ' ': { 'pattern': ' ',  'margin_left': '',  'margin_right': '',  'stick_to_left': 0 },
\  '=': { 'pattern': '<=>\|\(&&\|||\|<<\|>>\)=\|=\~\|=>\|[:+/*!%^=><&|-]\?=',
\                          'margin_left': ' ', 'margin_right': ' ', 'stick_to_left': 0 },
\  ':': { 'pattern': ':',  'margin_left': '',  'margin_right': ' ', 'stick_to_left': 1 },
\  ',': { 'pattern': ',',  'margin_left': '',  'margin_right': ' ', 'stick_to_left': 1 },
\  '|': { 'pattern': '|',  'margin_left': ' ', 'margin_right': ' ', 'stick_to_left': 0 },
\  '.': { 'pattern': '\.', 'margin_left': '',  'margin_right': '',  'stick_to_left': 0 }
\ }

let s:just = ['L', 'R', 'C']

function! s:do_align(just, fl, ll, fc, lc, pattern, nth, ml, mr, stick_to_left, recursive)
  let lines          = {}
  let max_token_len  = 0
  let max_delim_len  = 0
  let max_prefix_len = 0
  let max_tokens     = 0
  let pattern        = '\s*\(' .a:pattern. '\)\s*'
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
    let prefix = (nth > 1 ? join(tokens[0 : nth - 2], '') : '')
    let token  = substitute(last, pattern.'$', '', '')
    let suffix = join(tokens[nth : -1], '')

    if match(last, pattern.'$') == -1
      if !exists("g:easy_align_ignore_unmatched") || g:easy_align_ignore_unmatched
        continue
      else
        let delim = ''
      endif
    else
      let delim = matchlist(last, pattern)[1]
    endif

    let max_token_len  = max([len(token), max_token_len])
    let max_prefix_len = max([len(prefix), max_prefix_len])
    let max_delim_len  = max([len(delim), max_delim_len])
    let lines[line]    = [prefix, token, delim, suffix]
  endfor

  for [line, tokens] in items(lines)
    let [prefix, token, delim, suffix] = tokens

    let pad = repeat(' ', max_token_len - len(token) + max_prefix_len - len(prefix))
    if a:just == 0
      if a:stick_to_left
        let suffix = pad . suffix
      else
        let token = token . pad
      endif
    elseif a:just == 1
      let token = pad . token
    else
      let p1 = strpart(pad, 0, len(pad) / 2)
      let p2 = strpart(pad, len(pad) / 2)
      if a:stick_to_left
        let token = p1 . token
        let suffix = p2 . suffix
      else
        let token = p1. token .p2
      endif
    endif

    let delim   = repeat(' ', max_delim_len - len(delim)). delim
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
  echon "\rEasyAlign[". s:just[a:l] ."] (" .a:n.a:d. ")"
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
      elseif c == 13
        let just = (just + 1) % len(s:just)
      elseif c >= 48 && c <= 57
        if n == '*'
          break
        else
          let n = n . nr2char(c)
        endif
      elseif ch == '*'
        if !empty(n)
          break
        else
          let n = '*'
        endif
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

  let delimiters = extend(copy(s:easy_align_delimiters_default),
                  \ exists("g:easy_align_delimiters") ? g:easy_align_delimiters : {})

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

