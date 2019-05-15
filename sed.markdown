# sed cheatsheet

## Preface

Some useful tips of sed
Source: [sed & awk, 2nd Edition][sedawk2_book]

## Using sed

### Sample input file

```sh
$ cat list

John Daggett, 341 King Road, Plymouth MA
Alice Ford, 22 East Broadway, Richmond VA
Orville Thomas, 11345 Oak Bridge Road, Tulsa OK
Terry Kalkas, 402 Lans Road, Beaver Falls PA
Eric Adams, 20 Post Road, Sudbury MA
Hubert Sims, 328A Brook Road, Roanoke VA
Amy Wilde, 334 Bayshore Pkwy, Mountain View CA
Sal Carpenter, 73 6th Street, Boston MA
```

### Specify multiple instructions on the command line

1.  separate instructions with a semicolon

    ```sh
    $ sed 's/ MA/, Massachusettes/; s/ PA/, Pennsylvania/' list
    ```

2.  precede each instruction by `-e`

    ```sh
    $ sed -e 's/ MA/, Massachusettes/' -e 's/ PA/, Pennsylvania/' list
    ```

### Using a script file

Place instructions in a script file, use the script file with `-f`

```sh
$ cat tmp.sed
s/ MA/, Massachusettes/
s/ PA/, Pennsylvania/

$ sed -f tmp.sed list
John Daggett, 341 King Road, Plymouth, Massachusettes
Alice Ford, 22 East Broadway, Richmond VA
Orville Thomas, 11345 Oak Bridge Road, Tulsa OK
Terry Kalkas, 402 Lans Road, Beaver Falls, Pennsylvania
Eric Adams, 20 Post Road, Sudbury, Massachusettes
Hubert Sims, 328A Brook Road, Roanoke VA
Amy Wilde, 334 Bayshore Pkwy, Mountain View CA
Sal Carpenter, 73 6th Street, Boston, Massachusettes
```

### Suppress automatic display of input lines

By default, sed output every input line, you can suppress this behavior by specify the `-n` option, and then include a `p` in the instruction to output lines you intended to

```sh
$ sed -n 's/ CA/, California/p' list
Amy Wilde, 334 Bayshore Pkwy, Mountain View, California
```

If you use a sed script, put `#n` at the first line (equivalent to specify `-n` in command line) will also suppress the default output

## Substitution

Syntax:

```
[address]s/pattern/replacement/flags
```

Flags can be:

```
n       # only replace the nth occurence of the pattern in the pattern space
g       # replace globally in the pattern space
p       # print contents of the pattern space
w file  # write contents of the pattern space to file
```

Flags can be used in combination, such as `gp`, global and print

Meta characters in `replacement` section

```
&       # the string matched by the `pattern`
\<n>    # the <n>th subpattern matched
\       # escape `&`, `\`, or any other delimeter used
```

Example

```
$ sed -nr 's/Oak/\n\n/p' list
Orville Thomas, 11345

Bridge Road, Tulsa OK
```

## Pattern space

- `d` and `c` clears the pattern space, no following command is applied;
- `i` and `a` insert text before or append text after the current line;

  - these new text will be output anyway;
  - they do not affect line counter;
  - commands do not apply to them;
  - can only be specified on a single line;

- `c` can be used with a line range, but the text will output only once (if in a command group, the text will output for each line in the range)

## i/a - insert/append

append a line after the last line in `a.txt`

```sh
sed "$ a A new line" a.txt
```

## n - next

`n`: output contents of the pattern space, then reads the next line of input without return to the top of the script

example, delete blank line following `.H1` line:

```sh
/^\.H1/{
n
/^$/d
}
```

if a line begins with `.H1`, it is output (if default output not suppressed) , then the next line is read in, if blank, deleted

## N - Next

append next line to the pattern space, create a multiline pattern space, `^` matches the beginning of the space, `$` matches the end

## d - delete

delete the contents of pattern space, read in next line, and returns to top of the script

## D - Delete

Delete first line of pattern space, and **with second portion in the pattern space, returns to top of the script**, usually used in 'N', 'P', 'D' as a loop

```
## reduce multiple blank lines to one line
## 1. if matched a empty line, read in next line to pattern space.
## 2. if pattern space holds two empty line, delete the first one.
## 3. go on.

/^$/ {
N
/^\n$/D
}
```

## P - Print

Print the first line of the pattern space

## Misc

- Address requires `/` as delimeter, while patterns can use any character as delimeter;
- Command groups in one line, use ';' to separate commands:

  ```sh
  sed -n '/Alice/,/Eric/ {=; p}' list
  ```

[sedawk2_book]: http://shop.oreilly.com/product/9781565922259.do
