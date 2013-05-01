vim-easy-align
==============

Yet another Vim alignment plugin without too much ambition.

This plugin clearly has less features than the other pre-existing ones with the similar goals,
but it is simpler, easier to use, and just good enough for the most of the cases.

Usage
-----

Vim-easy-align defines `:EasyAlign` command in the visual mode.
For convenience, it is advised that you define a mapping for triggering it in your `.vimrc`.

```vim
vnoremap <silent> <Enter> :EasyAlign<cr>
```

With the mapping, you can align selected lines with a few keystrokes.

1. `<Enter>` key to start EasyAlign command
1. Optional field number (default: 1)
    - `1`        Alignment around 1st delimiter
    - `2`        Alignment around 2nd delimiter
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
| `|`       | Table markdown                                             |

### Example command sequences

| With visual map   | Description                                       | Equivalent command   |
| ----------------- | ------------------------------------------------- | -------------------- |
| `<Enter>=`        | Alignment around 1st equals sign (and the likes)  | `:'<,'>EasyAlign=`   |
| `<Enter>2=`       | Alignment around 2nd equals sign (and the likes)  | `:'<,'>EasyAlign2=`  |
| `<Enter>3=`       | Alignment around 3rd equals sign (and the likes)  | `:'<,'>EasyAlign3=`  |
| `<Enter>*=`       | Alignment around all equals signs (and the likes) | `:'<,'>EasyAlign*=`  |
| `<Enter><space>`  | Alignment around 1st space                        | `:'<,'>EasyAlign\ `  |
| `<Enter>2<space>` | Alignment around 2nd space                        | `:'<,'>EasyAlign2\ ` |
| `<Enter>:`        | Alignment around 1st colon                        | `:'<,'>EasyAlign:`   |
| ...               | ...                                               |                      |

### Partial alignment in blockwise-visual mode

In blockwise-visual mode (`CTRL-V`), EasyAlign aligns only the selected portions.
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
\ '/': { 'pattern': '//*' },
\ 'x': {
\     'pattern':       '[xX]',
\     'margin_left':   ' <<<',
\     'margin_right':  '>>> ',
\     'stick_to_left': 0
\   }
\ }
```

Demo
----

[Screencast](https://vimeo.com/63506219)

Author
------

[Junegunn Choi](https://github.com/junegunn)
