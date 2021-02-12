# Bash Cheatsheet

- [Resources](#resources)
- [Get help/documentation](#get-helpdocumentation)
- [Interactive use](#interactive-use)
  - [History](#history)
  - [VI Mode](#vi-mode)
    - [Command mode](#command-mode)
    - [Insert mode](#insert-mode)
- [Bash Invocation](#bash-invocation)
  - [Login vs. non-login](#login-vs-non-login)
  - [Interactive vs. non-interactive](#interactive-vs-non-interactive)
  - [Startup files](#startup-files)
  - [A prompt-unchangeable issue](#a-prompt-unchangeable-issue)
- [Variables](#variables)
  - [Parameter expansion](#parameter-expansion)
  - [String manipulation](#string-manipulation)
  - [Environment variables](#environment-variables)
  - [Special variables](#special-variables)
  - [Command line arguments](#command-line-arguments)
  - [Dynamic variables](#dynamic-variables)
- [Substitutions](#substitutions)
  - [Command substitution](#command-substitution)
  - [Process substitution](#process-substitution)
- [Expansions](#expansions)
  - [Globbing](#globbing)
  - [Brace expansion](#brace-expansion)
  - [Integer or character sequence](#integer-or-character-sequence)
- [`if` statement](#if-statement)
- [Conditional](#conditional)
- [`[` vs `[[`](#-vs-)
- [Arithmetic](#arithmetic)
- [Array](#array)
- [Dictionary](#dictionary)
- [Looping](#looping)
- [`case` statements](#case-statements)
- [Functions](#functions)
- [Variable scope](#variable-scope)
- [Input / output](#input--output)
  - [How to redirect output to a protected (root-only) file](#how-to-redirect-output-to-a-protected-root-only-file)
- [Here documents](#here-documents)
- [Builtins](#builtins)
  - [`source`, `.`](#source-)
  - [`read`](#read)
  - [`printf`](#printf)
  - [`set`](#set)
  - [`shift`](#shift)
- [Scripting best practices](#scripting-best-practices)
  - [Options](#options)
  - [`IFS`](#ifs)
  - [`trap`](#trap)
  - ['strict' mode](#strict-mode)
  - [Checking](#checking)
- [Quick recipes](#quick-recipes)
  - [Read lines of a file](#read-lines-of-a-file)
  - [Generate random numbers](#generate-random-numbers)
  - [Generate random strings](#generate-random-strings)
  - [Multiple commands on a single line](#multiple-commands-on-a-single-line)
  - [Basename and dirname](#basename-and-dirname)
  - [Get the directory of a script you're running](#get-the-directory-of-a-script-youre-running)
  - [Subshells](#subshells)
  - [Special characters on command line](#special-characters-on-command-line)
  - [Text file intersections](#text-file-intersections)
  - [Sum up a column of numbers](#sum-up-a-column-of-numbers)

## Resources

- [Bash by example][bash by example] on IBM DeveloperWorks by Daniel Robbins
- [The Art of Command Line][the-art-of-command-line]
- [15 Examples To Master Linux Command Line History][15-examples-to-master-linux-command-line-history]

## Get help/documentation

- `man`

    ```sh
    # search man pages
    man -k crontab
    # crontab (1)          - maintain crontab files for individual users (Vixie Cron)
    # crontab (5)          - tables for driving cron

    # limit search to section 1 (executables/commands)
    man -k crontab -s 1
    # crontab (1)          - maintain crontab files for individual users (Vixie Cron)

    # search using regex
    man -k 'cron.*' --regex

    man crontab

    # man page of crontab in section 5 (file format)
    man 5 crontab
    ```

- `type`

    Some commands are not executables, but Bash builtins, you can check this with `type`

    ```sh
    type echo
    # echo is a shell builtin

    type python
    # python is /home/gary/miniconda3/bin/python
    ```

- `help`

    Show info about builtin commands, just `help` list all builtins;

- misc

    ```sh
    whatis node
    # node (1)             - Server-side JavaScript runtime

    which node
    # /home/gary/.nvm/versions/node/v12.14.0/bin/node

    whereis node
    # node: /usr/local/bin/node /home/gary/.nvm/versions/node/v12.14.0/bin/node
    ```

## Interactive use

The interactive line editing is handled by the readline library, it's in Emacs mode by default, can be changed to Vi mode, see **`man readline`** for all editing shortcuts.

### History

- Search history: `Ctrl-R`, then type in keyword

  - `Ctrl-R` again to loop thru results;
  - Right arrow to select current result;

- Repeat previous command

    - the Up key
    - `Ctrl-P`
    - `!!`
    - `!-1`

- Execute a specific command

    ```sh
    # find the number of the command
    $ history | grep echo
        1437  echo $VISUAL
        1438  echo $EDITOR
        1439  echo $GIT_EDITOR
        2013  echo 'hello world'
        2014  echo 'hi'
        2016  echo 'hi'
        2020  history | grep echo

    # execute the specific command
    $ !2013
    echo 'hello world'
    hello world
    ```

### VI Mode

Run `set -o vi` to change to VI mode

#### Command mode

- `-`, `k` previous history
- `+`, `j` next history
- `C-K` kill line
- `/`, `?` search history
- `n`, `N` next/previous search result
- `#`  comment out current command and keep it in the history

#### Insert mode

- `C-W` delete word backward
- `C-U` delete to the start of the line
- `C-[` switch to command mode


## Bash Invocation

### Login vs. non-login

Typically, you are using a non-login shell, unless

- logged in from a tty, not thru a GUI;
- logged in remotely, such as thru ssh;


A login shell is one whose first character of first argument is a `-`, or one started with the `--login` option, you can test whether your current shell is a login shell or not:

```sh
prompt> echo $0
-bash               # "-" is the first character. Therefore, this is a login shell.

prompt> echo $0
bash                # a non-login shell.
```

### Interactive vs. non-interactive

An interactive shell is:
- Started without non-option arguments and without the `-c` option whose standard input and error are both connected to terminals (as determined by `isatty(3)`);
- Or one started with the `-i` option;
- `PS1` is set, and `$-` includes `i` if bash is interactive, allowing a shell script or a startup file to test this state;

### Startup files

Ref: [Zsh/Bash startup files loading order (.bashrc, .zshrc etc.)](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/)

```
+----------------+-----------+-----------+------+
|                |Interactive|Interactive|Script|
|                |login      |non-login  |      |
+----------------+-----------+-----------+------+
|/etc/profile    |   A       |           |      |
+----------------+-----------+-----------+------+
|/etc/bash.bashrc|           |    A      |      |
+----------------+-----------+-----------+------+
|~/.bashrc       |           |    B      |      |
+----------------+-----------+-----------+------+
|~/.bash_profile |   B1      |           |      |
+----------------+-----------+-----------+------+
|~/.bash_login   |   B2      |           |      |
+----------------+-----------+-----------+------+
|~/.profile      |   B3      |           |      |
+----------------+-----------+-----------+------+
|BASH_ENV        |           |           |  A   |
+----------------+-----------+-----------+------+
|                |           |           |      |
+----------------+-----------+-----------+------+
|                |           |           |      |
+----------------+-----------+-----------+------+
|~/.bash_logout  |    C      |           |      |
+----------------+-----------+-----------+------+
```

Login shell (both interactive or not):

1. read `/etc/profile` (if exists);
2. read first readable: `~/.bash_profile`, `~/.bash_login`, `~/.profile`;
3. ...
4. when exits, exec `~/.bash_loggout` (if exists)

Interactive non-login shell:

1. read both `/etc/bash.bashrc`, `~/.bashrc` (if exist)

General rule: **For Bash, put stuff in `~/.bashrc`, and make `~/.bash_profile` source it**

### A prompt-unchangeable issue

    2016-02-09: a `PS1` prompt problem: it cannot be changed, `PS1` settings in ~/.bashrc got no effect, set `PS1` in command line cannot change it, but it got git branchs in it
    finally found the reason: `/etc/bash_completion.d/git-prompt`, which sourced `/usr/lib/git-core/git-sh-prompt`

## Variables

set, use, unset a variable

```sh
$ foo='i am a var'
$ echo "hello ${foo} world"
hello i am a var world

$ unset foo
$ echo "hello ${foo} world"
hello world
```

### Parameter expansion

|   Expression in script:       |  FOO="world" (Set and Not Null)  |  FOO="" (Set But Null) |     (Unset)     |
|--------------------|----------------------|-----------------|-----------------|
| ${FOO:-hello}      | world                | hello           | hello           |
| ${FOO-hello}       | world                | ""              | hello           |
| ${FOO:=hello}      | world                | FOO=hello       | FOO=hello       |
| ${FOO=hello}       | world                | ""              | FOO=hello       |
| ${FOO:?hello}      | world                | error, exit     | error, exit     |
| ${FOO?hello}       | world                | ""              | error, exit     |
| ${FOO:+hello}      | hello                | ""              | ""              |
| ${FOO+hello}       | hello                | hello           | ""              |

**Null and empty string are equivalent in Bash**

Check whether a variable is set:

```sh
# check whether a var is set and not empty
# we have the '-u' flag, so simple '[ -n "$1" ]' would throw an error
set -eu

if [ -n "${1:+x}" ]; then
  echo 'set'
fi
```

See details here: https://stackoverflow.com/a/3870055

**CAUTION: In single brackets, always quote a variable**

```sh
# Wrong
[ -n $NOT_DEFINED ] && echo 'yes' || echo 'no'
# yes

# the above is equivalent to, the test returns true
[ -n ] && echo 'yes' || echo 'no'
# yes

# Correct: you NEED to quote the variable in single brackets
[ -n "$NOT_DEFINED" ] && echo 'yes' || echo 'no'
# no

# OR, use double brackets, then no need to worry about quoting
[[ -n $NOT_DEFINED ]] && echo 'yes' || echo 'no'
# no
```


### String manipulation

- String length

    ```sh
    a='hello world'
    echo ${#a}
    # 11
    ```

- Chopping strings, `##`,`#` to chop from beginning, `%%`,`%` to chop from the end, `##`, `%%` for longest matching, `#`, `%` for first matching

    ```sh
    foo='hello-hello.world.jpg'

    echo ${foo##*hello}
    # .world.jpg

    echo ${foo#*hello}
    # -hello.world.jpg

    echo ${foo%%.*}
    # hello-hello

    echo ${foo%.*}
    # hello-hello.world
    ```

- Substring

    ```sh
    foo='hello-world.jpg'
    echo ${foo:6:5}
    # world
    ```

- Uppercase / Lowercase

    Since Bash 4

    ```sh
    a='test'
    echo "${a^}"
    # Test

    echo "${a^^}"
    # TEST

    b='TEST'
    echo "${b,}"
    # tEST

    echo "${b,,}"
    # test
    ```

### Environment variables

Part of the UNIX process model. This means that environment variables are not exclusive to shell scripts, but can be used by compiled programs as well. When we `export` an environment variable under bash, any subsequent programs we run can read it, whether it is a shell script or not.

export a variable

```sh
foo='i am a var'
export foo
```

or use a one-liner: `export foo='i am a var'`

**exported variables are copied, not shared**, which means any modification in the subroutine will not affect the variable in the parent routine

```sh
date
# Sat Apr 11 10:09:59 NZST 2020

# set environment variable for a command
TZ=Asia/Shanghai date
# Sat Apr 11 06:10:21 CST 2020
```

### Special variables

- `$$` current process id;
- `$?` exit code of last command;

### Command line arguments

```sh
#!/bin/bash

echo "name of script is '$0'"
echo "first argument is '$1'"
echo "second argument is '$2'"
echo "seventeenth argument is '${17}'"
echo "number of arguments is '$#'"
echo "all arguments: "
for arg in "$@"
do
    echo $arg
done
```

test it out:

```sh
$ ./cmd-args.sh hello world is-fun
name of script is './cmd-args.sh'
first argument is 'hello'
second argument is 'world'
seventeenth argument is ''
number of arguments is '3'
all arguments:
hello
world
is-fun
```

### Dynamic variables

Since Bash 4.3, you can use `declare` builtin to create dynamic variables

```sh
i=20
var_20=gary

# ref is like a pointer in C
declare -n ref="var_$i"
echo "$ref"
# gary

echo "${!ref}"  # which variable ref is pointing to
# var_20

ref=amy
echo "$ref"
# amy

echo "$var_20"
# amy
```

## Substitutions

### Command substitution

Use back ticks or `$(...)` to get the output of a command

```sh
$ echo `date '+%Y/%m/%d %H:%M:%S'`
2013/01/10 10:43:56

$ echo $(date '+%Y/%m/%d %H:%M:%S')
2013/01/10 10:44:05
```

### Process substitution

When a command expects filenames as arguments, `<(CMD)` can help get output of `CMD` in a temporary file

Example: using diff to compare file list in two directories

```sh
ls test1 test2
# test1:
# a  b  c

# test2:
# c  d  e

diff <(ls test1) <(ls test2)
# 1,2d0
# < a
# < b
# 3a2,3
# > d
# > e
```

## Expansions

### Globbing

```sh
ls test?        # single character
# test1 test2

ls "test?"      # double quote disables globbing
# ls: cannot access 'test?': No such file or directory
```

### Brace expansion

```sh
ls gary.{txt,jpg}
# gary.txt gary.jpg

mkdir -p test-{1..3}/sub-{a..b}     # create all combinations
```



### Integer or character sequence

```sh
echo {1..5}                 # number sequence
# 1 2 3 4 5

echo {a..h}                 # character sequence
# a b c d e f g h

echo {10..1}                # reversed sequence
# 10 9 8 7 6 5 4 3 2 1

echo {1..10..3}             # sequence with increment interval
# 1 4 7 10

echo {0..1}{0..9}           # combinations
# 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19
```

brace expansion is performed before any other expansion, so `{1..$END}` would not work as expected, use `seq start end` or `for` loop instead:

```sh
END=3
for i in {1..$END}; do echo $i; done
# {1..3}

for i in `seq 1 $END`; do echo $i; done
# 1
# 2
# 3

for ((i=0; i<=$END; i++)) do echo $i; done
# 0
# 1
# 2
# 3
```


## `if` statement

    if [ condition ]
    then
        action
    elif [ condition2 ]
    then
        action2
    .
    .
    .
    elif [ condition3 ]
    then
        action3
    else
        actionx
    fi

example

    if [ "${1##*.}" = "tar" ]
    then
        echo 'This appears to be a tarball.'
    else
        echo 'At first glance, this does not appear to be a tarball.'
    fi

## Conditional

bash comparison operators:

    Operator    Meaning                             Example
    -s          File exists and not empty           [ -s "$myvar" ]
    -z          Zero-length string                  [ -z "$myvar" ]
    -n          Non-zero-length string              [ -n "$myvar" ]
    =           String equality                     [ "abc" = "$myvar" ]
    ==          Bash extension, same as '='
    !=          String inequality                   [ "abc" != "$myvar" ]
    -eq         Numeric equality                    [ 3 -eq "$myinteger" ]
    -ne         Numeric inequality                  [ 3 -ne "$myinteger" ]
    -lt         Numeric strict less than            [ 3 -lt "$myinteger" ]
    -le         Numeric less than or equals         [ 3 -le "$myinteger" ]
    -gt         Numeric strict greater than         [ 3 -gt "$myinteger" ]
    -ge         Numeric greater than or equals      [ 3 -ge "$myinteger" ]
    -f          Exists and is regular file          [ -f "$myfile" ]
    -d          Exists and is directory             [ -d "$myfile" ]
    -nt         First file is newer than second one [ "$myfile" -nt ~/.bashrc ]
    -ot         First file is older than second one [ "$myfile" -ot ~/.bashrc ]
    =~          Regular expression match            [[ 'Files a and b differ' =~ differ$ ]]

example:

    if [ "$myvar" -eq 3 ]
    then
        echo "myvar equals 3"
    fi

    if [ "$myvar" = "3" ]
    then
        echo "myvar equals 3"
    fi

**If `$myvar` is an integer, these two comparisons do exactly the same thing**, but the first uses arithmetic comparison operators, while the second uses string comparison operators. If `$myvar` is not an integer, then the first comparison will fail with an error.

if `$myvar` is empty or have space in it, like 'foo bar', it will result in error:

    $ myvar="foo bar oni"
    $ if [ $myvar = "foo bar oni" ]
    > then
    >     echo "yes"
    > fi
    bash: [: too many arguments

    $ unset myvar
    $ echo $myvar

    $ if [ $myvar = "foo bar oni" ]
    > then
    >     echo "yes"
    > fi
    bash: [: =: unary operator expected

so, **Always enclose string variables and environment variable in double quotes!**, like this:

    if [ "$myvar" = "foo bar oni" ]
    then
        echo "yes"
    fi

## `[` vs `[[`

- `[` is a shell builtin command, similar to `test`, but requires a closing `]`, builtin commands executes in the current process;

- There is an executable file at: `/bin/[`, which executes in a subshell;

  ```bash
  type -a [
  # [ is a shell builtin
  # [ is /usr/bin/[

  type '[['
  # [[ is a shell keyword
  ```

- `[[` is a Bash extension to `[`, it has some improvements:

  - `<`

    - `[[ a < b ]]` # works
    - `[ a \< b]` # `\` is required, do a redirection otherwise

  - `&&` and `||`

    - `[[ a = a && b = b ]]` # works
    - `[ a = a && b = b ]` # syntax error
    - `[ a = a ] && [ b = b ]` # POSIX recommendation

  - `(`

    - `[[ (a = a || a = b) && a = b ]]` # false
    - `[ ( a = a ) ]` # syntax error, `()` is interpreted as a subshell
    - `[ \( a = a -o a = b \) -a a = b ]` # equivalent, but `()` is deprecated by POSIX
    - `([ a = a ] || [ a = b ]) && [ a = b ]` # POSIX recommendation

  - word splitting

    - `x='a b'; [[ $x = 'a b' ]]` # true, quotes not needed
    - `x='a b'; [ $x = 'a b' ]` # syntax error, expands to `[ a b = 'a b' ]`
    - `x='a b'; [ "$x" = 'a b' ]` # equivalent

  - `=`

    - `[[ ab = a? ]]` # true, because it does pattern matching ( `* ? [` are magic). Does not glob expand to files in current directory. (**pattern matching, not regular expression**)
    - `[ ab = a? ]` # `a?` glob expands to files in current directory. So may be true or false depending on the files in the current directory.
    - `[ ab = a\? ]` # false, not glob expansion
    - `=` and `==` are the same in both `[` and `[[,` but `==` is a Bash extension.

  - `=~`

    - `[[ ab =~ ab? ]]` # true, POSIX extended regular expression match, `?` does not glob expand
    - `[ a =~ a ]` # syntax error
    - `printf 'ab' | grep -Eq 'ab?'` # POSIX equivalent

## Arithmetic

enclose arithmetic expressions(**integer only**) in `$((` and `))`

    $ echo $(( 100/3 ))
    33
    $ echo $((1+2))
    3
    $ a=10
    $ echo $(( a+2 ))
    12
    $ echo $(( $a+2 ))
    12
    $ echo $(( 1.3 + 4 ))
    bash: 1.3 + 4 : syntax error: invalid arithmetic operator (error token is ".3 + 4 ")

## Array

- Available in Bash, Zsh, not the original Bourne shell;

```bash
arr=(apple banana cherry)

echo ${arr[@]}                      # all elements
# apple banana cherry

echo ${arr[*]}                      # same as above, get all elements
# apple banana cherry

echo ${#arr[@]}                     # length
# 3

echo ${arr[1]}                     # first element, index starts at 1
# apple

echo ${arr[@]:1}                    # leave the first
# banana cherry

echo ${arr[@]: -1}                  # get the last, the space is needed
# cherry

echo ${arr[@]:0:2}                  # start from the first, get two
# apple banana
```

## Dictionary

Bash 4+

```sh
declare -A animals=( ["cow"]="moo" ["dog"]="woof")

echo "${!animals[@]}" # all keys
# dog cow

echo "${animals[@]}" # all values
# woof moo

echo "${animals[cow]}" # retrive a value
# moo

for animal in "${!animals[@]}"; do
  echo "$animal - ${animals[$animal]}";
done
# dog - woof
# cow - moo
```

## Looping

Standard `for` loop:

    $ for x in one two three four
    > do
    >     echo number $x
    > done
    number one
    number two
    number three
    number four

use file wildcards, variables in word list:

    $ FOO='hello'
    $ for i in lee_* $FOO
    > do
    >    echo $i
    > done
    lee_1
    lee_2
    lee_3
    hello

`while` loop:

    $ i=0
    $ while [ $i -le 3 ]
    > do
    >     echo $i
    >     i=$(( i+1 ))
    > done
    0
    1
    2
    3

`until` loop:

    $ i=0
    $ until [ $i -eq 2 ]
    > do
    >     echo $i
    >     i=$(( i + 1 ))
    > done
    0
    1

## `case` statements

`case` syntax:

    case ${filename##*.} in
        [tT][xX][tT])               # matches txt, TXT, Txt, tXt, ...
            echo 'a text file'
            ;;
        jpg | png)
            echo 'an image file'
            ;;
        *)
            echo 'unknown file'
            ;;
    esac

`*` means `default`, `;;` means `break`

## Functions

functions can take arguments just like scripts, use `$1`, `$2`, `$#`, `$@`, etc to access them:

write a script `func_args.sh`:

    #!/bin/bash

    func() {
        echo "this function has $# arguments"
        local i
        local count=1
        for i in $@
        do
            echo "arg ${count}: $i"
            count=$(( count + 1 ))
        done

        echo '.. and $0: ' $0
    }

return to bash:

    $ source func_args.sh
    $ func a happy dog
    this function has 3 arguments
    arg 1: a
    arg 2: happy
    arg 3: dog
    .. and $0:  /bin/bash

**but, `$0` in function, will either expand to the bash filename (if you run the function from the shell, interactively) or to the name of the script the function is called from**

return values from a function:

    larger() {
        if [ $1 -gt $2 ]; then
            return 0        # should be zero
        else
            return 1
        fi
    }

    if larger 2 1; then
        echo 'hooray'
    fi

**You can make functions return numeric values using the return command. The usual way to make functions return strings is for the function to store the string in a variable, which can then be used after the function finishes. Alternatively, you can echo a string and catch the result, like this: `RETURN_VAL=$(func var1 var2)`**

**you can get its exit status using `$?`**

## Variable scope

    #!/bin/bash

    s='hello from global scope'

    func() {
        s='hello from func'
        echo $s
    }

    func2() {
        local s='hello from func2'
        echo $s
    }


    echo 'before func():' $s
    func
    echo 'after func() :' $s
    func2
    echo 'after func2():' $s

run the script, you'll get:

    before func(): hello from global scope
    hello from func
    after func() : hello from func
    hello from func2
    after func2(): hello from func

**variables defined in functions have global scope, except you declare them as `local` explicitly**

## Input / output

By default stdout and stderr both go to the current terminal, they can be redirected:

```sh
ls > out 2> err

# append to files
ls >> out 2>> err

# redirect stderr to the stdout file 'out'
ls >> out 2>&1

# alternative syntax
ls &>> out
```

### How to redirect output to a protected (root-only) file

If `out` is a protected file, `sudo ls /root > out` won't work, because `sudo` only applies to `ls`, the redirection is done by `zsh`, which is not run by super user, so you need to pipe stdout to `sudo tee`:

```sh
ls -l out
# -rw-rw-r-- 1 root root 0 May 23 21:00 out

sudo ls /root > out
# zsh: permission denied: out

sudo ls /root | sudo tee out
```


## Here documents

Used in place of standard input

```sh
name='Gary'

# write something to a file, varialbes expanded
cat > result.txt <<EOT
hello ${name}
EOT

cat result.txt
# hello Gary

# quote EOT to disable variable expansion
cat > result2.txt <<'EOT'
hello ${name}
EOT

cat result2.txt
# hello ${name}
```

use here documents to edit an file:

    $ cat inc
    foo

    $ ed inc <<EOT
    > 1
    > s/foo/BAR/
    > w
    > q
    > EOT
    5
    foo
    5

    $ cat inc
    BAR

## Builtins

### `source`, `.`

```sh
source ./script
# or
# . ./script
```

the `source` command runs the script in the same shell as the calling script, just like `#include` in C, it can be used to incorporate variable and function definitions to a script, such as set up environment for later commands.

### `read`

```sh
$ echo 'your name?'; read name
your name?
lee

$ echo $name
lee
```

### `printf`

X/Open suggests it should be used in preference to `echo` for generating fomatted output, usage is similar to that in C

```sh
$ printf '%10s\t%-10d\n' 'lee' 20
        lee  20
```

### `set`

used to set shell options and positional parameters

```sh
$ set foo bar lol
$ echo $1 $3
foo lol
```

a trick: using `set` to get fields of a command's ouput

```sh
$ date
Tue Sep  9 09:48:17 CST 2014
$ set $(date)
$ echo $1 $2
Tue Sep
```

*this is just an example, you should not actually use this to extract `date` ouput, you should use format strings*

### `shift`

shift paramters off the left, can be used to scan parameters

```sh
$ set foo bar hah   # set paramters
$ echo $@
foo bar hah

$ shift

$ echo $@
bar hah
$ echo $#
2
```

## Scripting best practices

### Options

- `set -n`

    same as: `set -o noexec`, checks for syntax errors only, doesn’t execute commands;

- `set -v`

    same as: `set -o verbose`, echoes commands before running them;

- `set -x`

    same as: `set -o xtrace`, print commands and their arguments as they are executed (after variable expansions);

- `set -u`

    same as: `set -o nounset`, exit when an undefined variable is used, otherwise it's silently ignored;

    - use a default value when necessary: `NAME=${1:-gary}`, if `$1` is undefined or empty, `NAME` will be `gary`;

- `set -e`

    abort on errors (non-zero exit code), otherwise the script would continue. By default, bash doesn't exit on errors, which makes sense in an interactive shell context, but not in a script;

    - NOTE: when using `&&`, if a non-last command fails, although the exit code of the whole line is not 0, the script doesn't exit, this may or may not be expected:

        ```sh
        set -eu

        foo && echo 'after foo' # foo fails but the script doesn't exit
        echo $? # output 127

        echo 'end' # runs
        ```

        The `&&` and `if` structure may seem the same, but their exit codes are different:

        ```sh
        [ -f /x ] && echo 'done'
        echo $?
        # 1

        if [ -f /x ]; then
            echo 'done';
        fi
        echo $?
        # 0
        ```

- `set -o pipefail`

    abort on errors within pipes

    ```sh
    ls /point/to/nowhere | sort
    # ls: cannot access '/point/to/nowhere': No such file or directory

    echo $?
    # 0
    ```

    without the flag, `ls` has empty stdout and a message in stderr, sort takes the empty stdout, and executes successfully, its exit code 0 becomes the whole command exit code;

    ```sh
    set -o pipefail
    ls /point/to/nowhere | sort
    # ls: cannot access '/point/to/nowhere': No such file or directory

    echo $?
    # 2
    ```

    with the flag, `sort` still executes, but `ls`'s exit code becomes the whole command's exit code, with `set -e`, the script exits;

### `IFS`

`IFS` stands for Internal Field Seperator, by default, its values is `$' \n\t'` (`$'...'` is the construct that allows escaped characters);

```sh
for arg in $@; do
    echo "doing something with file: $arg"
done
```

```sh
./x.sh a.txt 'gary li.doc'

# doing something with file: a.txt
# doing something with file: gary
# doing something with file: li.doc
```

In the example above, we don't want to split by space, so we'd better set **`IFS=$'\n\t'`**

### `trap`

You can use `trap` to do some cleanup work on script error or exit, this makes sure the cleanup is always done even when the script exits unexpectedly:

```sh
#!/bin/bash
set -euo pipefail
set -x

function onExit {
    echo 'EXIT: clean up, remove temp directories, stop a service, etc'
}

function onError {
    echo 'ERROR: something is wrong'
}

trap onError ERR    # do something on error
trap onExit EXIT    # do something on exit

foo # triggers an error

exit 0
```

outputs

```
x.sh: line 15: foo: command not found
ERROR: something is wrong
EXIT: clean up, remove temp directories, stop a service, etc
```

### 'strict' mode

It's a good practice to start a script like this(called [unofficial bash strict mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/)), which will detect undefined variables, abort on errors and print a message:

```sh
set -euo pipefail
IFS=$'\n\t'
trap "echo 'error: Script failed: see failed command above'" ERR

# your code here
```

### Checking

Install a tool `shellcheck` to check your script:

```sh
sudo apt install shellcheck

shellcheck script.sh
```

## Quick recipes

### Read lines of a file

```sh
while read -r line; do echo $line; done < my_file.txt
```

### Generate random numbers

```sh
echo $RANDOM
# 12521
echo $RANDOM
# 15828

```

### Generate random strings

```sh
# 5 character string (5 bytes, 10 hex chars)
openssl rand -hex 5
# cf2a039a47
```

### Multiple commands on a single line

All three commands will execute even some fails

```sh
$ make ; make install ; make clean
```

Only proceed to the next command when the preceding one succeeded

```sh
$ make && make install && make clean
```

Stop execution after first success

```sh
$ cat file1 || cat file2 || cat file3
```

### Basename and dirname

```sh
basename /home/lee/code/test.php
# test.php

dirname /home/lee/code/test.php
# /home/lee/code
```

### Get the directory of a script you're running

ref: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in

```sh
DIR=$( cd "$( dirname "$0" )" && pwd )
```

### Subshells

Use subshells (enclosed with parenthesis) to group commands, which allows you to another directory temporarily

```sh
# do something in current dir

(cd /some/other/dir && other-command)

# continue in original dir
```

### Special characters on command line

Use `$''` to input special characters on command line

```sh
echo hello$'\n\t'world
# hello
# 	world
```

### Text file intersections

If you have two files 'a' and 'b', they are already uniqed, you can use `sort/uniq` to find common/different words in them like this:

```sh
sort a b | uniq           # a union b
sort a b | uniq -d        # a intersect b
sort a b b | uniq -u      # set difference a - b
```

### Sum up a column of numbers

```sh
awk '{ sum += $2 } END { print sum }' numbers.txt
```







<a name="end"></a>

[bash by example]: http://www.ibm.com/developerworks/linux/library/l-bash/index.html
[15-examples-to-master-linux-command-line-history]: http://www.thegeekstuff.com/2008/08/15-examples-to-master-linux-command-line-history/
[the-art-of-command-line]: (https://github.com/jlevy/the-art-of-command-line)
