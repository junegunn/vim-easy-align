vim: set scrolloff=1 buftype=nofile colorcolumn=:

vim-easy-align examples
=======================

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

```

Paul McCartney 1942
George Harrison 1943
Ringo Starr 1940
Pete Best 1941

```


Formatting table
----------------

| Option| Type | Default | Description |
|--|--|--|--|
| threads | Fixnum | 1 | number of threads in the thread pool |
|queues |Fixnum | 1 | number of concurrent queues |
|queue_size | Fixnum | 1000 | size of each queue |
|   interval | Numeric | 0 | dispatcher interval for batch processing |
|batch | Boolean | false | enables batch processing mode |
 |batch_size | Fixnum | nil | number of maximum items to be assigned at once |
 |logger | Logger | nil | logger instance for debug logs |


Alignment around =
------------------

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

```ruby

options = { :caching => nil,
            :versions => 3,
            "cache=blocks" => false }.merge(options)

```

Commas
------

```

aaa,   bb,c
d,eeeeeee
fffff, gggggggggg,
h, ,           ii
j,,k

```

Ignoring delimiters in comments and strings
-------------------------------------------

```c
/* a */ b = c
aa >= bb
// aaa = bbb = cccc
/* aaaa = */ bbbb   === cccc   " = dddd = " = eeee
aaaaa /* bbbbb */      == ccccc /* != eeeee = */ === fffff
```

