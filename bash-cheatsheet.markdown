Bash Cheatsheet
===============

- [Preface](#preface)
- [Variables](#variables)
- [Command substitution](#command-substitution)
- [brace expansion](#brace-expansion)
- [Strings](#strings)
- [`if` statement](#if-statement)
- [Command line arguments](#command-line-arguments)
- [Conditional](#conditional)
- [`[` vs `[[`](#vs)
- [Arithmetic](#arithmetic)
- [Array](#array)
- [Looping](#looping)
- [`case` statements](#case-statements)
- [Functions](#functions)
- [Variable scope](#variable-scope)
- [the source (.) command](#the-source--command)
- [integer or character sequence](#integer-or-character-sequence)
- [get directory of a script you're running](#get-directory-of-a-script-youre-running)
- [History](#history)
    - [Search history using Ctrl+R](#search-history-using-ctrlr)
    - [Repeat previous command](#repeat-previous-command)
    - [Execute a specific command](#execute-a-specific-command)
- [Bash Invocation](#bash-invocation)
    - [an prompt cannot be changed issue](#an-prompt-cannot-be-changed-issue)
- [Multiple commands on a single line](#multiple-commands-on-a-single-line)
- [Here documents](#here-documents)
- [read user input](#read-user-input)
- [expr](#expr)
- [printf](#printf)
- [set](#set)
- [shift](#shift)
- [Generate random numbers](#generate-random-numbers)
- [Debugging scripts](#debugging-scripts)
- [read lines of a file](#read-lines-of-a-file)
- [vi editing mode](#vi-editing-mode)


## Preface
This is a bash cheatsheat for quick reference. Code get from [Bash by example][bash by example] on IBM DeveloperWorks by Daniel Robbins.

## Variables
set, use, unset a variable

    $ foo='i am a var'
    $ echo "hello${foo}world"
    helloi am a varworld
    $ unset foo
    $ echo "hello${foo}world"
    helloworld

Environment variables is that they are a standard part of the UNIX process model. This means that environment variables not only are exclusive to shell scripts, but can be used by standard compiled programs as well. When we "export" an environment variable under bash, any subsequent program that we run can read our setting, whether it is a shell script or not.

export a variable

    foo='i am a var'
    export foo

or use one line:
    
    export foo='i am a var'

**exported variables are copied, not shared, which means any modification in the subroutine will not affect the variable in the parent routine**

'$$' for current shell process id

    $ echo $$
    24465

## Command substitution
two syntax:

    $ echo `date '+%Y/%m/%d %H:%M:%S'`
    2013/01/10 10:43:56
    $ echo $(date '+%Y/%m/%d %H:%M:%S')
    2013/01/10 10:44:05

## brace expansion

    $ touch {dog,cat}s
    $ ls
    cats  dogs

    $ touch {1..3}
    $ ls
    1  2  3  cats  dogs

## Strings
basename and dirname

    $ basename /home/lee/code/test.php
    test.php
    $ dirname /home/lee/code/test.php
    /home/lee/code

string length
    
    $ a='hello world'
    $ echo ${#a}
    11

string sorting

    if [ "$a" > "$b" ]
    if [ "$a" == "$b" ]

chopping strings, '##','#' to chop from beginning, '%%','%' to chop from the end, '##', '%%' for longest matching, '#', '%' for first matching

    $ foo='hello-hello.world.jpg'
    $ echo ${foo##*hello}
    .world.jpg
    $ echo ${foo#*hello}
    -hello.world.jpg
    $ echo ${foo%%.*}
    hello-hello
    $ echo ${foo%.*}
    hello-hello.world
    
substring
    
    $ foo='hello-world.jpg'
    $ echo ${foo:6:5}
    world

default values for a variable `${param:-default}`, ouput default if param is null

    $ echo $foo

    $ echo ${foo:-FOO}
    FOO
    $ echo $foo

${foo:=FOO} set foo as 'FOO' if foo is null
${foo:+BAR} returns 'BAR' if foo is NOT null

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
    
## Command line arguments
create a file named `cmd-args.sh`:

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

test it out:
    
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

* `[` is a shell builtin command, similar to `test`, but requires a closing `]`, builtin commands executes in the current process;
* There is a `/bin/[`, which executes in a subshell;

    ```bash
    type [
    # [ is a shell builtin

    type -p [
    # [ is /bin/[

    type '[['
    # [[ is a reserved word
    ```

* `[[` is a Bash extension to `[`, it has some improvements:

    * `<`

        * `[[ a < b ]]`     # works
        * `[ a \< b]`       # `\` is required, do a redirection otherwise

    * `&&` and `||`

        * `[[ a = a && b = b ]]`      # works
        * `[ a = a && b = b ]`        # syntax error
        * `[ a = a ] && [ b = b ]`        # POSIX recommendation

    * `(`

        * `[[ (a = a || a = b) && a = b ]]`     # false
        * `[ ( a = a ) ]`                       # syntax error, `()` is interpreted as a subshell
        * `[ \( a = a -o a = b \) -a a = b ]`   # equivalent, but `()` is deprecated by POSIX
        * `([ a = a ] || [ a = b ]) && [ a = b ]`   # POSIX recommendation

    * word splitting

        * `x='a b'; [[ $x = 'a b' ]]`   # true, quotes not needed
        * `x='a b'; [ $x = 'a b' ]`     # syntax error, expands to `[ a b = 'a b' ]`
        * `x='a b'; [ "$x" = 'a b' ]`   # equivalent

    * `=` 

        * `[[ ab = a? ]]`   # true, because it does pattern matching ( `* ? [` are magic). Does not glob expand to files in current directory. (**pattern matching, not regular expression**)
        * `[ ab = a? ]`     # `a?` glob expands to files in current directory. So may be true or false depending on the files in the current directory.
        * `[ ab = a\? ]`    # false, not glob expansion
        * `=` and `==` are the same in both `[` and `[[,` but `==` is a Bash extension.

    * `=~`

        * `[[ ab =~ ab? ]]`         # true, POSIX extended regular expression match, `?` does not glob expand
        * `[ a =~ a ]`              # syntax error
        * `printf 'ab' | grep -Eq 'ab?'`    # POSIX equivalent


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

* Available in Bash, Zsh, not the original Bourne shell;

```bash
arr=(apple banana cherry)

echo ${arr[@]}                      # all elements
# apple banana cherry

echo ${arr[*]}                      # same as above, get all elements
# apple banana cherry

echo ${#arr[@]}                     # length
# 3

echo ${#arr[1]}                     # first element, index starts at 1
# apple 

echo ${arr[@]:1}                    # leave the first
# banana cherry

echo ${arr[@]: -1}                  # get the last, the space is needed
# cherry

echo ${arr[@]:0:2}                  # start from the first, get two
# apple banana
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


## the source (.) command

    . ./script

the source command runs the script in the same shell as the calling script, just like `#include` in C, it can be used to incorporate variable and function definitions to a script, such as set up environment for later commands


## integer or character sequence

    $ echo {1..5} #number sequence
    1 2 3 4 5
    $ echo {a..h} #character sequence
    a b c d e f g h
    $ echo {10..1} #reversed sequence
    10 9 8 7 6 5 4 3 2 1
    $ echo {1..10..3} #sequence with increment interval
    1 4 7 10
    $ echo {0..9}{0..9} #echo 00 to 99
    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99

brace expansion is performed before any other expansion, so `{1..$VAR}` would not work as expected, use `seq start end` or `for` loop instead:

    $ END=5
    $ for i in {1..$END}; do echo $i; done 
    {1..5}

    $ for i in `seq 1 $END`; do echo $i; done
    1
    2
    3
    4
    5

    $ for ((i=0;i<=$END;i++)) do echo $i; done
    0
    1
    2
    3
    4
    5

## get directory of a script you're running

ref: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in

    DIR=$( cd "$( dirname "$0" )" && pwd )
    
## History

ref: [15 Examples To Master Linux Command Line History][15-examples-to-master-linux-command-line-history]

### Search history using Ctrl+R

    # press Ctrl+R, enter the keyword you want to search
    (reverse-i-search)`yes': date -d 'yesterday'

    # press Tab (or Left/Right) to edit the command, then Enter to execute
    $ date -d 'yesterday'
    Sat Jun  1 10:15:23 CST 2013

### Repeat previous command
    
* the Up key
* Ctrl+P
* `!!`
* `!-1`

### Execute a specific command

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


## Bash Invocation

login shell (both interactive or not):

    1. read /etc/profile  (if exists)
    2. read first readable: ~/.bash_profile, ~/.bash_login, ~/.profile
    3. ...
    4. when exits, exec ~/.bash_loggout (if exists)

interactive non-login shell:

    1. read both /etc/bash.bashrc, ~/.bashrc (if exist)

ref: [Zsh/Bash startup files loading order (.bashrc, .zshrc etc.)](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/)

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

General rule:

* For bash, put stuff in `~/.bashrc`, and make `~/.bash_profile` source it. 

Typically, most users will only encounter a login shell ony if 

* they logged in from a tty, not thru a GUI;
* they logged in remotely, such as thru ssh;

test whether current shell is a login shell or not:

    prompt> echo $0
    -bash # "-" is the first character. Therefore, this is a login shell.

    prompt> echo $0
    bash # "-" is NOT the first character. This is NOT a login shell.

A login shell is one whose first character of argument zero is a `-`, or one started with the `--login` option.

An interactive shell is one started without non-option arguments and without the `-c` option whose standard input and error are both connected to terminals (as determined by `isatty(3)`), or one started with the `-i` option. `PS1` is set and `$-` includes `i` if bash is interactive, allowing a shell script or a startup file to test this state.

on Ubuntu 14.04, the `Terminal` program starts as login shell, `Terminator` starts as non-login shell



### an prompt cannot be changed issue

    2016-02-09: a `PS1` prompt problem: it cannot be changed, `PS1` settings in ~/.bashrc got no effect, set `PS1` in command line cannot change it, but it got git branchs in it  
    finally found the reason: `/etc/bash_completion.d/git-prompt`, which sourced `/usr/lib/git-core/git-sh-prompt` 

## Multiple commands on a single line

all three commands will execute even some fails

    $ make ; make install ; make clean

only proceed to the next command when the preceding one succeeded

    $ make && make install && make clean

stop execution after the first successed

    $ cat file1 || cat file2 || cat file3

## Here documents

    $ cat <<EOT
    > haha
    > here documents
    > EOT
    haha
    here documents

variable expansion in here documents:

    $ name='Lee'
    $ echo $name
    Lee
    $ cat <<EOT
    > my name: $name
    > EOT
    my name: Lee

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



## read user input

    $ echo 'your name?'; read name
    your name?
    lee
    $ echo $name
    lee

## expr

usually used for simple arithmetic, normally replaced with more efficient `$((...))`

    $ x=$(expr 2 - 1)
    $ echo $x
    1

## printf

X/Open suggests it should be used in preference to `echo` for generating fomatted output, usage is similar to that in C

    $ printf '%10s\t%-10d\n' 'lee' 20
           lee  20        

## set

used to set shell options and positional parameters

    $ set foo bar lol
    $ echo $1 $3
    foo lol

a trick: using `set` to get fields of a command's ouput 

    $ date
    Tue Sep  9 09:48:17 CST 2014
    $ set $(date)
    $ echo $1 $2
    Tue Sep

this is just an example, you should not use this in reality to extract `date` ouput, you should use format strings

## shift

shift paramters off the left, can be used to scan parameters

    $ set foo bar hah   # set paramters
    $ echo $@
    foo bar hah

    $ shift

    $ echo $@
    bar hah
    $ echo $#
    2

## Generate random numbers

    $ echo $RANDOM 
    12521
    $ echo $RANDOM 
    15828
    $ echo $RANDOM 
    18324
    $ echo $RANDOM 
    21661

## Debugging scripts

Checks for syntax errors only; doesn’t execute commands

    set -o noexec
    set -n

Echoes commands before running them

    set -o verbose
    set -v

Echoes commands after processing on the command line

    set -o xtrace
    set -x

Gives an error message when an undefined variable is used

    set -o nounset
    set -u

set debugging flag around problem section in a script:

    #!/bin/bash

    set -x          # start debugging
    foo='bar'
    echo $foo

    echo $bar
    set +x          # end debugging

    exit 0


## read lines of a file

    $ while read -r line; do echo $line; done < my_file.txt

## vi editing mode

	set -o vi		# change to vi mode

	#				# prepend # to the line and send it to the history list


<a name="end"></a>

[bash by example]: http://www.ibm.com/developerworks/linux/library/l-bash/index.html
[15-examples-to-master-linux-command-line-history]: http://www.thegeekstuff.com/2008/08/15-examples-to-master-linux-command-line-history/
