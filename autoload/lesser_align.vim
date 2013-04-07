if exists("g:lesser_align_loaded")
  finish
endif
let g:lesser_align_loaded = 1

function! s:do_align(fl, ll, pattern, nth, ml, mr, ljust, recursive)
  let lines         = {}
  let just_len      = 0
  let max_delim_len = 0
  let max_tokens    = 0
  let pattern       = '\s*\(' .a:pattern. '\)\s*'
  for line in range(a:fl, a:ll)
    let tokens     = split(getline(line), pattern.'\zs')
    let max_tokens = len(tokens) > max_tokens ? len(tokens) : max_tokens

    if len(tokens) < a:nth
      continue
    endif

    let nth    = match(tokens[0], '^\s*$') != -1 ? a:nth + 1 : a:nth
    let last   = tokens[nth - 1]
    let before = (nth > 1 ? join(tokens[0 : nth - 2], '') : '') . substitute(last, pattern.'$', '', '')
    let after  = join(tokens[nth : -1], '')

    if match(last, pattern.'$') == -1
      continue
    endif

    let delim         = matchlist(tokens[nth - 1], pattern)[1]
    let just_len      = len(before) > just_len ? len(before) : just_len
    let max_delim_len = len(delim) > max_delim_len ? len(delim) : max_delim_len
    let lines[line]   = [before, after, delim]
  endfor

  for [line, tokens] in items(lines)
    let [prefix, suffix, delim] = tokens
    let pad = just_len - len(prefix)
    if pad > 0
      for i in range(pad)
        if a:ljust
          let suffix = ' '. suffix
        else
          let prefix = prefix . ' '
        endif
      endfor
    endif
    let pad = max_delim_len - len(delim)
    if pad > 0
      for i in range(pad)
        let delim = ' '. delim
      endfor
    endif
    let ml = empty(prefix) ? '' : a:ml
    let mr = empty(suffix) ? '' : a:mr
    call setline(line, substitute(join([prefix, ml, delim, mr, suffix], ''), '\s*$', '', ''))
  endfor

  if a:recursive && a:nth < max_tokens
    call s:do_align(a:fl, a:ll, a:pattern, a:nth + 1, a:ml, a:mr, a:ljust, a:recursive)
  endif
endfunction

function! lesser_align#align() range
  echon "\rlesser-align ()"
  let n = ''
  let recursive = 0

  while 1
    let c  = getchar()
    let ch = nr2char(c)
    if c == 3 || c == 27
      return
    elseif c >= 48 && c <= 57
      if recursive
        echo "Number(*) already specified"
        return
      endif
      let n = n . nr2char(c)
      echon "\rlesser-align (". n .")"
    elseif ch == '*'
      if !empty(n)
        echo "Number already specified"
        return
      endif
      let recursive = 1
      echon "\rlesser-align (*)"
    else
      break
    endif
  endwhile

  let n = empty(n) ? 1 : n

  let error = 0
  if ch == ' '
    call s:do_align(a:firstline, a:lastline, ' ', n, '', '', 0, recursive)
  elseif ch == '='
    call s:do_align(a:firstline, a:lastline, '<=>\|&&=\|||=\|=\~\|=>\|[:+/*!%^=-]\?=', n, ' ', ' ', 0, recursive)
  elseif ch == ':'
    call s:do_align(a:firstline, a:lastline, ':', n, '', ' ', 1, recursive)
  elseif ch == ','
    call s:do_align(a:firstline, a:lastline, ',', n, '', ' ', 1, recursive)
  elseif ch == '|'
    call s:do_align(a:firstline, a:lastline, '|', n, ' ', ' ', 0, recursive)
  else
    let error = 1
  endif

  if error
    echon "\rUnknown delimiter: ". ch
  else
    echon "\rlesser-align (". (recursive ? '*' : n) . ch .")"
  endif
endfunction

