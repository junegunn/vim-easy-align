vim-easy-align
==============

A simple, easy-to-use Vim alignment plugin.

Demo
----

![Screencast](https://raw.github.com/junegunn/i/master/vim-easy-align.gif)

(Too fast? Slower GIF is [here](https://raw.github.com/junegunn/i/master/vim-easy-align.gif))

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

### _"I already have a similar one. Should I switch?"_

Maybe or maybe not. See [related work](https://github.com/junegunn/vim-easy-align#related-work) section.

Installation
------------

Either [download zip file](http://www.vim.org/scripts/script.php?script_id=4520)
and extract in ~/.vim or
[use](https://github.com/tpope/vim-pathogen)
[your](https://github.com/gmarik/vundle)
[favorite](https://github.com/junegunn/vim-plug)
[plugin](https://github.com/Shougo/neobundle.vim)
[manager](https://github.com/MarcWeber/vim-addon-manager).

- [Pathogen](https://github.com/tpope/vim-pathogen)
  - `git clone https://github.com/junegunn/vim-easy-align.git ~/.vim/bundle/vim-easy-align`
- [Vundle](https://github.com/gmarik/vundle)
  1. Add `Bundle 'junegunn/vim-easy-align'` to .vimrc
  2. Run `:BundleInstall`
- [NeoBundle](https://github.com/Shougo/neobundle.vim)
  1. Add `NeoBundle 'junegunn/vim-easy-align'` to .vimrc
  2. Run `:NeoBundleInstall`
- [vim-plug](https://github.com/junegunn/vim-plug)
  1. Add `Plug 'junegunn/vim-easy-align'` to .vimrc
  2. Run `:PlugInstall`

Usage
-----

_vim-easy-align_ defines `:EasyAlign` command (and the right-align
variant `:EasyAlign!`) for visual mode.

| Mode                      | Command                                          |
| ------------------------- | ------------------------------------------------ |
| Interactive mode          | `:EasyAlign[!] [OPTIONS]`                        |
| Using predefined rules    | `:EasyAlign[!] [N-th] DELIMITER_KEY [OPTIONS]`   |
| Using regular expressions | `:EasyAlign[!] [N-th] /REGEXP/ [OPTIONS]`        |
| Live interactive mode     | `:LiveEasyAlign[!] [...]`                        |

### Concept of _alignment rule_

An *alignment rule* is a predefined set of options for common alignment tasks,
which is identified by a single character, *DELIMITER KEY*, such as `<space>`,
`=`, `:`, `.`, `|`, `&`, and `,`.

Think of it as a shortcut. Instead of writing regular expression and setting
several options, you can just type in a single character.

### Interactive mode

The command will go into the interactive mode when no argument is given.
For convenience, it is advised that you define a mapping for triggering it in
your `.vimrc`.

```vim
vnoremap <silent> <Enter> :EasyAlign<Enter>
```

(Of course you can use any key combination as the trigger. e.g. `<Leader>a`)

With the mapping, you can align selected lines of text with only a few keystrokes.

1. `<Enter>` key to start interactive EasyAlign command
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
1. Delimiter key (a single keystroke; `<space>`, `=`, `:`, `.`, `|`, `&`, `,`)

Alignment rules for the following delimiters have been defined to meet the most needs.

| Delimiter key | Description/Use cases                                                |
| ------------- | -------------------------------------------------------------------- |
| `<space>`     | General alignment around whitespaces                                 |
| `=`           | Operators containing equals sign (`=`, `==,` `!=`, `+=`, `&&=`, ...) |
| `:`           | Suitable for formatting JSON or YAML                                 |
| `.`           | Multi-line method chaining                                           |
| `,`           | Multi-line method arguments                                          |
| `&`           | LaTeX tables (matches `&` and `\\`)                                  |
| &#124;        | Table markdown                                                       |

You can override these default rules or define your own rules with
`g:easy_align_delimiters`, which will be described in
[the later section](https://github.com/junegunn/vim-easy-align#extending-alignment-rules).

#### Example command sequences

| With visual map     | Description                                             | Equivalent command     |
| ------------------- | ------------------------------------------------------- | ---------------------- |
| `<Enter><space>`    | Alignment around 1st whitespaces                        | `:'<,'>EasyAlign\ `    |
| `<Enter>2<space>`   | Alignment around 2nd whitespaces                        | `:'<,'>EasyAlign2\ `   |
| `<Enter>-<space>`   | Alignment around the last whitespaces                   | `:'<,'>EasyAlign-\ `   |
| `<Enter>-2<space>`  | Alignment around the 2nd to last whitespaces            | `:'<,'>EasyAlign-2\ `  |
| `<Enter>:`          | Alignment around 1st colon (`key:  value`)              | `:'<,'>EasyAlign:`     |
| `<Enter><Right>:`   | Alignment around 1st colon (`key : value`)              | `:'<,'>EasyAlign:s0l1` |
| `<Enter>=`          | Alignment around 1st operators with =                   | `:'<,'>EasyAlign=`     |
| `<Enter>2=`         | Alignment around 2nd operators with =                   | `:'<,'>EasyAlign2=`    |
| `<Enter>3=`         | Alignment around 3rd operators with =                   | `:'<,'>EasyAlign3=`    |
| `<Enter>*=`         | Alignment around all operators with =                   | `:'<,'>EasyAlign*=`    |
| `<Enter>**=`        | Left-right alternating alignment around all = operators | `:'<,'>EasyAlign**=`   |
| `<Enter><Enter>=`   | Right alignment around 1st equals signs                 | `:'<,'>EasyAlign!=`    |
| `<Enter><Enter>**=` | Right-left alternating alignment around all = operators | `:'<,'>EasyAlign!**=`  |

#### Using regular expressions

Instead of finishing the command with a predefined delimiter key, you can type
in a regular expression after `<CTRL-/>` or `<CTRL-X>` key.
For example, if you want to align text around all occurrences of numbers:

- `<Enter>`
- `*`
- `<CTRL-/>` (or `<CTRL-X>` on GVim)
  - `[0-9]\+`

#### Alignment options in interactive mode

While in interactive mode, you can set alignment options using special shortcut
keys listed below. The meaning of each option will be described in
[the following sections](https://github.com/junegunn/vim-easy-align#alignment-options).

| Key       | Option             | Values                                             |
| --------  | ------------------ | -------------------------------------------------- |
| `CTRL-F`  | `filter`           | Input string (`[gv]/.*/?`)                         |
| `CTRL-I`  | `indentation`      | shallow, deep, none, keep                          |
| `CTRL-L`  | `left_margin`      | Input number or string                             |
| `CTRL-R`  | `right_margin`     | Input number or string                             |
| `CTRL-D`  | `delimiter_align`  | left, center, right                                |
| `CTRL-U`  | `ignore_unmatched` | 0, 1                                               |
| `CTRL-G`  | `ignore_groups`    | [], ['String'], ['Comment'], ['String', 'Comment'] |
| `CTRL-O`  | `mode_sequence`    | Input string (`/[lrc]+\*{0,2}/`)                   |
| `<Left>`  | `stick_to_left`    | `{ 'stick_to_left': 1, 'left_margin': 0 }`         |
| `<Right>` | `stick_to_left`    | `{ 'stick_to_left': 0, 'left_margin': 1 }`         |
| `<Down>`  | `*_margin`         | `{ 'left_margin': 0, 'right_margin': 0 }`          |

After a successful alignment, you can repeat the same operation using the
repeatable, non-interactive command recorded in `g:easy_align_last_command`.

```vim
:<C-R>=g:easy_align_last_command<Enter><Enter>
```

### Live interactive mode

If you're performing a complex alignment where multiple options should be
carefully adjusted, try "live interactive mode" where you can preview the result
of the alignment on-the-fly as you type in.

Live interactive mode can be started with `:LiveEasyAlign` command which takes
the same parameters as `:EasyAlign`. I suggest you define a mapping such as
follows in addition to the one for `:EasyAlign` command.

```vim
vnoremap <silent> <Leader><Enter> :LiveEasyAlign<Enter>
```

In live interactive mode, you have to type in the same delimiter (or `CTRL-X` on
regular expression) again to finalize the alignment. This allows you to preview
the result of the alignment and freely change the delimiter using backspace key
without leaving the interactive mode.

### Using `EasyAlign` in command line

Instead of going into the interactive mode, you can just type in arguments to
`:EasyAlign` command.

```vim
" Using predefined alignment rules
:EasyAlign[!] [N-th] DELIMITER_KEY [OPTIONS]

" Using arbitrary regular expressions
:EasyAlign[!] [N-th] /REGEXP/ [OPTIONS]
```

For example, when aligning the following lines around colons and semi-colons,

    apple;:banana::cake
    data;;exchange:;format

try these commands:

- `:EasyAlign /[:;]\+/`
- `:EasyAlign 2/[:;]\+/`
- `:EasyAlign */[:;]\+/`
- `:EasyAlign **/[:;]\+/`

You can also provide a number of alignment options, [which will be discussed in
detail later](https://github.com/junegunn/vim-easy-align#alignment-options),
to EasyAlign command in Vim dictionary format.

- `:EasyAlign * /[:;]\+/ { 'stick_to_left': 1, 'left_margin': 0 }`

Which means that the matched delimiter should be positioned right next to the
preceding token, without margin on the left. So we get:

    apple;: banana::   cake
    data;;  exchange:; format

Option names are fuzzy-matched, so you can write as follows:

- `:EasyAlign * /[:;]\+/ { 'stl': 1, 'l': 0 }`

You can even omit spaces between the arguments, so concisely (or cryptically):

- `:EasyAlign*/[:;]\+/{'s':1,'l':0}`

Nice. But let's make it even shorter. Option values can be written in shorthand
notation.

- `:EasyAlign*/[:;]\+/s1l0`

The following table summarizes the shorthand notation.

| Option           | Expression |
| ---------------- | ---------- |
| filter           | `[gv]/.*/` |
| left_margin      | `l[0-9]+`  |
| right_margin     | `r[0-9]+`  |
| stick_to_left    | `s[01]`    |
| ignore_unmatched | `iu[01]`   |
| ignore_groups    | `ig\[.*\]` |
| delimiter_align  | `d[lrc]`   |
| mode_sequence    | `m[lrc*]*` |
| indentation      | `i[ksdn]`  |

For your information, the same thing can be done in the interactive mode as well
with the following key combination.

- `<Enter>`
- `*`
- `<Left>`
- `<CTRL-/>` (or `<CTRL-X>` on GVim)
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

### EasyAlign as Vim operator

You can define an operator function which executes EasyAlign command, so that it
can be used with a Vim movement.

```vim
function! s:easy_align_1st_eq(type, ...)
  '[,']EasyAlign=
endfunction
nnoremap <Leader>= :set opfunc=<SID>easy_align_1st_eq<Enter>g@

function! s:easy_align_1st_colon(type, ...)
  '[,']EasyAlign:
endfunction
nnoremap <Leader>: :set opfunc=<SID>easy_align_1st_colon<Enter>g@
```

Now without going into visual mode, you can align the lines in the paragraph
by `<Leader>=ip` or `<Leader>:ip`.

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
| `mode_sequence`    | string  |                       | Alignment modes for multiple occurrences of delimiters  |

There are 4 ways to set alignment options (from lowest precedence to highest):

1. Some option values can be set with corresponding global variables
2. Option values can be specified in the definition of each alignment rule
3. Option values can be given as arguments to `:EasyAlign` command
4. Option values can be set in interactive mode using special shortcut keys

| Option name        | Shortcut key        | Abbreviated | Global variable                 |
| ------------------ | ------------------- | ----------- | ------------------------------- |
| `filter`           | `CTRL-F`            | `[gv]/.*/`  |                                 |
| `left_margin`      | `CTRL-L`            | `l[0-9]+`   |                                 |
| `right_margin`     | `CTRL-R`            | `r[0-9]+`   |                                 |
| `stick_to_left`    | `<Left>`, `<Right>` | `s[01]`     |                                 |
| `ignore_groups`    | `CTRL-G`            | `ig\[.*\]`  | `g:easy_align_ignore_groups`    |
| `ignore_unmatched` | `CTRL-U`            | `iu[01]`    | `g:easy_align_ignore_unmatched` |
| `indentation`      | `CTRL-I`            | `i[ksdn]`   | `g:easy_align_indentation`      |
| `delimiter_align`  | `CTRL-D`            | `d[lrc]`    | `g:easy_align_delimiter_align`  |
| `mode_sequence`    | `CTRL-O`            | `m[lrc*]*`  |                                 |

### Filtering lines

With `filter` option, you can align lines that only match or do not match a
given pattern. There are several ways to set the pattern.

1. Press `CTRL-F` in interactive mode and input `g/pat/` or `v/pat/`
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

Satisfied? :satisfied:

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

Notice that `idt` is fuzzy-matched to `indentation`.

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

In addition to these, you can fine-tune alignments over multiple occurrences of
the delimiters with 'mode_sequence' option. (The option can also be set
in interactive mode with the special key `CTRL-O`)

```vim
" Left alignment over the first two occurrences of delimiters
:EasyAlign = { 'mode_sequence': 'll' }

" Right, left, center alignment over the 1st to 3rd occurrences of delimiters
:EasyAlign = { 'm': 'rlc' }

" Using shorthand notation
:EasyAlign = mrlc

" Right, left, center alignment over the 2nd to 4th occurrences of delimiters
:EasyAlign 2=mrlc

" (*) Repeating alignments (default: l, r, or c)
"   Right, left, center, center, center, center, ...
:EasyAlign *=mrlc

" (**) Alternating alignments (default: lr or rl)
"   Right, left, center, right, left, center, ...
:EasyAlign **=mrlc

" Right, left, center, center, center, ... repeating alignment
" over the 3rd to the last occurrences of delimiters
:EasyAlign 3=mrlc*

" Right, left, center, right, left, center, ... alternating alignment
" over the 3rd to the last occurrences of delimiters
:EasyAlign 3=mrlc**
```

### Extending alignment rules

Although the default rules should cover the most of the use cases,
you can extend the rules by setting a dictionary named `g:easy_align_delimiters`.

You may refer to the definitions of the default alignment rules
[here](https://github.com/junegunn/vim-easy-align/blob/2.6.1/autoload/easy_align.vim#L29).

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

There are two well-known plugins with the same goal as that of vim-easy-align.

- [DrChip's Alignment Tool for Vim](http://www.drchip.org/astronaut/vim/align.html) (herein will be referred to as "Align")
- [Tabular](https://github.com/godlygeek/tabular)

Both are great plugins with very large user bases. I actually had been a Tabular
user for a couple of years before I finally made up my mind to roll out my own.

So why would someone choose vim-easy-align over those two?

Feature-by-feature comparison I believe is not quite useful, since a typical
user will end up using only a small subset of the features.
So I will mention just a few core benefits of vim-easy-align.

### Ease of use

As the name implies, vim-easy-align is *easier* to use. Its interactive mode
allows you to achieve what you want with just a few keystrokes.
The key sequence is mnemonic, so it's easy to remember and execute.
It even feels like a native Vim command!

- *Right-align*: `<Enter><Enter>`
- around the *second* occurrences: `2`
- of *whitespaces*: `<space>`

For the simplest cases, Tabular and Align are also easy to use. But sooner or
later, you will find yourself scratching your head, trying to come up with some
complex regular expressions.

_"How am I going to align the third to the last word in each line to the right
without affecting the ones before it?"_

### Clean

vim-easy-align doesn't clutter your workspace with mappings and global
variables. All you would need is a single mapping to the interactive EasyAlign
command, and even that is totally up to you.

### Optimized for code editing

vim-easy-align by default performs syntax-aware alignment, which is invaluable
when editing codes.

Try to come up with a regular expression to correctly format the following code
snippet. With vim-easy-align under default configuration and a mapping, it can
be done with just two keystrokes: `<Enter>:`

```javascript
var jdbc = {
  // JDBC driver for MySQL database:
  driver: "com.mysql.jdbc.Driver",
  /* JDBC URL for the connection (jdbc:mysql://HOSTNAME/DATABASE) */
  url: 'jdbc:mysql://localhost/test',
  database: "test",
  "user:pass":"r00t:pa55"
};
```

(To be fair, Align also can be configured to consider syntax highlighting with
`g:AlignSkip` function reference which should point to a custom function that
looks up the syntax group of a character on a certain position)

### Thoroughly tested

Virtually every aspect of vim-easy-align is being tested with a comprehensive
set of test cases using [Vader.vim](https://github.com/junegunn/vader.vim).

### "Okay. So should I switch?"

Maybe, but I can't really say. I have no ambition to make vim-easy-align
an absolute superior to the others. For some cases, vim-easy-align works better
than the others, but for some other cases, Tabular or Align.vim might be a
better choice.

So try it yourself and see if it works for you!

Author
------

[Junegunn Choi](https://github.com/junegunn)

License
-------

MIT
