vim-easy-align ![travis-ci](https://travis-ci.org/junegunn/vim-easy-align.svg?branch=master)
==============

A simple, easy-to-use Vim alignment plugin.

Demo
----

<img src="https://raw.githubusercontent.com/junegunn/i/master/vim-easy-align.gif" height="494" alt="Screencast">

(Too fast? Slower GIF is [here](https://raw.githubusercontent.com/junegunn/i/master/vim-easy-align-slow.gif))

Features
--------

- Easy to use
  - Comes with a predefined set of alignment rules
  - Provides a fast and intuitive interface
- Extensible
  - You can define your own rules
  - Supports arbitrary regular expressions
- Optimized for code editing
  - Takes advantage of syntax highlighting feature to avoid unwanted alignments

Installation
------------

User your favorite plugin manager.

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'junegunn/vim-easy-align'
```

TL;DR - One-minute guide
------------------------

Add the following mappings to your .vimrc.

```vim
" Start interactive EasyAlign in visual mode (e.g. vip<Enter>)
vmap <Enter> <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
```

And with the following lines of text,

```
apple   =red
grass+=green
sky-=   blue
```

try these commands:

- `vip<Enter>=`
    - `v`isual-select `i`nner `p`aragraph
    - Start EasyAlign command (`<Enter>`)
    - Align around `=`
- `gaip=`
    - Start EasyAlign command (`ga`) for `i`nner `p`aragraph
    - Align around `=`

Notice that the commands are repeatable with `.` key if you have installed
[repeat.vim](https://github.com/tpope/vim-repeat). Install
[visualrepeat](https://github.com/vim-scripts/visualrepeat) as well if you want
to repeat in visual mode.

Usage
-----

### Concept of _alignment rule_

Though easy-align can align lines of text around any delimiter, it provides
shortcuts for the most common use cases with the concept of "_alignment rule_".

An *alignment rule* is a predefined set of options for common alignment tasks,
which is identified by a single character, *DELIMITER KEY*, such as `<Space>`,
`=`, `:`, `.`, `|`, `&`, `#`, and `,`.

Think of it as a shortcut. Instead of writing regular expression and setting
several options, you can just type in a single character.

### Execution models

There are two ways to use easy-align.

#### 1. Using `<Plug>` mappings

The recommended method is to use `<Plug>` mappings as described earlier.

| Mapping                 | Mode   | Description                                          |
| ----------------------- | ------ | ---------------------------------------------------- |
| `<Plug>(EasyAlign)`     | normal | Start interactive mode for a motion/text object      |
| `<Plug>(EasyAlign)`     | visual | Start interactive mode for the selection             |
| `<Plug>(LiveEasyAlign)` | normal | Start live-interactive mode for a motion/text object |
| `<Plug>(LiveEasyAlign)` | visual | Start live-interactive mode for the selection        |

#### 2. Using `:EasyAlign` command

If you prefer command-line or do not want to start interactive mode, you can use
`:EasyAlign` command instead.

| Mode                                       | Command                                          |
| ------------------------------------------ | ------------------------------------------------ |
| Interactive mode                           | `:EasyAlign[!] [OPTIONS]`                        |
| Live interactive mode                      | `:LiveEasyAlign[!] [...]`                        |
| Non-interactive mode (predefined rules)    | `:EasyAlign[!] [N-th] DELIMITER_KEY [OPTIONS]`   |
| Non-interactive mode (regular expressions) | `:EasyAlign[!] [N-th] /REGEXP/ [OPTIONS]`        |

### Interactive mode

The following sections will assume that you have `<Plug>(EasyAlign)` mappings in
your .vimrc as below:

```vim
" Start interactive EasyAlign in visual mode (e.g. vip<Enter>)
vmap <Enter> <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
```

With these mappings, you can align text with only a few keystrokes.

1. `<Enter>` key in visual mode, or `ga` followed by a motion or a text
   object to start interactive mode
1. Optional: Enter keys to select alignment mode (left, right, or center)
1. Optional: N-th delimiter (default: 1)
    - `1`         Around the 1st occurrences of delimiters
    - `2`         Around the 2nd occurrences of delimiters
    - ...
    - `*`         Around all occurrences of delimiters
    - `**`        Left-right alternating alignment around all delimiters
    - `-`         Around the last occurrences of delimiters (`-1`)
    - `-2`        Around the second to last occurrences of delimiters
    - ...
1. Delimiter key (a single keystroke; `<Space>`, `=`, `:`, `.`, `|`, `&`, `#`, `,`)

#### Predefined alignment rules

| Delimiter key | Description/Use cases                                                |
| ------------- | -------------------------------------------------------------------- |
| `<Space>`     | General alignment around whitespaces                                 |
| `=`           | Operators containing equals sign (`=`, `==,` `!=`, `+=`, `&&=`, ...) |
| `:`           | Suitable for formatting JSON or YAML                                 |
| `.`           | Multi-line method chaining                                           |
| `,`           | Multi-line method arguments                                          |
| `&`           | LaTeX tables (matches `&` and `\\`)                                  |
| `#`           | Ruby/Python comments                                                 |
| `<Bar>`       | Table markdown                                                       |

You can override these default rules or define your own rules with
`g:easy_align_delimiters`, which will be described in
[the later section](https://github.com/junegunn/vim-easy-align#extending-alignment-rules).

#### Examples

| With visual map     | Description                        | Equivalent command    |
| ------------------- | ---------------------------------- | --------------------- |
| `<Enter><Space>`    | Around 1st whitespaces             | `:'<,'>EasyAlign\ `   |
| `<Enter>2<Space>`   | Around 2nd whitespaces             | `:'<,'>EasyAlign2\ `  |
| `<Enter>-<Space>`   | Around the last whitespaces        | `:'<,'>EasyAlign-\ `  |
| `<Enter>-2<Space>`  | Around the 2nd to last whitespaces | `:'<,'>EasyAlign-2\ ` |
| `<Enter>:`          | Around 1st colon (`key:  value`)   | `:'<,'>EasyAlign:`    |
| `<Enter><Right>:`   | Around 1st colon (`key : value`)   | `:'<,'>EasyAlign:<l1` |
| `<Enter>=`          | Around 1st operators with =        | `:'<,'>EasyAlign=`    |
| `<Enter>3=`         | Around 3rd operators with =        | `:'<,'>EasyAlign3=`   |
| `<Enter>*=`         | Around all operators with =        | `:'<,'>EasyAlign*=`   |
| `<Enter>**=`        | Left-right alternating around =    | `:'<,'>EasyAlign**=`  |
| `<Enter><Enter>=`   | Right alignment around 1st =       | `:'<,'>EasyAlign!=`   |
| `<Enter><Enter>**=` | Right-left alternating around =    | `:'<,'>EasyAlign!**=` |

#### Using regular expressions

Instead of finishing the command with a predefined delimiter key, you can type
in a regular expression after `<CTRL-/>` or `<CTRL-X>` key.
For example, if you want to align text around all occurrences of numbers:

- `<Enter>`
- `*`
- `<CTRL-X>`
  - `[0-9]\+`

#### Alignment options in interactive mode

While in interactive mode, you can set alignment options using special shortcut
keys listed below. The meaning of each option will be described in
[the following sections](https://github.com/junegunn/vim-easy-align#alignment-options).

| Key       | Option             | Values                                             |
| --------- | ------------------ | -------------------------------------------------- |
| `CTRL-F`  | `filter`           | Input string (`[gv]/.*/?`)                         |
| `CTRL-I`  | `indentation`      | shallow, deep, none, keep                          |
| `CTRL-L`  | `left_margin`      | Input number or string                             |
| `CTRL-R`  | `right_margin`     | Input number or string                             |
| `CTRL-D`  | `delimiter_align`  | left, center, right                                |
| `CTRL-U`  | `ignore_unmatched` | 0, 1                                               |
| `CTRL-G`  | `ignore_groups`    | [], ['String'], ['Comment'], ['String', 'Comment'] |
| `CTRL-A`  | `align`            | Input string (`/[lrc]+\*{0,2}/`)                   |
| `<Left>`  | `stick_to_left`    | `{ 'stick_to_left': 1, 'left_margin': 0 }`         |
| `<Right>` | `stick_to_left`    | `{ 'stick_to_left': 0, 'left_margin': 1 }`         |
| `<Down>`  | `*_margin`         | `{ 'left_margin': 0, 'right_margin': 0 }`          |

### Live interactive mode

If you're performing a complex alignment where multiple options should be
carefully adjusted, try "live interactive mode" where you can preview the result
of the alignment on-the-fly as you type in.

Live interactive mode can be started with either `<Plug>(LiveEasyAlign)` map
or `:LiveEasyAlign` command. Or you can switch to live interactive mode while
in ordinary interactive mode by pressing `<CTRL-P>`. (P for Preview)

In live interactive mode, you have to type in the same delimiter (or `CTRL-X` on
regular expression) again to finalize the alignment. This allows you to preview
the result of the alignment and freely change the delimiter using backspace key
without leaving the interactive mode.

### Non-interactive mode

Instead of starting interactive mode, you can use declarative, non-interactive
`:EasyAlign` command.

```vim
" Using predefined alignment rules
"   :EasyAlign[!] [N-th] DELIMITER_KEY [OPTIONS]
:EasyAlign :
:EasyAlign =
:EasyAlign *=
:EasyAlign 3\

" Using arbitrary regular expressions
"   :EasyAlign[!] [N-th] /REGEXP/ [OPTIONS]
:EasyAlign /[:;]\+/
:EasyAlign 2/[:;]\+/
:EasyAlign */[:;]\+/
:EasyAlign **/[:;]\+/
```

A command can end with alignment options, [each of which will be discussed in
detail later](https://github.com/junegunn/vim-easy-align#alignment-options),
in Vim dictionary format.

- `:EasyAlign * /[:;]\+/ { 'stick_to_left': 1, 'left_margin': 0 }`

`stick_to_left` of 1 means that the matched delimiter should be positioned right
next to the preceding token, and `left_margin` of 0 removes the margin on the
left. So we get:

    apple;: banana::   cake
    data;;  exchange:; format

Option names are fuzzy-matched, so you can write as follows:

- `:EasyAlign * /[:;]\+/ { 'stl': 1, 'l': 0 }`

You can even omit spaces between the arguments, so concisely (or cryptically):

- `:EasyAlign*/[:;]\+/{'s':1,'l':0}`

Nice. But let's make it even shorter. Option values can be written in shorthand
notation.

- `:EasyAlign*/[:;]\+/<l0`

The following table summarizes the shorthand notation.

| Option             | Expression     |
| ------------------ | -------------- |
| `filter`           | `[gv]/.*/`     |
| `left_margin`      | `l[0-9]+`      |
| `right_margin`     | `r[0-9]+`      |
| `stick_to_left`    | `<` or `>`     |
| `ignore_unmatched` | `iu[01]`       |
| `ignore_groups`    | `ig\[.*\]`     |
| `align`            | `a[lrc*]*`     |
| `delimiter_align`  | `d[lrc]`       |
| `indentation`      | `i[ksdn]`      |

For your information, the same operation can be done in interactive mode as
follows:

- `<Enter>`
- `*`
- `<Left>`
- `<CTRL-X>`
  - `[:;]\+`

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
since the same can be easily done using the negative N-th parameter: `<Enter>-=`


Alignment options
-----------------

### List of options

| Option             | Type    | Default               | Description                                             |
| ------------------ | ------- | --------------------- | ------------------------------------------------------- |
| `filter`           | string  |                       | Line filtering expression: `g/../` or `v/../`           |
| `left_margin`      | number  | 1                     | Number of spaces to attach before delimiter             |
| `left_margin`      | string  | `' '`                 | String to attach before delimiter                       |
| `right_margin`     | number  | 1                     | Number of spaces to attach after delimiter              |
| `right_margin`     | string  | `' '`                 | String to attach after delimiter                        |
| `stick_to_left`    | boolean | 0                     | Whether to position delimiter on the left-side          |
| `ignore_groups`    | list    | ['String', 'Comment'] | Delimiters in these syntax highlight groups are ignored |
| `ignore_unmatched` | boolean | 1                     | Whether to ignore lines without matching delimiter      |
| `indentation`      | string  | `k`                   | Indentation method (*k*eep, *d*eep, *s*hallow, *n*one)  |
| `delimiter_align`  | string  | `r`                   | Determines how to align delimiters of different lengths |
| `align`            | string  | `l`                   | Alignment modes for multiple occurrences of delimiters  |

There are 4 ways to set alignment options (from lowest precedence to highest):

1. Some option values can be set with corresponding global variables
2. Option values can be specified in the definition of each alignment rule
3. Option values can be given as arguments to `:EasyAlign` command
4. Option values can be set in interactive mode using special shortcut keys

| Option name        | Shortcut key        | Abbreviated    | Global variable                 |
| ------------------ | ------------------- | -------------- | ------------------------------- |
| `filter`           | `CTRL-F`            | `[gv]/.*/`     |                                 |
| `left_margin`      | `CTRL-L`            | `l[0-9]+`      |                                 |
| `right_margin`     | `CTRL-R`            | `r[0-9]+`      |                                 |
| `stick_to_left`    | `<Left>`, `<Right>` | `<` or `>`     |                                 |
| `ignore_groups`    | `CTRL-G`            | `ig\[.*\]`     | `g:easy_align_ignore_groups`    |
| `ignore_unmatched` | `CTRL-U`            | `iu[01]`       | `g:easy_align_ignore_unmatched` |
| `indentation`      | `CTRL-I`            | `i[ksdn]`      | `g:easy_align_indentation`      |
| `delimiter_align`  | `CTRL-D`            | `d[lrc]`       | `g:easy_align_delimiter_align`  |
| `align`            | `CTRL-A`            | `a[lrc*]*`     |                                 |

### Filtering lines

With `filter` option, you can align lines that only match or do not match a
given pattern. There are several ways to set the pattern.

1. Press `CTRL-F` in interactive mode and type in `g/pat/` or `v/pat/`
2. In command-line, it can be written in dictionary format: `{'filter': 'g/pat/'}`
3. Or in shorthand notation: `g/pat/` or `v/pat/`

(You don't need to escape '/'s in the regular expression)

#### Examples

```vim
" Start interactive mode with filter option set to g/hello/
EasyAlign g/hello/

" Start live interactive mode with filter option set to v/goodbye/
LiveEasyAlign v/goodbye/

" Align the lines with 'hi' around the first colons
EasyAlign:g/hi/
```

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
   e.g. `:EasyAlign:ig[]`

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

If a pattern in `ignore_groups` is prepended by a `!`, it will have the opposite
meaning. For instance, if `ignore_groups` is given as `['!Comment']`, delimiters
that are *not* highlighted as Comment will be ignored during the alignment.

### Ignoring unmatched lines

`ignore_unmatched` option determines how EasyAlign command processes lines that
do not have N-th delimiter.

1. In left-alignment mode, they are ignored
2. In right or center-alignment mode, they are *not* ignored, and the last
   tokens from those lines are aligned as well as if there is an invisible
   trailing delimiter at the end of each line
3. If `ignore_unmatched` is 1, they are ignored regardless of the alignment mode
4. If `ignore_unmatched` is 0, they are *not* ignored regardless of the mode

Let's take an example.
When we align the following code block around the (1st) colons,

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

However, we can override this default behavior by setting `ignore_unmatched`
option to zero using one of the following methods.

1. Press `CTRL-U` in interactive mode to toggle `ignore_unmatched` option
2. Set the global `g:easy_align_ignore_unmatched` variable to 0
3. Define a custom alignment rule with `ignore_unmatched` option set to 0
4. Provide `ignore_unmatched` option to `:EasyAlign` command. e.g. `:EasyAlign:iu0`

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

However, with `:EasyAlign=dl`, delimiters are left-aligned.

```ruby
apple  =   1
banana +=  apple
cake   ||= banana
```

And on `:EasyAlign=dc`, center-aligned.

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
#   :EasyAlign=is
  apple    = 1
  banana   = 2
  cake     = 3
  daisy    = 4
  eggplant = 5

# Use the _d_eepest indentation among the lines
#   :EasyAlign=id
        apple    = 1
        banana   = 2
        cake     = 3
        daisy    = 4
        eggplant = 5

# Indentation: _n_one
#   :EasyAlign=in
apple    = 1
banana   = 2
cake     = 3
daisy    = 4
eggplant = 5
```

In interactive mode, you can change the option value with `CTRL-I` key.

### Alignments over multiple occurrences of delimiters

As stated above, "N-th" parameter is used to target specific occurrences of
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

In addition to these, you can fine-tune alignments over multiple occurrences
of the delimiters with 'align' option. (The option can also be set in
interactive mode with the special key `CTRL-A`)

```vim
" Left alignment over the first two occurrences of delimiters
:EasyAlign = { 'align': 'll' }

" Right, left, center alignment over the 1st to 3rd occurrences of delimiters
:EasyAlign = { 'a': 'rlc' }

" Using shorthand notation
:EasyAlign = arlc

" Right, left, center alignment over the 2nd to 4th occurrences of delimiters
:EasyAlign 2=arlc

" (*) Repeating alignments (default: l, r, or c)
"   Right, left, center, center, center, center, ...
:EasyAlign *=arlc

" (**) Alternating alignments (default: lr or rl)
"   Right, left, center, right, left, center, ...
:EasyAlign **=arlc

" Right, left, center, center, center, ... repeating alignment
" over the 3rd to the last occurrences of delimiters
:EasyAlign 3=arlc*

" Right, left, center, right, left, center, ... alternating alignment
" over the 3rd to the last occurrences of delimiters
:EasyAlign 3=arlc**
```

### Extending alignment rules

Although the default rules should cover the most of the use cases,
you can extend the rules by setting a dictionary named `g:easy_align_delimiters`.

You may refer to the definitions of the default alignment rules
[here](https://github.com/junegunn/vim-easy-align/blob/2.9.6/autoload/easy_align.vim#L32-L46).

#### Examples

```vim
let g:easy_align_delimiters = {
\ '>': { 'pattern': '>>\|=>\|>' },
\ '/': {
\     'pattern':         '//\+\|/\*\|\*/',
\     'delimiter_align': 'l',
\     'ignore_groups':   ['!Comment'] },
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
\     'pattern':      ' \(\S\+\s*[;=]\)\@=',
\     'left_margin':  0,
\     'right_margin': 0
\   }
\ }
```

Other options
-------------

### Disabling &foldmethod during alignment

[It is reported](https://github.com/junegunn/vim-easy-align/issues/14) that
`&foldmethod` value of `expr` or `syntax` can significantly slow down the
alignment when editing a large, complex file with many folds. To alleviate this
issue, EasyAlign provides an option to temporarily set `&foldmethod` to `manual`
during the alignment task. In order to enable this feature, set
`g:easy_align_bypass_fold` switch to 1.

```vim
let g:easy_align_bypass_fold = 1
```

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

Advanced examples and use cases
-------------------------------

See [EXAMPLES.md](https://github.com/junegunn/vim-easy-align/blob/master/EXAMPLES.md)
for more examples.

Related work
------------

- [DrChip's Alignment Tool for Vim](http://www.drchip.org/astronaut/vim/align.html)
- [Tabular](https://github.com/godlygeek/tabular)

Author
------

[Junegunn Choi](https://github.com/junegunn)

License
-------

MIT
