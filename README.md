vim-lesser-align
================

Yet another Vim alignment plugin without too much ambition.
This plugin clearly has less features than the other pre-existing ones with the similar goals,
but is simpler, easier to use, and good enough for most of the cases.

Usage
-----

Vim-lesser-align defines `LesserAlign` command in the visual mode.
For convenience, it is advised that you define a mapping for triggering it in your `.vimrc`.

```vim
vnoremap <silent> <Enter> :LesserAlign<cr>
```

Then, a key sequence becomes a combination of 3 parts.

1. `<Enter>`
    - Shortcut for `:LesserAssign<Enter>`
1. Integer (optional, default: 1)
    - `1`: Alignment around 1st delimiter
    - `2`: Alignment around 2nd delimiter
    - `...`
    - `*`: Alignment around all delimiters (tabularize)
1. Delimiter
    - `=`
      - Operators containing equals sign (=, ==, !=, +=, &&=, ...)
    - `<space>`
      - Space
    - `:`
    - `,`
    - `|`

| Keystroke           | Description                                           |
| ------------------- | ----------------------------------------------------- |
| `<Enter>=`          | *A*lignment around 1st equals sign (and the likes)    |
| `<Enter>2=`         | *A*lignment around *2*nd equals sign (and the likes)  |
| `<Enter>3=`         | *A*lignment around *3*rd equals sign (and the likes)  |
| `<Enter>*=`         | *A*lignment around *all* equals signs (and the likes) |
| `<Enter><space>`    | *A*lignment around *1*st whitespace                   |
| `<Enter>2<space>`   | *A*lignment around *2*nd whitespace                   |
| `<Enter>:`          | *A*lignment around *1*st colon                        |
| ...                 | ...                                                   |

Author
------

[Junegunn Choi](https://github.com/junegunn)
