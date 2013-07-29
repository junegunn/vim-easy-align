vim-easy-align
==============

A simple, easy-to-use Vim alignment plugin without too much ambition.

Features:

- Optimized for code editing
- Requires minimal keystrokes
- Extensible alignment rules
- Aligns text around either _all or n-th_ occurrence(s) of the delimiter
- Ignores delimiters in certain syntax highlighting groups (e.g. comments, strings)
- Ignores lines without a matching delimiter

Demo
----

![Screencast](https://raw.github.com/junegunn/vim-easy-align/gif/vim-easy-align.gif)

Installation
------------

Either [download zip file](http://www.vim.org/scripts/script.php?script_id=4520)
and extract in ~/.vim or use [Vundle](https://github.com/gmarik/vundle) (recommended)
or [Pathogen](https://github.com/tpope/vim-pathogen).

### With Vundle

```vim
Bundle 'junegunn/vim-easy-align'
```

Usage
-----

_vim-easy-align_ defines interactive `:EasyAlign` command in the visual mode.
For convenience, it is advised that you define a mapping for triggering it in your `.vimrc`.

```vim
vnoremap <silent> <Enter> :EasyAlign<cr>
```

With the mapping, you can align selected lines with a few keystrokes.

1. `<Enter>` key to start interactive EasyAlign command
1. Optional Enter keys to toggle right-justification mode
1. Optional field number (default: 1)
    - `1`         Around the 1st occurrences of delimiters
    - `2`         Around the 2nd occurrences of delimiters
    - ...
    - `*`         Around all occurrences of delimiters
    - `**`        Left-right alternating alignment around all delimiters
    - `-`         Around the last occurrences of delimiters (`-1`)
    - `-2`        Around the second to last occurrences of delimiters
    - ...
1. Delimiter key (a single keystroke; `<space>`, `=`, `:`, `.`, `|`, `,`)

Alignment rules for the following delimiters have been defined to meet the most needs.

| Delimiter key | Description/Use cases                                      |
| ------------- | ---------------------------------------------------------- |
| `<space>`     | General alignment around spaces                            |
| `=`           | Operators containing equals sign (=, ==, !=, +=, &&=, ...) |
| `:`           | Suitable for formatting JSON or YAML                       |
| `.`           | Multi-line method chaining                                 |
| `,`           | Multi-line method arguments                                |
| &#124;        | Table markdown                                             |

### Example command sequences

| With visual map     | Description                                              | Equivalent command        |
| ------------------- | -------------------------------------------------------- | ------------------------- |
| `<Enter><space>`    | Alignment around 1st whitespaces                         | `:'<,'>EasyAlign\ `       |
| `<Enter>2<space>`   | Alignment around 2nd whitespaces                         | `:'<,'>EasyAlign2\ `      |
| `<Enter>-<space>`   | Alignment around the last whitespaces                    | `:'<,'>EasyAlign-\ `      |
| `<Enter>:`          | Alignment around 1st colon                               | `:'<,'>EasyAlign:`        |
| `<Enter>=`          | Alignment around 1st equals signs (and the likes)        | `:'<,'>EasyAlign=`        |
| `<Enter>2=`         | Alignment around 2nd equals signs (and the likes)        | `:'<,'>EasyAlign2=`       |
| `<Enter>3=`         | Alignment around 3rd equals signs (and the likes)        | `:'<,'>EasyAlign3=`       |
| `<Enter>*=`         | Alignment around all equals signs (and the likes)        | `:'<,'>EasyAlign*=`       |
| `<Enter>**=`        | Left-right alternating alignment around all equals signs | `:'<,'>EasyAlign**=`      |
| `<Enter><Enter>=`   | Right-justified alignment around 1st equals signs        | `:'<,'>EasyAlignRight=`   |
| `<Enter><Enter>**=` | Right-left alternating alignment around all equals signs | `:'<,'>EasyAlignRight**=` |
| ...                 | ...                                                      |                           |

### Partial alignment in blockwise-visual mode

In blockwise-visual mode (`CTRL-V`), EasyAlign command aligns only the selected
text in the block, instead of the whole lines in the range.

Consider the following case where you want to align text around `=>` operators.

```ruby
my_hash = { :a => 1,
            :aa => 2,
            :aaa => 3 }
```

In non-blockwise visual mode (`v` / `V`), `<Enter>=` won't work since the assignment
operator in the first line gets in the way.
So we instead enter blockwise-visual mode (`CTRL-V`), and select the text *around*
`=>` operators, then press `<Enter>=`.

```ruby
my_hash = { :a   => 1,
            :aa  => 2,
            :aaa => 3 }
```

However, in this case, we don't really need blockwise visual mode
since the same can be easily done using the negative field number: `<Enter>-=`

Options
-------

| Option                        | Type       | Default               | Description                                           |
| ----------------------------- | ---------- | --------------------- | ----------------------------------------------------- |
| g:easy_align_ignores          | list       | ['String', 'Comment'] | Ignore delimiters in these syntax highlighting groups |
| g:easy_align_ignore_unmatched | boolean    | `1`                   | Ignore lines without matching delimiter               |
| g:easy_align_delimiters       | dictionary | `{}`                  | Extend or override alignment rules                    |

### Ignoring delimiters in comments or strings

EasyAlign can be configured to ignore delimiters in certain highlight groups,
such as code comments or strings. By default, delimiters that are highlighted as
code comments or strings are ignored.

```vim
" Default:
"   If a delimiter is in a highlight group whose name matches
"   any of the followings, it will be ignored.
let g:easy_align_ignores = ['Comment', 'String']
```

For example,

```ruby
{
  # Quantity of apples: 1
  apple: 1,
  # Quantity of bananas: 2
  bananas: 2,
  # Quantity of grape:fruits: 3
  'grape:fruits': 3
}
```

becomes

```ruby
{
  # Quantity of apples: 1
  apple:          1,
  # Quantity of bananas: 2
  bananas:        2,
  # Quantity of grape:fruits: 3
  'grape:fruits': 3
}
```

Naturally, this only works when syntax highlighting is enabled.

You can override `g:easy_align_ignores` to change the rule.

```vim
" Ignore nothing!
let g:easy_align_ignores = []
```

Then you get,

```ruby
{
  # Quantity of apples:  1
  apple:                 1,
  # Quantity of bananas: 2
  bananas:               2,
  # Quantity of grape:   fruits: 3
  'grape:                fruits': 3
}
```

Satisfied? :satisfied:

### Ignoring unmatched lines

Lines without a matching delimiter are ignored as well (except in
right-justification mode).

For example, when aligning the following code block around the colons,

```ruby
{
  apple: proc {
    this_line_does_not_have_a_colon
  },
  bananas: 2,
  grapefruits: 3
}
```

this is usually what we want.

```ruby
{
  apple:       proc {
    this_line_does_not_have_a_colon
  },
  bananas:     2,
  grapefruits: 3
}
```

However, this default behavior is also configurable.

```vim
let g:easy_align_ignore_unmatched = 0
```

Then we get,

```ruby
{
  apple:                             proc {
    this_line_does_not_have_a_colon
  },
  bananas:                           2,
  grapefruits:                       3
}
```

### Extending alignment rules

```vim
" Examples
let g:easy_align_delimiters = {
\ '>': { 'pattern': '>>\|=>\|>' },
\ '/': { 'pattern': '//\+\|/\*\|\*/' },
\ '#': { 'pattern': '#\+' },
\ ']': {
\     'pattern':       '[\[\]]',
\     'margin_left':   '',
\     'margin_right':  '',
\     'stick_to_left': 0
\   },
\ ')': {
\     'pattern':       '[()]',
\     'margin_left':   '',
\     'margin_right':  '',
\     'stick_to_left': 0
\   }
\ }
```

Author
------

[Junegunn Choi](https://github.com/junegunn)

License
-------

MIT
