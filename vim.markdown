# Vim cheatsheet

- [Vim cheatsheet](#vim-cheatsheet)
  - [Preface](#preface)
  - [Moving around](#moving-around)
    - [Jumping](#jumping)
    - [Scrolling](#scrolling)
    - [Tags](#tags)
  - [Search and replace](#search-and-replace)
    - [Copy from one location, replacing multiple locations](#copy-from-one-location-replacing-multiple-locations)
    - [Special characters in a replacement pattern](#special-characters-in-a-replacement-pattern)
  - [Regular Expressions](#regular-expressions)
    - [Enable ERE (extended regular expression)](#enable-ere-extended-regular-expression)
    - [About new line](#about-new-line)
    - [Lookahead/lookbehind modifiers](#lookaheadlookbehind-modifiers)
  - [Editing](#editing)
    - [Change a word/sentence](#change-a-wordsentence)
    - [Change word to uppper/lower case](#change-word-to-uppperlower-case)
    - [Increase / Decrease numbers](#increase--decrease-numbers)
    - [Indent lines](#indent-lines)
    - [Abbreviations](#abbreviations)
    - [Word completion](#word-completion)
    - [Command macros](#command-macros)
  - [Edit multiple files](#edit-multiple-files)
    - [multiple buffers](#multiple-buffers)
    - [multiple windows](#multiple-windows)
    - [tab page](#tab-page)
    - [tag with windows](#tag-with-windows)
  - [Record and Play](#record-and-play)
  - [Copy and Paste](#copy-and-paste)
  - [Registers](#registers)
  - [Options](#options)
  - [Miscs](#miscs)
    - [Avoid the Esc key](#avoid-the-esc-key)
    - [Save a readonly file](#save-a-readonly-file)
    - [Add a new filetype](#add-a-new-filetype)
    - [Encoding](#encoding)
    - [Save session](#save-session)
    - [Folding](#folding)
  - [Modes](#modes)
    - [ex mode](#ex-mode)
    - [visual mode](#visual-mode)
  - [plugins](#plugins)
    - [Vundle](#vundle)

## Preface

Some useful tips for vim
Source:

## Moving around

### Jumping

    ^   # move to first nonblank character of current line

    m<x>    # create a mark <x> at current position
    `<x>    # jump to mark <x>, can be used to edit/delete a chunk of code
    ``  # move to previous mark or context
    ''  # move to line beginning of previous mark or context

    `.  '. g;  # to the last change position
    `^  '^  # to the position where last Insert mode was stopped
    g,		# moves back in edit history

    fx      # move to next occurence of x in current line
    Fx      # move to previous occurence of x in current line
    tx      # move to just before next occurence of x in current line
    Tx      # move to just after  previous occurence of x in current line
    ;       # repeat previous find in same direction
    ,       # repeat previous find in opposite direction

    (   # to beginning of current sentence
    )   # to beginning of next sentence
    {   # to beginning of current paragraph
    }   # to beginning of next paragraph
    [[   # to beginning of current section
    ]]   # to beginning of next section

    %    # when the cursor is on a bracket, it will jump to the matching one; else it will jump to a bracket character

### Scrolling

    z<Enter>    # scroll current line to top of screen
    z.   # scroll current line to middle of screen
    z-   # scroll current line to bottom of screen

    H    # move cursor to screen top
    M    # move cursor to screen middle
    L    # move cursor to screen bottom

### Tags

in project root dir, create tags file (`.TAGS`) for all php files, you should add the `.TAGS` to svn ignore (add it to `~/.subversion/config`)

    $ etags -R -h '.php' -f .TAGS .

use tags in Vim:

    Ctrl+]      # jump to the tag your cursor is on
    Ctrl+T      # jump back

    :tag <tag-name>     # jump to <tag-name>
    :tags       # show tag stack

## Search and replace

```
:set ic          # set ignore case in search on
:set is          # set increment search on
:set his         # set highlight search on
```

```
*                # search for the word under cursor
```

```
/whereisyou\c                   # ignore case in this search

:%s/old/new/gc                  # confirm before replace

:g/^$/ d                        # delete all empty lines
:g/^[[:space:]]*$/ d            # delete all blank lines(only contains spaces)
:s/.*/\U&/                      # change a line to uppercase

:g/^/ mo 0                     # reverse order of lines in a file (by moving each line to line 1 in order)

:g!/integer/ s/$/ NO-INT/      # append a 'NO-INT' to each line which does not contain 'integer'

:/^Part 2/,/^Part 3/g /^Chapter/ .+2w >> begin  # write the second line of each Chapter in Part 2 to a file named 'begin'

:s/\<file\>/&s/  # '&' in relace string represents text matched

:g/hint mode/ s/open/OPEN/gc    # replace only in lines match 'hint mode'

:s                              # the same as `:s//~/`, repeat last substitution
:&                              # repeat last substitution
&                               # repeat last substitution
:%&g                            # repeat last substitution globally
:~                              # similar to `:&`, the search pattern used is the last search pattern used in any command, not just last substition command, example:

:s/red/blue/
/green
:~              # replace green to blue
```

### Copy from one location, replacing multiple locations

1. `yiw` # copy a word
2. ... # move to destination
3. `ciw<C-r>0<Esc>` # replace the current one with the yanked one in register 0

define a map for the last command: `map <leader>rr ciw<C-r>0<Esc>`, so you can just use `<leader>rr` to get the work done;

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

### Lookahead/lookbehind modifiers

To find `Gary` in `GaryLi`:

- In PCRE, you use `Gary(?=Li)`
- PCRE is not supported in Vim, its syntax (ECE mode):

  `Gary(Li)@?=`

- Reference:

  - `@?=`: positive lookahead;
  - `@?!`: negative lookahead;
  - `@?<=`: prositive lookbehind;
  - `@?<!`: negative lookbehind;

## Editing

### Change a word/sentence

    ciw		change current word (only the word is deleted, the spaces after it are keeped)
    caw		change current word (the space after the word will be deleted too)

    cis		change current sentence
    cip		change current passage
    ci(		change everything in the parenthesis: delete all the content and put you in insert mode

### Change word to uppper/lower case

select character you want to change, use the `~` key to change word case

    g~iw    change word case of the word you cursor is on
    g~ip    change word case of the paragraph you cursor is on

### Increase / Decrease numbers

place your crusor on a number:

    Ctrl+a   # increase the number by one
    <number>Ctrl+a   # increase the number by <number>
    Ctrl+x   # decrease the number by one
    <number>Ctrl+x   # decrease the number by <number>

### Indent lines

in command mode,

    >>              # increase indentation for current line
    <<              # decrease indentation for current line

in insert mode,

    Ctrl + t        # increase indentation
    Ctrl + d        # decrease indentation
    ^ Ctrl+d        # shift the cursor back to beginning of the line
    0 Ctrl+d        # shift the cursor back to beginning of the line, and reset auto indent level to zero

select lines you want to indent in visual mode, then use `>` to indent them  
indent a block: place cursor on one of the brackets, then `>%` to indent the block

### Abbreviations

**Turn off paste mode** for this abbreviations to work

    :ab <abbr> <phrase>     # when in insert mode, <abbr> inputted as a whole word will be expanded to <phrase> automatically
    :ab                     # list all abbreviations
    :unab <abbr>            # disable <abbr> abbreviation

    :ab DB Database         # input 'DB' to get 'Database'

### Word completion

use `Ctrl+X` followed by:

- `Ctrl+F` filename
- `Ctrl+L` whole line
- `Ctrl+N/P` word, search current file
- `Ctrl+K` dictionary, dictionary files is set by `set dictionary`
  such as `set dictionary=~/.mydict`, put any words you want in the file `~/.mydict`
- `Ctrl+T` thesaurus file is set by `set thesaurus`
  such as `set thesaurus=~/.mythesaurus`
- `Ctrl+I` word, search current file and included files

- `Ctrl+N` next
- `Ctrl+P` previous

dictionary file example:
china
zhongguo
lenovo

thesaurus file example, in insert mode, when you place the cursor after a word, then `Ctrl+X_Ctrl+T`, a list of synonyms from the thesaurus file would show up:

    fun enjoyable desirable
    funny hilarious lol lmao
    retrieve getchar getcwd getdirentries getenv

### Command macros

    :map <x> <sequence>         # define <x> as a macro for command <sequence>, <x> may be function keys, `#1` for F1
    :map                        # list all command macros
    :unmap <x>                  # disable <x>

    :map V dwelp               # map V as `dwelp`, which swaps words

    :map =i I<i>^[              # add '<i>' tag at line beginning
    :map =I A</i>^[             # add '</i>' tag at line ending

`map!`, `unmap!` for define and remove key mappings in insert mode

    :map! =b <b></b>^[F<i       # define `=b` as insert '<b></b>' in current editing position and place the input cursor in between(which can not be done by abbreviation)

keys may be used in user defined commands:

    Letters:        g, K, V
    Control keys:   ^A, ^K, ^O, ^W, and ^X
    Symbols:        _, *, \, and =

you can store command sequence in named buffers, and execute it using `@` functions, e.g.,

    1. input this at a new line 'cwhello world^[', (the last character is an escaped <Esc>) then <Esc> to exit insert mode;
    2. "gdd    # put this line in buffer g;
    3. place the cursor at beginning of a word, and `@g` will execute the macro in buffer g, and replace the word with 'hello world';

## Edit multiple files

### multiple buffers

    :e              # open another file

    :next           # switch to next file/buffer
    :prev[ious]     # switch to previous file/buffer
    :first          # switch to the first file
    :last           # switch to the last file

    :ls, :files, :buffers   # list all buffers

    :buffer <n>         # move to buffer <n>
    :sbuffer <n>         # opens a new window for buffer <n>

    :windo <cmd>        # executes <cmd> in each window
    :bufdo <cmd>        # executes <cmd> in each buffer

vi has two special filenames, `%` means current filename, `#` means alternative filename, these can be used for easy file switching between two files

    :e #            # switch to last file you were editting, you can also use Ctrl+^
    :w %.new        # save a copy of current file, with a '.new' appended to the current filename

### multiple windows

open multiple files in multiple windows, use the `-o` option

    $ vi -o file1 file2
    $ vi -o4 file1 file2    # open 4 windows at once, the last two will be empty
    $ vi -O file1 file2     # split windows vertically

in vim:

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
    ^w[<>]                 # decrease/increase windows width
    ^w|                 # make current window widest size possible
    :resize [-+]n      # decrease/increase windows height by <n> lines
    :resize n      # set windows height to n lines

### tab page

**different tabs are like multiple desktops, multiple windows can be opened in one tab**

open and close tab page

    $ vim -p file_1 file_2  # open each file in a tab page
    :tabe file_name         # open file in a new tab
    :tabc                   # close current tab

navigation

    gt / gT         # go to next / previous tab in normal mode
    :tabn           # switch to next tab
    :tabp           # switch to previous tab

    :tabs           # list all tabs
    :tabfirst       # switch to first tab
    :tablast        # switch to last tab

or try to use `Ctrl + Alt + PageUp/PageDown` to switch tab (may only available in some systems)

### tag with windows

    ^wg]    # create a new window, open the file containing tag under the cursor
    ^wf     # create a new window, open the file under the cursor
    ^wgf     # create a new tab, open the file under the cursor

## Record and Play

(in normal mode) press `qa` : record macro a  
do whatever operation you want to be recorded  
(in normal mode) press `q`, stop recording  
(in normal mode) press `@a`, replay macro a

## Copy and Paste

if you paste some text, and the indentation screwed up, use the following command before you actually paste anything

    :set paste

named buffers

    "a2yy    # copy two lines to buffer a
    "ap      # paste from buffer a

using ex command

    :7,13ya a   # yank line 7 through 13 to buffer a
    :pu a       # put buffer a after the current line

copy to and paste from system clipboard, in X11 system register '\*' means _PRIMARY_ SELECTION, register '\+' means _CLIPBOARD_
(ref: [Accessing_the_system_clipboard](http://vim.wikia.com/wiki/Accessing_the_system_clipboard))

    "+p     # paste
    "+yy    # copy current line
    :% y +  # copy all lines

## Registers

Registers are used for recording, copying:

- in normal mode:

  - `@x` replays register `x`;
  - `"xp` pastes content from register `x`;

- in insert or command mode:

  - `Ctrl+R` followd by `x` pastes content from register `x`;

- special registers:

  - `%`: relative path of current file, so `"%p` pastes the current file path;
  - `#`: relative path of the alternative file;
  - `_`: blackhole/null register;
  - `"`: unamed register, deleting, changing and yanking text copies the text to this register, `p` paste from this register;
  - `0`: yanking text copies it to this register and the unnamed register `"` as well;

- you can edit register contents in command line:

      	`:let @q = 'macro contents'`

- or show all registers by `:reg` or `:registers`

## Options

    :set all    # show all options
    :set        # show options you changed, including changes in your .vimrc file or in this session
    :set option?    # find out current value of the option

    :set list       # display tab and newline characters
    :5,20 l         # temporarily display tab and newline characters of line 5 through 20

## Miscs

    <C-g>   # show file info
    :=       # show line numbers of file
    :#       # show current line number
    :-10,$ #    # show the last 10 lines' number

    :set binary     # set vim in binary mode, vim by default writes the file with a final new-line appended, in binary mode this doesn’t happen

    :<C-F>  # edit command history

### Avoid the Esc key

    ctrl+[, ctrl+c      # escape from edit mode to normal mode, replace the '<Esc>' key

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

## Modes

### ex mode

    Q               # go to ex mode
    :vi             # go back to vi mode

    :sh             # create a shell withoud exiting vi, go back to vi using Ctrl+D
    :r !sort file       # read in file in sorted order
    :31,34!sort -n      # sort lines from 31 through 34 as numbers

    !<move><command>    # filtering text selected by <move> using <command>
    <num>!!<command>         # filtering <num> lines using <command>

### visual mode

```
viw         # go into visual mode, selecting current word
vis         # go into visual mode, selecting current sentence
vi"         # go into visual mode, selecting current everything inside "
vi(         # go into visual mode, selecting current everything inside (
```

select text objects in visual mode (find more, :help text-objects):

    <count>aw   # select <count> words(delimited by punctuations)
    <count>aW   # select <count> words(delimited by white space)
    as, is      # add sentence, or inner sentence
    ap, ip      # add paragraph, or inner paragraph

## plugins

`.vim` files in `.vim/plugin` folder are loaded automatically when vim starts

- ctrl-p

  use `Ctrl-p` to start searching files

  `Ctrl-r` to switch to regex mode

  `Ctrl-t`, `Ctrl-v`, `Ctrl-x` to open the file in new tab / vertical split / horizontal split

  `Ctrl-y` to create a new file and its parent directories

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

- vim-repeat

make `.` to work with plugin actions as well

### Vundle

Vundle is one of the best Vim plugin managers, go to https://github.com/VundleVim/Vundle.vim for details

to use it:

    * clone vundle to `~/.vim/bundle/Vundle.vim`

            git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

    * configure plugins in `.vimrc`

    * Launch vim and run `:PluginInstall`
