vim-lesser-align
================

Yet another Vim alignment plugin without too much ambition.

This plugin clearly has less features than the other pre-existing ones with the similar goals,
but it is simpler, easier to use, and good enough for the most of the cases.

Usage
-----

Vim-lesser-align defines `LesserAlign` command in the visual mode.

For convenience, it is advised that you define a mapping for triggering it in your `.vimrc`.

```vim
vnoremap <silent> <Enter> :LesserAlign<cr>
```

Then a key sequence becomes a combination of 3 parts.

1. `<Enter>`
    - Shortcut for `:LesserAssign<cr>`
1. Integer (*optional*, default: 1)
    - `1`: Alignment around 1st delimiter
    - `2`: Alignment around 2nd delimiter
    - `...`
    - `*`: Alignment around all delimiters (tabularize)
1. Delimiter
    - `=`: Operators containing equals sign (=, ==, !=, +=, &&=, ...)
    - `<space>`
    - `:`
    - `,`
    - `|`

Examples
--------

| With visual map   | Description                                        | Equivalent command      |
| ----------------- | -------------------------------------------------- | ----------------------- |
| `<Enter>=`        | Alignment around 1st equals sign (and the likes)   | `:'<,'>LesserAlign =`   |
| `<Enter>2=`       | Alignment around 2nd equals sign (and the likes)   | `:'<,'>LesserAlign 2=`  |
| `<Enter>3=`       | Alignment around 3rd equals sign (and the likes)   | `:'<,'>LesserAlign 3=`  |
| `<Enter>*=`       | Alignment around all equals signs (and the likes)  | `:'<,'>LesserAlign *=`  |
| `<Enter><space>`  | Alignment around 1st whitespace                    | `:'<,'>LesserAlign \ `  |
| `<Enter>2<space>` | Alignment around 2nd whitespace                    | `:'<,'>LesserAlign 2\ ` |
| `<Enter>:`        | Alignment around 1st colon                         | `:'<,'>LesserAlign :`   |
| ...               | ...                                                |                         |

Defining custom alignment rules
-------------------------------

Define (or override) alignment rules.

```vim
let g:lesser_align_delimiters = {
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
