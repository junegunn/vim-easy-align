vim-easy-align
==============

A simple, easy-to-use Vim alignment plugin.

Demo
----

![Screencast](https://raw.github.com/junegunn/vim-easy-align/gif/vim-easy-align.gif)

(Too fast? Slower GIF is [here](https://raw.github.com/junegunn/vim-easy-align/gif/vim-easy-align-slow.gif))

Features
--------

- Makes the common case easy
  - Comes with a predefined set of alignment rules
  - Provides a fast and intuitive interface
- Extensible
  - You can define your own rules
  - Supports arbitrary regular expressions
- Optimized for code editing
  - Takes advantage of syntax highlighting feature to avoid unwanted alignments

Installation
------------

Either [download zip file](http://www.vim.org/scripts/script.php?script_id=4520)
and extract in ~/.vim or use [Vundle](https://github.com/gmarik/vundle) (recommended)
or [Pathogen](https://github.com/tpope/vim-pathogen).

### With Vundle

Add the following line to your .vimrc,

```vim
Bundle 'junegunn/vim-easy-align'
```

then execute `:BundleInstall` command.

Usage
-----

_vim-easy-align_ defines `:EasyAlign` command (and the right-align
variant `:EasyAlign!`) in the visual mode.

| Mode                      | Command                                          |
| ------------------------- | ------------------------------------------------ |
| Interactive mode          | `:EasyAlign[!] [OPTIONS]`                        |
| Using predefined rules    | `:EasyAlign[!] [FIELD#] DELIMITER_KEY [OPTIONS]` |
| Using regular expressions | `:EasyAlign[!] [FIELD#] /REGEXP/ [OPTIONS]`      |

### Interactive mode

The command will go into the interactive mode when no argument is given.
For convenience, it is advised that you define a mapping for triggering it in
your `.vimrc`.

```vim
vnoremap <silent> <Enter> :EasyAlign<cr>
```

(Of course you can use any key combination as the trigger. e.g. `<Leader>a`)

With the mapping, you can align selected lines of text with only a few keystrokes.

1. `<Enter>` key to start interactive EasyAlign command
1. Optional Enter keys to select alignment mode (left, right, or center)
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

| Delimiter key | Description/Use cases                                                |
| ------------- | -------------------------------------------------------------------- |
| `<space>`     | General alignment around whitespaces                                 |
| `=`           | Operators containing equals sign (`=`, `==,` `!=`, `+=`, `&&=`, ...) |
| `:`           | Suitable for formatting JSON or YAML                                 |
| `.`           | Multi-line method chaining                                           |
| `,`           | Multi-line method arguments                                          |
| &#124;        | Table markdown                                                       |

You can override these default rules or define your own rules with
`g:easy_align_delimiters`, which will be described in the later section.

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
| `<Enter><Enter>=`   | Right alignment around 1st equals signs                  | `:'<,'>EasyAlign!=`   |
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

Option names are fuzzy-matched, so you can write as follows:

- `:EasyAlign * /[:;]\+/ { 'stl': 1, 'l': 0 }`

You can even omit spaces between the arguments, so concisely (or cryptically):

- `:EasyAlign*/[:;]\+/{'s':1,'l':0}`

Available options will be shown later in the document.

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

Alignment options
-----------------

Option values can be 1) specified as global variables, 2) set on each alignment
rule in `g:easy_align_delimiters`, 3) or given to every `:EasyAlign` command.

Command-line options have the highest precedence, and global variables have the
lowest precedence.

### List of options

| Option             | Type    | Default               | Description                                             |
| ------------------ | ------- | --------------------- | ------------------------------------------------------- |
| `left_margin`      | number  | 0                     | Number of spaces to attach before delimiter             |
| `left_margin`      | string  | `''`                  | String to attach before delimiter                       |
| `right_margin`     | number  | 0                     | Number of spaces to attach after delimiter              |
| `right_margin`     | string  | `''`                  | String to attach after delimiter                        |
| `stick_to_left`    | boolean | 0                     | Whether to position delimiter on the left-side          |
| `ignore_groups`    | list    | ['String', 'Comment'] | Delimiters in these syntax highlight groups are ignored |
| `ignore_unmatched` | boolean | 1                     | Whether to ignore lines without matching delimiter      |
| `indentation`      | string  | `k`                   | Indentation method (*k*eep, *d*eep, *s*hallow, *n*one)  |
| `delimiter_align`  | string  | `r`                   | Determines how to align delimiters of different lengths |
| `mode_sequence`    | string  |                       | Alignment modes for multiple occurrences of delimiters  |

Some of the options can be specified using corresponding global variables.

| Option             | Global variable                 |
| ------------------ | ------------------------------- |
| `ignore_groups`    | `g:easy_align_ignore_groups`    |
| `ignore_unmatched` | `g:easy_align_ignore_unmatched` |
| `delimiter_align`  | `g:easy_align_delimiter_align`  |
| `indentation`      | `g:easy_align_indentation`      |

In interactive mode, you can switch some of the alignment options using special
keys listed below.

| Key      | Option             | Values                                             |
| -------- | ------------------ | -------------------------------------------------- |
| `CTRL-I` | `indentation`      | shallow, deep, none, keep                          |
| `CTRL-L` | `left_margin`      | Input number or string                             |
| `CTRL-R` | `right_margin`     | Input number or string                             |
| `CTRL-D` | `delimiter_align`  | left, center, right                                |
| `CTRL-U` | `ignore_unmatched` | 0, 1                                               |
| `CTRL-G` | `ignore_groups`    | [], ['String'], ['Comment'], ['String', 'Comment'] |
| `CTRL-O` | `mode_sequence`    | Input string of l, r, and c characters             |

### Ignoring delimiters in comments or strings

EasyAlign can be configured to ignore delimiters in certain syntax highlight
groups, such as code comments or strings. By default, delimiters that are
highlighted as code comments or strings are ignored.

```vim
" Default:
"   If a delimiter is in a highlight group whose name matches
"   any of the followings, it will be ignored.
let g:easy_align_ignore_groups = ['Comment', 'String']
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

You can change the default rule by using one of these 4 methods.

1. Press `CTRL-G` in interactive mode to switch groups
2. Define global `g:easy_align_ignore_groups` list
3. Define a custom rule in `g:easy_align_delimiters` with `ignore_groups` option
4. Provide `ignore_groups` option to `:EasyAlign` command.
   e.g. `:EasyAlign:{'ig':[]}`

For example if you set `ignore_groups` option to be an empty list, you get

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
right-align mode).

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

However, this default behavior is also configurable by using one of these 4
methods.

1. Press `CTRL-U` in interactive mode to toggle `ignore_unmatched` option
2. Set the global `g:easy_align_ignore_unmatched` variable to 0
3. Define a custom alignment rule with `ignore_unmatched` option set to 0
4. Provide `ignore_unmatched` option to `:EasyAlign` command. e.g. `:EasyAlign:{'iu':0}`

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

### Aligning delimiters of different lengths

Global `g:easy_align_delimiter_align` option and rule-wise/command-wise
`delimiter_align` option determines how matched delimiters of different lengths
are aligned.

```ruby
apple = 1
banana += apple
cake ||= banana
```

By default, delimiters are right-aligned as follows.

```ruby
apple    = 1
banana  += apple
cake   ||= banana
```

However, with `:EasyAlign={'da':l}`, delimiters are left-aligned.

```ruby
apple  =   1
banana +=  apple
cake   ||= banana
```

And on `:EasyAlign={'da':c}`, center-aligned.

```ruby
apple   =  1
banana +=  apple
cake   ||= banana
```

In interactive mode, you can change the option value with `CTRL-D` key.

### Adjusting indentation

By default :EasyAlign command keeps the original indentation of the lines. But
then again we have `indentation` option. See the following example.

```ruby
# Lines with different indentation
  apple = 1
    banana = 2
      cake = 3
        daisy = 4
     eggplant = 5

# Default: _k_eep the original indentation
#   :EasyAlign=
  apple       = 1
    banana    = 2
      cake    = 3
        daisy = 4
     eggplant = 5

# Use the _s_hallowest indentation among the lines
#   :EasyAlign={'idt':s}
  apple    = 1
  banana   = 2
  cake     = 3
  daisy    = 4
  eggplant = 5

# Use the _d_eepest indentation among the lines
#   :EasyAlign={'idt':d}
        apple    = 1
        banana   = 2
        cake     = 3
        daisy    = 4
        eggplant = 5

# Indentation: _n_one
#   :EasyAlign={'idt':n}
apple    = 1
banana   = 2
cake     = 3
daisy    = 4
eggplant = 5
```

Notice that `idt` is fuzzy-matched to `indentation`.

In interactive mode, you can change the option value with `CTRL-I` key.

### Left/right/center mode switch in interactive mode

In interactive mode, you can choose the alignment mode you want by pressing
enter keys. The non-bang command, `:EasyAlign` starts in left-alignment mode
and changes to right and center mode as you press enter keys, while the bang
version first starts in right-alignment mode.

- `:EasyAlign`
  - Left, Right, Center
- `:EasyAlign!`
  - Right, Left, Center

If you do not prefer this default mode transition, you can define your own
settings as follows.

```vim
let g:easy_align_interactive_modes = ['l', 'r']
let g:easy_align_bang_interactive_modes = ['c', 'r']
```

### Alignments over multiple occurrences of delimiters

As stated above, "field number" is used to target specific occurrences of
the delimiter when it appears multiple times in each line.

To recap:

```vim
" Left-alignment around the FIRST occurrences of delimiters
:EasyAlign =

" Left-alignment around the SECOND occurrences of delimiters
:EasyAlign 2=

" Left-alignment around the LAST occurrences of delimiters
:EasyAlign -=

" Left-alignment around ALL occurrences of delimiters
:EasyAlign *=

" Left-right ALTERNATING alignment around all occurrences of delimiters
:EasyAlign **=

" Right-left ALTERNATING alignment around all occurrences of delimiters
:EasyAlign! **=
```

In addition to these, you can fine-tune alignments over multiple occurrences of
the delimiters with 'mode_sequence' option. (The option can also be given
in interactive mode with the special key `CTRL-O`.)

```vim
" Left alignment over the first two occurrences of delimiters
:EasyAlign = { 'mode_sequence': 'll' }

" Right, left, center alignment over the 1st to 3rd occurrences of delimiters
:EasyAlign = { 'm': 'rlc' }

" Right, left, center alignment over the 2nd to 4th occurrences of delimiters
:EasyAlign 2={ 'm': 'rlc' }

" (*) Repeating alignments (default: l, r, or c)
"   Right, left, center, center, center, center, ...
:EasyAlign *={ 'm': 'rlc' }

" (**) Alternating alignments (default: lr or rl)
"   Right, left, center, right, left, center, ...
:EasyAlign **={ 'm': 'rlc' }
```

### Extending alignment rules

Although the default rules should cover the most of the use cases,
you can extend the rules by setting a dictionary named `g:easy_align_delimiters`.

#### Example

```vim
let g:easy_align_delimiters = {
\ '>': { 'pattern': '>>\|=>\|>' },
\ '/': { 'pattern': '//\+\|/\*\|\*/', 'ignore_groups': ['String'] },
\ '#': { 'pattern': '#\+', 'ignore_groups': ['String'], 'delimiter_align': 'l' },
\ ']': {
\     'pattern':       '[[\]]',
\     'left_margin':   0,
\     'right_margin':  0,
\     'stick_to_left': 0
\   },
\ ')': {
\     'pattern':       '[()]',
\     'left_margin':   0,
\     'right_margin':  0,
\     'stick_to_left': 0
\   },
\ 'd': {
\     'pattern': ' \(\S\+\s*[;=]\)\@=',
\     'left_margin': 0,
\     'right_margin': 0
\   }
\ }
```

Advanced examples and use cases
-------------------------------

See [EXAMPLES.md](https://github.com/junegunn/vim-easy-align/blob/master/EXAMPLES.md)
for more examples.

Author
------

[Junegunn Choi](https://github.com/junegunn)

License
-------

MIT
