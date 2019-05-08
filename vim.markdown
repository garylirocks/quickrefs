# Vim cheatsheet

- [Motions](#motions)
  - [Left-right motions](#left-right-motions)
  - [Up-down motions](#up-down-motions)
  - [Word motions](#word-motions)
  - [Text object motions](#text-object-motions)
  - [Marks](#marks)
    - [Examples](#examples)
  - [Jumps](#jumps)
  - [Various motions](#various-motions)
  - [Tags](#tags)
- [Editing](#editing)
  - [Operators](#operators)
  - [Text objects](#text-objects)
  - [Examples](#examples-1)
  - [Increase / Decrease numbers](#increase--decrease-numbers)
  - [Indent lines](#indent-lines)
  - [Abbreviations](#abbreviations)
  - [Word completion](#word-completion)
- [Search and replace](#search-and-replace)
  - [Special characters in a replacement pattern](#special-characters-in-a-replacement-pattern)
  - [Copy from one location, replacing multiple locations](#copy-from-one-location-replacing-multiple-locations)
- [Regular Expressions](#regular-expressions)
  - [Enable ERE (extended regular expression)](#enable-ere-extended-regular-expression)
  - [About new line](#about-new-line)
  - [Lookahead / Lookbehind modifiers](#lookahead--lookbehind-modifiers)
- [Buffer, Window and Tab](#buffer-window-and-tab)
  - [Concepts](#concepts)
  - [Multiple buffers](#multiple-buffers)
  - [arglist](#arglist)
  - [Multiple windows](#multiple-windows)
  - [Tabs](#tabs)
  - [Tag with windows](#tag-with-windows)
- [Record and Play](#record-and-play)
- [Copy and Paste](#copy-and-paste)
- [Command macros](#command-macros)
- [Registers](#registers)
- [Options](#options)
- [Modes](#modes)
  - [ex mode](#ex-mode)
  - [visual mode](#visual-mode)
- [Plugins](#plugins)
  - [Vundle](#vundle)
  - [Useful Plugins](#useful-plugins)
  - [vim-surround](#vim-surround)
- [Miscs](#miscs)
  - [Avoid the Esc key](#avoid-the-esc-key)
  - [Save a readonly file](#save-a-readonly-file)
  - [Add a new filetype](#add-a-new-filetype)
  - [Encoding](#encoding)
  - [Save session](#save-session)
  - [Folding](#folding)
- [Refs](#refs)

## Motions

### Left-right motions

```
[count]h/l
0, <Home>       # first character of the line
^               # first non-blank character of the line
$, <End>        # end of the line
g0, g^, g$      # moves on the screen line when lines wrap
[count]|        # to screen column [count]
[count]f{char}  # to [count]'th occurence of {char} to the right
[count]F{char}  # to [count]'th occurence of {char} to the left
[count]t{char}  # till before [count]'th occurence of {char} to the right
[count]T{char}  # till after [count]'th occurence of {char} to the left
;               # repeat lastest f/F/t/T motion
,               # repeat lastest f/F/t/T motion in opposite direction
```

### Up-down motions

```
[count]j/k
gj, gk          # [count] display lines up/down when line wraps
-, +            # up/down to first non-blank character
G               # Goto last line
gg              # Goto first line
[count]G/gg     # Goto line [count]
:[range]        # go to last line in [range], which can be ":22", ":+5" or ":'mark"
{count}%        # go to {count} percentage of the file
```

### Word motions

```
[count]w/W      # [count] words/WORDS forward
[count]e/E      # forward to the end of word/WORD [count]
[count]b/B      # [count] words/WORDS backward
```

_a WORD consists of any non-blank characters_

### Text object motions

```
(       # to beginning of current sentence
)       # to beginning of next sentence
{       # to beginning of current paragraph
}       # to beginning of next paragraph
[[      # sections backward or to the previous '{' in the first column, can be used to find methods
]]      # sections forward or to the next '{' in the first column
```

### Marks

```
m{a-zA-Z}   # create a mark at current position
m' or m`    # set previous context mark, can be jumped to with "''" or "``"

:[range]ma[rk] {a-zA-Z'}
:[range]k{a-zA-Z'}      # set mark
:marks                  # show marks
:marks {arg}            # args can be "ab", "{A-Z}" etc
:delm[arks] {marks}     # delete marks
:delm[arks]!            # delete marks for current buffer
```

```
'{a-z} `{a-z}       # jump to the mark

''  ``              # the position before the latest jump, or where "m'" or "m`" was given

'[ '] `[ `]         # the first/last line of previously changed or yanked text
'< `< '> `>         # the first/last char/line of last selected Visual area
'" `"               # cursor position when last exiting the current buffer
'^ `^               # last Insert mode postion
'. `.               # last chnage position
```

- Marks are NOT the same as named registers;
- Types of marks
  - `'{a-z}` lowercase marks, valid within a file;
  - `'{A-Z}` uppercase marks, valid between files;
  - `'{0-9}` numbered marks, set from .viminfo file;

#### Examples

```
d`a         # delete until mark `a
10yy']      # yanking 10 lines and go to the last line
```

### Jumps

- Vim keeps a jump list and a change list (for each window), you can go back and forth in them;
- Each window has its own jump list, which can span multiple files, if you start editing a new file, you can still jump back to the old file;
- A "jump" is one of the following commands: "'", "`", "G", "/", "?", "n", "N", "%", "(", ")", "[[", "]]", "{", "}", ":s", ":tag", "L", "M", "H" and the commands that start editing a new file;

```
CTRL-O          # go back in jump list
CTRL-I, <Tab>   # go forward in jump list

g;              # go back in change list
g,              # go forward in change list

:jumps          # jump list
:changes        # change list
```

### Various motions

```
%               # jumps to matching bracket (customizable with `matchpairs' option)

H               # (High) move cursor to screen top
M               # (Middle) move cursor to screen middle
L               # (Low) move cursor to screen bottom

CTRL-E          # scroll down one line
CTRL-Y          # scroll up one line
CTRL-B          # scroll Back
CTRL-F          # scroll Forward
CTRL-D          # scroll Down (half a window by default)
CTRL-U          # scroll Up (half a window by default)

z<Enter> / zt   # scroll current line to top of screen
z. / zz         # scroll current line to middle of screen
z- / zb         # scroll current line to bottom of screen
```

### Tags

In project root dir, create a tags file (`.TAGS`) for all your code files, this tags file should be ignored by Git.

```sh
# find '.php' files recursively in current directory and create a tag file '.TAGS'
etags -R -h '.php' -f .TAGS .

# list supported languages
etags --list-languages
```

Use tags in Vim:

```
CTRL-]              # jump to the tag your cursor is on
CTRL-T              # jump back

:tag <tag-name>     # jump to <tag-name>
:tags               # show tag stack
```

## Editing

Think _operators_, _text objects_, and _motions_, _operators_ acts upon _text objects_ and _motions_;

### Operators

```
:h operator

c   change
d   delete
y   yank into register (does not change the text)
~   swap case (only if 'tildeop' is set)
g~  swap case
gu  make lowercase
gU  make uppercase
!   filter through an external program
=   indent
>   shift right
<   shift left
```

### Text objects

```
:h text-object

aw              a word (including following whitespace)
iw              inner word (don't include whitespace)

aW              a WORD (including all non-blank characters)
iW              inner WORD

ap              a paragraph (including following empty line)
ip              inner paragraph

as              a sentence
is              inner sentence

at              HTML/XML tag block
it              inner tag block

a(, a), ab
i(, i), ib      () block

a], a[
i], i[          [] block

a<, a>
i<, i>          <> block

a{, a}, aB
i{, i}, iB      {} Block

a", a', a`
i", i', i`      quote block
```

### Examples

![Vim motions](./images/vim_motions.png)

```
ciw     change current word (only the word is deleted, the spaces after it are keeped)
caw     change current word (the space after the word will be deleted too)

cis     change current sentence
ci(     change everything in the parenthesis: delete all the content and put you in insert mode

gUiw    change word to UPPERCASE
```

### Increase / Decrease numbers

```
[count]CTRL-a   # increase the number by [count]
[count]CTRL-x   # decrease the number by [count]
```

### Indent lines

```
>>              # increase indentation for current line
<<              # decrease indentation for current line
```

- In insert mode:

  ```
  CTRL-t          # increase indentation
  CTRL-d          # decrease indentation
  ```

- Visual mode: select lines, use `>` to indent them;
- Indent a block: place cursor on one of the brackets, then `>%` to indent the block;

### Abbreviations

**Turn off paste mode** for this abbreviations to work

```
:ab <abbr> <phrase>     # when in insert mode, <abbr> inputted as a whole word will be expanded to <phrase> automatically
:ab                     # list all abbreviations
:unab <abbr>            # disable <abbr> abbreviation
```

Example:

```
:ab DB Database         # input 'DB' to get 'Database'
```

### Word completion

Use `CTRL-X` followed by:

- `CTRL-N/P` word, search current file
- `CTRL-L` whole line
- `CTRL-F` filename

- `CTRL-I` word, search current file and included files
- `CTRL-K` dictionary, dictionary files is set by `set dictionary` such as `set dictionary=~/.mydict`, put any words you want in the file `~/.mydict`
- `CTRL-T` thesaurus file is set by `set thesaurus`
  such as `set thesaurus=~/.mythesaurus`

Dictionary file example:

```
china
zhongguo
lenovo
```

Thesaurus file example, in insert mode, when you place the cursor after a word, then `CTRL-X CTRL-T`, a list of synonyms from this file would show up:

```
fun enjoyable desirable
funny hilarious lol lmao
retrieve getchar getcwd getdirentries getenv
```

## Search and replace

```
:set ic          # set ignore case in search on
:set is          # set increment search on
:set his         # set highlight search on
```

```
*                # search for the word under cursor
#                # same as above, opposite direction
gd               # go to local declaration
```

```
/whereisyou\c                   # ignore case in this search

:%s/old/new/gc                  # confirm before replace
:s/.*/\U&/                      # change a line to uppercase
:s/\<file\>/&s/                 # add 's' to a 'file', '\<' means word start, '\>' means word end, '&' in relace string represents text matched

:g/^$/ d                        # delete all empty lines
:g/^[[:space:]]*$/ d            # delete all blank lines(only contains spaces)

:g/^/ mo 0                     # reverse order of lines in a file (by moving each line to line 1 in order)

:g/hint mode/ s/open/OPEN/gc    # replace only in lines match 'hint mode'

:g!/integer/ s/$/ NO-INT/      # append a 'NO-INT' to each line which does not contain 'integer'

:/^Part 2/,/^Part 3/g /^Chapter/ .+2w >> begin  # write the second line of each Chapter in Part 2 to a file named 'begin'
```

```
:s                              # the same as `:s//~/`, repeat last substitution

:&                              # repeat last substitution
&                               # same as above

:%&g                            # repeat last substitution globally

:~                              # similar to `:&`, the search pattern used is the last search pattern used in any command, not just last substition command, example:

:s/red/blue/
/green
:~                              # replace 'green' to 'blue'
```

### Special characters in a replacement pattern

- `&` means the entire string matched by the search pattern: `:s/tab/(&)/`, add parenthesis to 'tab';

- `~` means your last replacement pattern,

```
:s/tab/(&)/     # add parenthesis to 'tab'
:s/open/~/      # add parenthesis to 'open'
```

- `\u`, `\l` causes the following character to upper or lower case

```
:s/\(you\)\(.*\)\(he\)/\u\3\2\u\1/      # switch 'you' and 'he', and to 'You' and 'He'
```

- `\U`, `\L`, `\e`, `\E` causes characters up to `\e`, `\E` or end of string to change case

```
:s/should/\U&/g     # change 'should' to upper case
```

### Copy from one location, replacing multiple locations

1. `yiw` # copy a word
2. ... # move to destination
3. `ciw<CTRL-R>0<Esc>` # replace the current one with the yanked one in register 0

define a map for the last command: `map <leader>rr ciw<CTRL-R>0<Esc>`, so you can just use `<leader>rr` to get the work done;

## Regular Expressions

- most characters lose their special meaning inside brackets, you don't need to escape them. There are threee characters you still need to escape: `]-/`

- in vi, `\<` matches the beginning of a word, `\>` matches the end of a word

### Enable ERE (extended regular expression)

by default, vim use basic regular expressions, which means

`.`, `*`, `\`, `[`, `^`, and `$` are metacharacters

`+`, `?`, `|`, `{`, `(`, and `)` must be escaped to use their special function.

to match a string like this `AAAA`, you should use `/A\{4\}`, you can **enable extended regex syntax by prepending the pattern with `\v` (very magic)**, so this pattern can be written as `/\vA{4}`

### About new line

when searching:

`\n` is newline, `\r` is `CR` (carriage return = Ctrl-M = `^M`)

when replacing:

`\r` is newline, `\n` is a null byte (0x00 = `^@`)

### Lookahead / Lookbehind modifiers

To find `Gary` in `GaryLi`:

- In PCRE, you use `Gary(?=Li)`
- PCRE is not supported in Vim, its syntax (ECE mode):

  `Gary(Li)@?=`

- Reference:

  - `@?=`: positive lookahead;
  - `@?!`: negative lookahead;
  - `@?<=`: prositive lookbehind;
  - `@?<!`: negative lookbehind;

## Buffer, Window and Tab

### Concepts

Tabs for window containers;
Windows for buffer viewports;
Buffers for file proxies;

### Multiple buffers

```
gf                      # open file under cursor

:e[dit] {file}          # open another file
:fin[d] {file}          # find a file in 'path' and edit it

:bo[tright] term        # open a terminal window at the bottom
```

```
:ls, :files, :buffers   # list all buffers

:bn / :bp               # switch to next/previous buffer

:b <n>                  # move to buffer <n>
:sb[uffer] <n>          # opens a new window for buffer <n>

CTRL-^                  # edit the alternate file

:bufdo <cmd>            # executes <cmd> in all buffers
```

Vim has special filenames:

- `%` means current filename;
- `#` means alternative filename, these can be used for easy file switching between two files;
- `##` all files in the arglist;

```
:e #                    # switch to last file you were editting, you can also use CTRL-^
:w %.new                # save a copy of current file, with a '.new' appended to the current filename
```

### arglist

- When starging Vim with more than one file names, the list is remembered as the argument list;
- It's different from buffer list, arglist was already in Vi, and buffer list is new in Vim;
- Every file in arglis is also in buffer list, but buffer list commonly has more files;
- There is a global arglist used by all windows, and it's possible to create a new arglist local to a window;

```
:args               # print arglist
:args {arglist}     # define {arglist} as the new arglist

:arga {name}        # add {name} to the arglist

:n[ext]             # edit next file in the arglist
:wn[ext]            # write current file and start editing the next
:wp[revious]        # write current file and start editing the previous file

:first / :last      # switch to the first/last buffer

:argdo {cmd}        # execute {cmd} for each file the arglist
```

Local arglist

```
:argl[ocal]         # make a local copy of the global arglist

:argg[lobal]        # use the global arglist for current window
```

When a window is split, the new window inherits the arglist from current window.

Example:

Replace word "my_foo" to "My_Foo" in all `*.c` and `*.h` files, and save the files

```
:args *.[ch]
:argdo %s/\<my_foo\>/My_Foo/ge | update
```

### Multiple windows

Open multiple files in multiple windows, use the `-o` option

```sh
vi -o file1 file2
vi -O file1 file2     # split windows vertically

vi -o4 file1 file2    # open 4 windows at once, the last two will be empty
```

In vim:

```
:split [<file>],  :new,  ^ws     # split window horizontally
:vsplit [<file>], :vnew, ^wv     # split window vertically
:close [<file>],         ^wc     # close a window
:only,                   ^wo     # make current window the only one

^w[hjkl]            # move between windows
^ww                 # cycle through all windows
^wp                 # go to previous window
^wt                 # go to the top window
^wb                 # go to the bottom window

^wr                 # rotate windows
^wR                 # rotate windows in opposite direction

^wx                 # exchange windows
^w<n>x              # exchange with the <n>th windows

^w[HJKL]            # move and reflow windows, 'H' move current window to left most and make it take full height of the screen
^wT                 # move current window to a new tab

^w-                 # decrease windows height by one line
^w+                 # increase windows height by one line
^w[<>]              # decrease/increase windows width
^w|                 # make current window widest size possible
:resize [-+]n       # decrease/increase windows height by <n> lines
:resize n           # set windows height to n lines

:windo <cmd>        # executes <cmd> in each window
:sf {file}          # split window and :find {file}
:vert {cmd}         # make any split {cmd} vertical
```

Example:

```
:args *.js              # use all *.js as the arglist
:vert sall              # split all in arglist vertically
:windo diffthis         # show diff
```

### Tabs

**Different tabs are like multiple desktops, multiple windows can be opened in one tab**

Open and close tab page

```
$ vim -p file1 file2    # open each file in a tab page

:tabe file_name         # open file in a new tab
:tabc                   # close current tab
:tabo                   # close all other tabs
```

Navigation

```
gt / gT         # go to next / previous tab in normal mode

:tabs           # list all tabs
:tabn           # switch to next tab
:tabp           # switch to previous tab
:tabfirst       # switch to first tab
:tablast        # switch to last tab
```

or try to use `CTRL-ALT-PageUp/PageDown` to switch tab (may only available in some systems)

### Tag with windows

```
^wg]        # create a new window, open the file containing tag under the cursor

^wf         # create a new window, open the file under the cursor
^wgf        # create a new tab, open the file under the cursor
```

## Record and Play

1. (in normal mode) press `qa` : start recording, then do whatever operation you want to be recorded;
2. (in normal mode) press `q`, stop recording;
3. (in normal mode) press `@a`, replay macro a;
4. Use `@@` to repeat last replay;

## Copy and Paste

If you paste some text, and the indentation screwed up, use the following command before you actually paste anything

```
:set paste
```

Copy to named registers

```
"a2yy    # copy two lines to buffer a
"ap      # paste from buffer a
```

Using ex command

```
:7,13ya a   # yank line 7 through 13 to buffer a
:pu a       # put buffer a after the current line
```

Copy to and paste from system clipboard, in X11 system register `*` means _PRIMARY_ SELECTION, register `+` means _CLIPBOARD_
(Ref: [Accessing_the_system_clipboard](http://vim.wikia.com/wiki/Accessing_the_system_clipboard))

```
"+p         # paste
"+yy        # copy current line
:% y +      # copy all lines
```

## Command macros

```
:map <x> <sequence>         # define <x> as a macro for command <sequence>, <x> may be function keys, `#1` for F1
:map                        # list all command macros
:unmap <x>                  # disable <x>

:map V dwelp                # map V as `dwelp`, which swaps words

:map =i I<i>^[              # add '<i>' tag at line beginning
:map =I A</i>^[             # add '</i>' tag at line ending
```

`map!`, `unmap!` for define and remove key mappings in insert mode

    :map! =b <b></b>^[F<i       # define `=b` as insert '<b></b>' in current editing position and place the input cursor in between(which can not be done by abbreviation)

Keys may be used in user defined commands:

- Letters: `g`, `K`, `V`
- Control keys: `^A`, `^K`, `^O`, `^W`, `^X`
- Symbols: `_`, `*`, `\`, `=`

You can store command sequence in named buffers, and execute it using `@` functions, e.g.,

1. Input this at a new line `cwhello world^[`, (the last character is an escaped <Esc>) then <Esc> to exit insert mode;
2. `"gdd` put this line in buffer `g`;
3. Place the cursor at beginning of a word, and `@g` will execute the macro in buffer g, and replace the word with `hello world`;

## Registers

Registers are used for recording, copying:

- In normal mode:

  - `@x` replays register `x`;
  - `"xp` pastes content from register `x`;

- In insert or command mode:

  - `CTRL-R` followd by `x` pastes content from register `x`;

- Special registers:

  - `%`: relative path of current file, so `"%p` pastes the current file path;
  - `#`: relative path of the alternative file;
  - `_`: blackhole/null register;
  - `"`: unamed register, deleting, changing and yanking text copies the text to this register, `p` paste from this register;
  - `0`: yanking text copies it to this register and the unnamed register `"` as well;

- You can edit register contents in command line: `:let @q = 'macro contents'`
- Or show all registers by `:reg[isters]`;

## Options

```
:set all        # show all options
:set            # show options you changed, including changes in your .vimrc file or in this session
:set option?    # find out current value of an option

:set list       # display tab and newline characters
:5,20 l         # temporarily display tab and newline characters of line 5 through 20
```

## Modes

### ex mode

```
Q                   # go to ex mode
:vi                 # go back to vi mode

:sh                 # create a shell without exiting vi, go back to vi using CTRL-D
:r !sort file       # read in file in sorted order
:31,34!sort -n      # sort lines from 31 through 34 as numbers

!<move><command>    # filtering text selected by <move> using <command>
<num>!!<command>    # filtering <num> lines using <command>
```

### visual mode

```
viw         # go into visual mode, selecting current word
vis         # go into visual mode, selecting current sentence
vi"         # go into visual mode, selecting current everything inside "
vi(         # go into visual mode, selecting current everything inside (
```

Select text objects in visual mode:

```
<count>aw   # select <count> words(delimited by punctuations)
<count>aW   # select <count> words(delimited by white space)
as, is      # add sentence, or inner sentence
ap, ip      # add paragraph, or inner paragraph
```

Blockwise mode

```
CTRL-V      # select a rectangular area
```

If you used `CTRL-V` for pasting in your terminal program, you may need `CTRL-SHIFT-V`

## Plugins

- `.vim` files in `.vim/plugin` folder are loaded automatically when Vim starts;

### Vundle

Vundle is one of the best Vim plugin managers, go to https://github.com/VundleVim/Vundle.vim for details

To use it:

1. Clone vundle to `~/.vim/bundle/Vundle.vim`

```sh
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

2. Configure plugins in `.vimrc`
3. Launch vim and run `:PluginInstall`

### Useful Plugins

- ctrl-p

  Use `CTRL-P` to start searching files

  `CTRL-R` to switch to regex mode

  `CTRL-T`, `CTRL-V`, `CTRL-X` to open the file in new tab / vertical split / horizontal split

  `CTRL-Y` to create a new file and its parent directories

- nerdtree

  file system explorer

- nerdtree-tabs

  makes the file system explorer consistent across all tabs

- vim-airline

  beautiful status line

- syntastic

  syntax checker

- easytags

  update tags file automatically

- tagbar

  show all tags in a separate window

- vim-surround

- vim-repeat

  make vim-surround actions repeatable with `.`

### vim-surround

easily delete, change and add surroundings in pairs, surroundings can be parentheses, brackets, html/xml tags

```
Hello World
```

to add surroundings, in visual mode, select the two words, `S'`, it must be a capital `S` here

```
'Hello World'
```

to change surroundings, `cs'"`

```
"Hello World"
```

to change to tags, `cs"<span>`

```
<span>Hello World</span>
```

to change the surrounding tags, `cst"`

```
"Hello World"
```

to remove surroundings, `ds"`

```
Hello World
```

to add surroundings on a word, `ysiw]`

```
[Hello] World
```

to add braces and spaces, `cs[{`, a left brace `(`, `[`, `{` will add a space after it as well

```
({ Hello } World)
```

to add parentheses to the entire line, `yss)`

```
{ Hello } World
```

to use a tag, `cs}<em>`

```
<em> Hello </em> World
```

to wrap it in another tag, use `V` to select the whole line, then `S<p class="notice">`

```
<p class="notice">
    <em> Hello </em> World
</p>
```

## Miscs

```
CTRL-G          # show file info
:=              # show line numbers of file
:#              # show current line number
:-10,$ #        # show the last 10 lines' number

:set binary     # set vim in binary mode, vim by default writes the file with a final new-line appended, in binary mode this doesn’t happen

:CTRL-F         # edit command history
```

### Avoid the Esc key

    CTRL-[, CTRL-c      # escape from edit mode to normal mode, replace the '<Esc>' key

or

    alt+h/j/k/l         # alt followed by any normal mode key, will exit from the insert mode and take the normal mode action

### Save a readonly file

you opened a file which is readonly to you(you do not add `sudo` to your command), made some changes, when you save, you got an error, to save this file as root, do this:

    :w !sudo tee %

you can also save to a new file which you have write permission, then move it to the original file

    :w /path/to/another_file

### Add a new filetype

e.g. treat `.md` file as markdown files, to use syntax highlighting, add following lines to `~/.vim/filetype.vim`, ref `:help new-filetype`

    $ cat ~/.vim/filetype.vim
    " my filetype file

    if exists("did_load_filetypes")
      finish
    endif

    augroup filetypedetect
      au! BufRead,BufNewFile *.md       setfiletype markdown
    augroup END

### Encoding

use fencview.vim plugin to autodetect encodings, which provides two commands:

    :FencView           -> let you select an encoding for the buffer
    :FencAutoDetect     -> auto detect and convert encodings automatically

### Save session

save session info in a file

    :mksession ~/myVimSession.vim

reenter a session:

    $ vi
    :source ~/myVimSession.vim

### Folding

    za      # open or close folds

## Refs

[Talk on going mouseless with Vim, Tmux and Hotkeys](https://youtu.be/E-ZbrtoSuzw)
