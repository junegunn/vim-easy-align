vim-easy-align examples
=======================

The description in this document assumes that you have defined this mapping.

```vim
vnoremap <silent> <Enter> :EasyAlign<cr>
```

To enable syntax highlighting in the code blocks, define and call the following
function.

```vim
function! GFM()
  let syntaxes = {
  \ 'ruby':   'syntax/ruby.vim',
  \ 'yaml':   'syntax/yaml.vim',
  \ 'vim':    'syntax/vim.vim',
  \ 'c':      'syntax/c.vim'
  \ }

  for [lang, syn] in items(syntaxes)
    unlet b:current_syntax
    silent! exec printf("syntax include @%s %s", lang, syn)
    exec printf("syntax region %sSnip matchgroup=Snip start='```%s' end='```' contains=@%s",
                \ lang, lang, lang)
  endfor
  let b:current_syntax='mkd'
endfunction
```

Alignment around whitespaces
----------------------------

You can align text around whitespaces with `<space>` delimiter key.

Try these commands:
- `<Enter><space>`
- `<Enter>2<space>`
- `<Enter>*<space>`
- `<Enter>-<space>`
- `<Enter>-2<space>`
- `<Enter><Enter><space>`
- `<Enter><Enter>*<space>`

### Example

```

Paul McCartney 1942
George Harrison 1943
Ringo Starr 1940
Pete Best 1941

```

Formatting table
----------------

Try these commands:
- `<Enter>*|`
- `<Enter>**|`
- `<Enter><Enter>*|`
- `<Enter><Enter>**|`

### Example

```

| Option| Type | Default | Description |
|--|--|--|--|
| threads | Fixnum | 1 | number of threads in the thread pool |
|queues |Fixnum | 1 | number of concurrent queues |
|queue_size | Fixnum | 1000 | size of each queue |
|   interval | Numeric | 0 | dispatcher interval for batch processing |
|batch | Boolean | false | enables batch processing mode |
 |batch_size | Fixnum | nil | number of maximum items to be assigned at once |
 |logger | Logger | nil | logger instance for debug logs |

```


Alignment around =
------------------

The default rule for delimiter key `=` aligns around a whole family of operators
containing `=` character.

Try these commands:
- `<Enter>=`
- `<Enter>*=`
- `<Enter>**=`
- `<Enter><Enter>**=`

### Example

```ruby

a =
a = 1
bbbb = 2
ccccccc = 3
ccccccccccccccc
ddd = 4
eeee === eee = eee = eee=f
fff = ggg += gg &&= gg
g != hhhhhhhh == 888
i   := 5
i     %= 5
i       *= 5
j     =~ 5
j   >= 5
aa      =>         123
aa <<= 123
aa        >>= 123
bbb               => 123
c     => 1233123
d   =>      123
dddddd &&= 123
dddddd ||= 123
dddddd /= 123
gg <=> ee

```

Formatting YAML (or JSON)
-------------------------

Try `<Enter>:` here, to align text around only the first occurrences of colons.
In this case, you don't want to align around all the colons: `<Enter>*:`.

```yaml

mysql:
  # JDBC driver for MySQL database:
  driver: com.mysql.jdbc.Driver
  # JDBC URL for the connection (jdbc:mysql://HOSTNAME/DATABASE)
  url: jdbc:mysql://localhost/test
  database: test
  "user:pass":r00t:pa55

```

Partial alignment in block-visual mode / Negative field index
-------------------------------------------------------------

You can try one of these:
- Select text around `=>` in block-wise visual mode (`<Ctrl>-V`) and `<Enter>=`
- `<Enter>-=`

```ruby

options = { :caching => nil,
            :versions => 3,
            "cache=blocks" => false }.merge(options)

```

Commas
------

There is also a predefined rule for commas, try `<Enter>*,` for the following
lines.

```

aaa,   bb,c
d,eeeeeee
fffff, gggggggggg,
h, ,           ii
j,,k

```

Ignoring delimiters in comments and strings
-------------------------------------------

Delimiters highlighted as comments or strings are ignored by default, try
`<Enter>*=` on the following lines.

```c

/* a */ b = c
aa >= bb
// aaa = bbb = cccc
/* aaaa = */ bbbb   === cccc   " = dddd = " = eeee
aaaaa /* bbbbb */      == ccccc /* != eeeee = */ === fffff

```

Aligning in-line comments
-------------------------

```ruby
apple = 1 # comment not aligned
banana = 'Gros Michel' # comment 2
```

So, how do we align the trailing comments in the above lines?
Simply try `<Enter>-<space>`! The spaces in the comments are ignored, so the
trailing comment in each line is considered to be a single chunk.

But this doesn't work in the following case.

```ruby
apple = 1 # comment not aligned
apricot = 'DAD' + 'F#AD'
banana = 'Gros Michel' # comment 2
```

That is because the second line doesn't have trailing comment, and
the last space (`-`) for that line is the one just before `'F#AD'`.

So, let's define a custom mapping for `#`.

```vim
if !exists('g:easy_align_delimiters')
  let g:easy_align_delimiters = {}
endif
let g:easy_align_delimiters['#'] = { 'pattern': '#\+', 'ignores': ['String'] } }
```

Notice that the rule overrides `ignores` attribute in order *not to ignore*
delimiters highlighted as comments.

Then on `<Enter>#`, we get

```ruby
apple = 1         # comment not aligned
apricot = 'A#B'
banana = 'string' # comment 2
```

