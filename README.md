vim-easy-align
==============

A simple, easy-to-use Vim alignment plugin without too much ambition.

Demo
----

[Screencast](https://vimeo.com/63506219)

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
    - `1`        Alignment around 1st delimiters
    - `2`        Alignment around 2nd delimiters
    - ...
    - `*`        Alignment around all delimiters (recursive)
1. Delimiter (`<space>`, `=`, `:`, `.`, `|`, `,`)

Alignment rules for the following delimiters have been crafted to meet the most needs.

| Delimiter | Description/Use cases                                      |
| --------- | ---------------------------------------------------------- |
| `<space>` | General alignment around spaces                            |
| `=`       | Operators containing equals sign (=, ==, !=, +=, &&=, ...) |
| `:`       | Suitable for formatting JSON or YAML                       |
| `.`       | Multi-line method chaining                                 |
| `,`       | Multi-line method arguments                                |
| &#124;    | Table markdown                                             |

### Example command sequences

| With visual map   | Description                                       | Equivalent command      |
| ----------------- | ------------------------------------------------- | ----------------------- |
| `<Enter>=`        | Alignment around 1st equals signs (and the likes) | `:'<,'>EasyAlign=`      |
| `<Enter>2=`       | Alignment around 2nd equals signs (and the likes) | `:'<,'>EasyAlign2=`     |
| `<Enter>3=`       | Alignment around 3rd equals signs (and the likes) | `:'<,'>EasyAlign3=`     |
| `<Enter>*=`       | Alignment around all equals signs (and the likes) | `:'<,'>EasyAlign*=`     |
| `<Enter><Enter>=` | Right-justified alignment around 1st equals signs | `:'<,'>EasyAlignRight=` |
| `<Enter><space>`  | Alignment around 1st space                        | `:'<,'>EasyAlign\ `     |
| `<Enter>2<space>` | Alignment around 2nd space                        | `:'<,'>EasyAlign2\ `    |
| `<Enter>:`        | Alignment around 1st colon                        | `:'<,'>EasyAlign:`      |
| ...               | ...                                               |                         |

### Partial alignment in blockwise-visual mode

In blockwise-visual mode (`CTRL-V`), EasyAlign command aligns only the selected
parts, instead of the whole lines in the range.

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

Defining custom alignment rules
-------------------------------

```vim
let g:easy_align_delimiters = {
\ '>': { 'pattern': '>>\|=>\|>' },
\ '/': { 'pattern': '//*' },
\ 'x': {
\     'pattern':       '[xX]',
\     'margin_left':   ' <<<',
\     'margin_right':  '>>> ',
\     'stick_to_left': 0
\   }
\ }
```

Handling unmatched lines
------------------------

EasyAlign by default ignores lines without the matching delimiters (except in right-justification mode).
This is to ignore interleaved comments commonly found in code.

For example, when aligning the following code block,

```
{
  # Quantity of apples
  apple: 1,
  # Quantity of bananas
  bananas: 2,
  # Quantity of grapefruits
  grapefruits: 3
}
```

we don't want to the comment lines to affect the alignment,
so this is usually what we want.

```
{
  # Quantity of apples
  apple:       1,
  # Quantity of bananas
  bananas:     2,
  # Quantity of grapefruits
  grapefruits: 3
}
```

However, this default behavior is configurable.

```vim
let g:easy_align_ignore_unmatched = 0
```

Then we get,

```
{
  # Quantity of apples
  apple:                     1,
  # Quantity of bananas
  bananas:                   2,
  # Quantity of grapefruits
  grapefruits:               3
}
```

Author
------

[Junegunn Choi](https://github.com/junegunn)
