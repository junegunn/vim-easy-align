vim-easy-align
==============

A simple, easy-to-use Vim alignment plugin without too much ambition.

Demo
----

![Screencast](https://raw.github.com/junegunn/vim-easy-align/gif/vim-easy-align.gif)

Features
--------

- Optimized for code editing
- Designed to require minimal keystrokes
- Extensible alignment rules
- Supports arbitrary regular expressions
- Aligns text around either _all or n-th_ occurrence(s) of the delimiter
- Ignores delimiters in certain syntax highlight groups (e.g. comments, strings)
- Ignores lines without a matching delimiter

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

_vim-easy-align_ defines `:EasyAlign` command (and the right-justification
variant `:EasyAlign!`) in the visual mode.

| Mode                      | Command                                       |
| ------------------------- | --------------------------------------------- |
| Interactive mode          | `:EasyAlign`                                  |
| Using predefined rules    | `:EasyAlign [FIELD#] DELIMITER_KEY [OPTIONS]` |
| Using regular expressions | `:EasyAlign [FIELD#] /REGEXP/ [OPTIONS]`      |

### Interactive mode

The command will go into the interactive mode when no argument is given.
For convenience, it is advised that you define a mapping for triggering it in
your `.vimrc`.

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

#### Example command sequences

| With visual map     | Description                                              | Equivalent command    |
| ------------------- | -------------------------------------------------------- | --------------------- |
| `<Enter><space>`    | Alignment around 1st whitespaces                         | `:'<,'>EasyAlign\ `   |
| `<Enter>2<space>`   | Alignment around 2nd whitespaces                         | `:'<,'>EasyAlign2\ `  |
| `<Enter>-<space>`   | Alignment around the last whitespaces                    | `:'<,'>EasyAlign-\ `  |
| `<Enter>:`          | Alignment around 1st colon                               | `:'<,'>EasyAlign:`    |
| `<Enter>=`          | Alignment around 1st equals signs (and the likes)        | `:'<,'>EasyAlign=`    |
| `<Enter>2=`         | Alignment around 2nd equals signs (and the likes)        | `:'<,'>EasyAlign2=`   |
| `<Enter>3=`         | Alignment around 3rd equals signs (and the likes)        | `:'<,'>EasyAlign3=`   |
| `<Enter>*=`         | Alignment around all equals signs (and the likes)        | `:'<,'>EasyAlign*=`   |
| `<Enter>**=`        | Left-right alternating alignment around all equals signs | `:'<,'>EasyAlign**=`  |
| `<Enter><Enter>=`   | Right-justified alignment around 1st equals signs        | `:'<,'>EasyAlign!=`   |
| `<Enter><Enter>**=` | Right-left alternating alignment around all equals signs | `:'<,'>EasyAlign!**=` |
| ...                 | ...                                                      |                       |

### Non-interactive mode

Instead of going into the interactive mode, you can type in arguments to
`:EasyAlign` command. In non-interactive mode, you can even use arbitrary
regular expressions.

```vim
" Using predefined alignment rules
:EasyAlign[!] [FIELD#] DELIMITER_KEY [OPTIONS]

" Using arbitrary regular expressions
:EasyAlign[!] [FIELD#] /REGEXP/ [OPTIONS]
```

For example, when aligning the following lines around colons and semi-colons,

    apple;:banana::cake
    data;;exchange:;format

try these commands:

- `:EasyAlign /[:;]\+/`
- `:EasyAlign 2/[:;]\+/`
- `:EasyAlign */[:;]\+/`
- `:EasyAlign **/[:;]\+/`

Notice that you can't append `\zs` to your regular expression to put delimiters
on the left. It can be done by providing additional options in Vim dictionary
format.

- `:EasyAlign * /[:;]\+/ { 'stick_to_left': 1, 'left_margin': '' }`

Then we get:

    apple;: banana::   cake
    data;;  exchange:; format

Options keys are fuzzy-matched, so you can write as follows:

- `:EasyAlign * /[:;]\+/ { 'stl': 1, 'l': 0 }`

You can even omit spaces between the arguments, so concisely (or cryptically):

- `:EasyAlign*/[:;]\+/{'s':1,'l':0}`

Available options for each alignment are as follows.

| Atrribute        | Type             | Default                 |
| ---------------- | ---------------- | ----------------------- |
| left_margin      | number or string | 0                       |
| right_margin     | number or string | 0                       |
| stick_to_left    | boolean          | 0                       |
| ignore_unmatched | boolean          | 1                       |
| ignores          | array            | `['String', 'Comment']` |

(The last two options will be described shortly in the following sections.)

### Partial alignment in blockwise-visual mode

In blockwise-visual mode (`CTRL-V`), EasyAlign command aligns only the selected
text in the block, instead of the whole lines in the range.

Consider the following case where you want to align text around `=>` operators.

```ruby
my_hash = { :a => 1,
            :aa => 2,
            :aaa => 3 }
```

In non-blockwise visual mode (`v` / `V`), `<Enter>=` won't work since the
assignment operator in the first line gets in the way. So we instead enter
blockwise-visual mode (`CTRL-V`), and select the text *around*
`=>` operators, then press `<Enter>=`.

```ruby
my_hash = { :a   => 1,
            :aa  => 2,
            :aaa => 3 }
```

However, in this case, we don't really need blockwise visual mode
since the same can be easily done using the negative field number: `<Enter>-=`

Global options
--------------

| Option                        | Type       | Default                 | Description                                        |
| ----------------------------- | ---------- | ----------------------- | -------------------------------------------------- |
| g:easy_align_ignores          | list       | `['String', 'Comment']` | Ignore delimiters in these syntax highlight groups |
| g:easy_align_ignore_unmatched | boolean    | `1`                     | Ignore lines without matching delimiter            |
| g:easy_align_delimiters       | dictionary | `{}`                    | Extend or override alignment rules                 |

### Ignoring delimiters in comments or strings

EasyAlign can be configured to ignore delimiters in certain syntax highlight
groups, such as code comments or strings. By default, delimiters that are
highlighted as code comments or strings are ignored.

```vim
" Default:
"   If a delimiter is in a highlight group whose name matches
"   any of the followings, it will be ignored.
let g:easy_align_ignores = ['Comment', 'String']
```

For example, the following paragraph

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

becomes as follows on `<Enter>:` (or `:EasyAlign:`)

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

Naturally, this feature only works when syntax highlighting is enabled.

You can change the default rule by either defining global `g:easy_align_ignores`
array,

```vim
" Ignore nothing!
let g:easy_align_ignores = []
```

or providing `ignores` option to :EasyAlign command

```vim
:EasyAlign:{'is':[]}
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

Lines without any matching delimiter are ignored as well (except in
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

One way is to set the global `g:easy_align_ignore_unmatched` variable to be 0.

```vim
let g:easy_align_ignore_unmatched = 0
```

Or in non-interactive mode, you can provide `ignore_unmatched` option to
:EasyAlign command

```vim
:EasyAlign:{'iu':0}
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

Although the default rules should cover the most of the use cases,
you can extend the rules by setting a dictionary named `g:easy_align_delimiters`.

#### Example

```vim
" Examples
let g:easy_align_delimiters = {
\ '>': { 'pattern': '>>\|=>\|>' },
\ '/': { 'pattern': '//\+\|/\*\|\*/', 'ignores': ['String'] },
\ '#': { 'pattern': '#\+', 'ignores': ['String'] },
\ ']': {
\     'pattern':       '[\[\]]',
\     'left_margin':   0,
\     'right_margin':  0,
\     'stick_to_left': 0
\   },
\ ')': {
\     'pattern':       '[()]',
\     'left_margin':   0,
\     'right_margin':  0,
\     'stick_to_left': 0
\   }
\ }
```

Examples and use cases
----------------------

See the [link](https://github.com/junegunn/vim-easy-align/blob/master/EXAMPLES.md)
for more examples.

Author
------

[Junegunn Choi](https://github.com/junegunn)

License
-------

MIT
