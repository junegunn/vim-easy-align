easy-align examples
===================

Open this document in your Vim and try it yourself.

This document assumes that you have the following mappings in your .vimrc.

```vim
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
```

You can use either of the maps. Place the cursor on the paragraph and press

- `gaip` "(ga) start easy-align on (i)nner (p)aragraph"
- or `vipga` "(v)isual-select (i)nner (p)aragraph and (ga) start easy-align"

To enable syntax highlighting in the code blocks, define and call the following
function.

```vim
function! GFM()
  let langs = ['ruby', 'yaml', 'vim', 'c']

  for lang in langs
    unlet b:current_syntax
    silent! exec printf("syntax include @%s syntax/%s.vim", lang, lang)
    exec printf("syntax region %sSnip matchgroup=Snip start='```%s' end='```' contains=@%s",
                \ lang, lang, lang)
  endfor
  let b:current_syntax='mkd'

  syntax sync fromstart
endfunction
```

Alignment around whitespaces
----------------------------

You can align text around whitespaces with `<space>` delimiter key.

Start the interactive mode as described above (`gaip` or `vipga`) and try
these commands:

- `<space>`
- `2<space>`
- `*<space>`
- `-<space>`
- `-2<space>`
- `<Enter><space>`
- `<Enter>*<space>`
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

Again, start the interactive mode and try these commands:

- `*|`
- `**|`
- `<Enter>*|`
- `<Enter>**|`
- `<Enter><Enter>*|`

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

The default rule for delimiter key `=` aligns around a whole family of
operators containing `=` character.

Try these commands in the interactive mode.

- `=`
- `*=`
- `**=`
- `<Enter>**=`
- `<Enter><Enter>*=`

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

You can use `:`-rule here to align text around only the first occurrences of
colons. In this case, you don't want to align around all the colons: `*:`.

```yaml
mysql:
  # JDBC driver for MySQL database:
  driver: com.mysql.jdbc.Driver
  # JDBC URL for the connection (jdbc:mysql://HOSTNAME/DATABASE)
  url: jdbc:mysql://localhost/test
  database: test
  "user:pass":r00t:pa55
```

Formatting multi-line method chaining
-------------------------------------

Try `.` or `*.` on the following lines.

```ruby
my_object
      .method1().chain()
    .second_method().call()
      .third().call()
     .method_4().execute()
```

Notice that the indentation is adjusted to match the shortest one among those of
the lines starting with the delimiter.

```ruby
my_object
    .method1()      .chain()
    .second_method().call()
    .third()        .call()
    .method_4()     .execute()
```


Using blockwise-visual mode or negative N-th parameter
------------------------------------------------------

You can try either:
- select text around `=>` in blockwise-visual mode (`CTRL-V`) and `ga=`
- or `gaip-=`

```ruby
options = { :caching => nil,
            :versions => 3,
            "cache=blocks" => false }.merge(options)
```

Commas
------

There is also a predefined rule for commas, try `*,`.

```
aaa,   bb,c
d,eeeeeee
fffff, gggggggggg,
h, ,           ii
j,,k
```

Ignoring delimiters in comments or strings
------------------------------------------

Delimiters highlighted as comments or strings are ignored by default, try
`gaip*=` on the following lines.

```c

/* a */ b = c
aa >= bb
// aaa = bbb = cccc
/* aaaa = */ bbbb   === cccc   " = dddd = " = eeee
aaaaa /* bbbbb */      == ccccc /* != eeeee = */ === fffff

```

This only works when syntax highlighting is enabled.

Aligning in-line comments
-------------------------

*Note: Since the current version provides '#'-rule as one of the default rules,
you can ignore this section.*

```ruby
apple = 1 # comment not aligned
banana = 'Gros Michel' # comment 2
```

So, how do we align the trailing comments in the above lines? Simply try
`-<space>`. The spaces in the comments are ignored, so the trailing comment in
each line is considered to be a single chunk.

But that doesn't work in the following case.

```ruby
apple = 1 # comment not aligned
apricot = 'DAD' + 'F#AD'
banana = 'Gros Michel' # comment 2
```

That is because the second line doesn't have trailing comment, and
the last (`-`) space for that line is the one just before `'F#AD'`.

So, let's define a custom mapping for `#`.

```vim
if !exists('g:easy_align_delimiters')
  let g:easy_align_delimiters = {}
endif
let g:easy_align_delimiters['#'] = { 'pattern': '#', 'ignore_groups': ['String'] }
```

Notice that the rule overrides `ignore_groups` attribute in order *not to ignore*
delimiters highlighted as comments.

Then on `#`, we get

```ruby
apple = 1         # comment not aligned
apricot = 'DAD' + 'F#AD'
banana = 'string' # comment 2
```

If you don't want to define the rule, you can do the same with the following
command:

```vim
" Using regular expression /#/
" - "ig" is a shorthand notation of "ignore_groups"
:EasyAlign/#/{'ig':['String']}

" Or more concisely with the shorthand notation;
:EasyAlign/#/ig['String']
```

In this case, the second line is ignored as it doesn't contain a `#` (The one
in `'F#AD'` is ignored as it's highlighted as String). If you don't want the
second line to be ignored, there are three options:

1. Set global `g:easy_align_ignore_unmatched` flag to 0
2. Use `:EasyAlign` command with `ignore_unmatched` option
3. Update the alignment rule with `ignore_unmatched` option

```vim
" 1. Set global g:easy_align_ignore_unmatched to zero
let g:easy_align_ignore_unmatched = 0

" 2. Using :EasyAlign command with ignore_unmatched option
" 2-1. Using predefined rule with delimiter key #
"      - "iu" is expanded to "*i*gnore_*u*nmatched"
:EasyAlign#{'iu':0}
" or
:EasyAlign#iu0

" 2-2. Using regular expression /#/
:EasyAlign/#/ig['String']iu0

" 3. Update the alignment rule with ignore_unmatched option
let g:easy_align_delimiters['#'] = {
  \ 'pattern': '#', 'ignore_groups': ['String'], 'ignore_unmatched': 0 }
```

Then we get,

```ruby
apple = 1                # comment not aligned
apricot = 'DAD' + 'F#AD'
banana = 'string'        # comment 2
```

Aligning C-style variable definition
------------------------------------

Take the following example:

```c
const char* str = "Hello";
int64_t count = 1 + 2;
static double pi = 3.14;
```

We can align these lines with the predefined `=` rule. Select the lines and
press `ga=`

```c
const char* str  = "Hello";
int64_t count    = 1 + 2;
static double pi = 3.14;
```

Not bad. However, the names of the variables, `str`, `count`, and `pi` are not
aligned with each other. Can we do better? We can clearly see that simple
`<space>`-rule won't properly align those names.
So let's define an alignment rule than can handle this case.

```vim
let g:easy_align_delimiters['d'] = {
\ 'pattern': '\(const\|static\)\@<! ',
\ 'left_margin': 0, 'right_margin': 0
\ }
```

This new rule aligns text around spaces that are *not* preceded by
`const` or `static`. Let's select the lines and try `gad`.

```c
const char*   str = "Hello";
int64_t       count = 1 + 2;
static double pi = 3.14;
```

Okay, the names are now aligned. We select the lines again with `gv`, and then
press `ga=` to finish our alignment.

```c
const char*   str   = "Hello";
int64_t       count = 1 + 2;
static double pi    = 3.14;
```

So far, so good. However, this rule is not sufficient to handle more complex
cases involving C++ templates or Java generics. Take the following example:

```c
const char* str = "Hello";
int64_t count = 1 + 2;
static double pi = 3.14;
static std::map<std::string, float>*    scores = pointer;
```

We see that our rule above doesn't work anymore.

```c
const char*                  str = "Hello";
int64_t                      count = 1 + 2;
static double                pi = 3.14;
static std::map<std::string, float>*    scores = pointer;
```

So what do we do? Let's try to improve our alignment rule.

```vim
let g:easy_align_delimiters['d'] = {
\ 'pattern': ' \ze\S\+\s*[;=]',
\ 'left_margin': 0, 'right_margin': 0
\ }
```

Now the new rule has changed to align text around spaces that are followed
by some non-whitespace characters and then an equals sign or a semi-colon.
Try `vipgad`

```c
const char*                          str = "Hello";
int64_t                              count = 1 + 2;
static double                        pi = 3.14;
static std::map<std::string, float>* scores = pointer;
```

We're right on track, now press `gvga=` and voila!

```c
const char*                          str    = "Hello";
int64_t                              count  = 1 + 2;
static double                        pi     = 3.14;
static std::map<std::string, float>* scores = pointer;
```

