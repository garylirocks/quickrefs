# awk cheatsheet

- [Preface](#preface)
- [basic usage](#basic-usage)
  - [sample input file:](#sample-input-file)
  - [simple use](#simple-use)
  - [use with sed](#use-with-sed)
- [Records and Fields](#records-and-fields)
- [Field Separators](#field-separators)
- [Variables](#variables)
- [System variables](#system-variables)
- [Output formatting](#output-formatting)
- [Array](#array)
- [Function](#function)
- [`getline`](#getline)
- [Misc](#misc)
- [Recipes](#recipes)

## Preface

Some useful tips of awk
Source: [sed & awk, 2nd Edition][sedawk2_book], [团子的小窝][tuanzi]

## basic usage

### sample input file:

    $ cat list
    John Daggett, 341 King Road, Plymouth MA
    Alice Ford, 22 East Broadway, Richmond VA
    Orville Thomas, 11345 Oak Bridge Road, Tulsa OK
    Terry Kalkas, 402 Lans Road, Beaver Falls PA
    Eric Adams, 20 Post Road, Sudbury MA
    Hubert Sims, 328A Brook Road, Roanoke VA
    Amy Wilde, 334 Bayshore Pkwy, Mountain View CA
    Sal Carpenter, 73 6th Street, Boston MA

### simple use

awk treats each line as a record consisting of fields separated by delimiter(default to spaces or tabs), `$0` represents the entire line, `$1` refers to the first field, `$2` the second, ...
the delimiter can be specified by the `-F` option

```sh
$ awk '{print $1}' list # print first field of each line
John
Alice
Orville
Terry
Eric
Hubert
Amy
Sal

$ awk '/VA/ {print $1}' list # print first field of each line that matches the regular expression
Alice
Hubert

$ awk -F, '{print $1; print $2; print $3;}' list | head # use ',' as delimiter and rearrange fields

John Daggett
    341 King Road
    Plymouth MA
Alice Ford
    22 East Broadway
    Richmond VA
Orville Thomas
    11345 Oak Bridge Road
    Tulsa OK
Terry Kalkas
```

### use with sed

output state and names in each state
put commands in a script named `nameByState.sh`

    $ cat nameByState.sh
    #!/bin/bash

    sed '
    s/ CA/, California/
    s/ MA/, Massachusetts/
    s/ OK/, Oklahoma/
    s/ PA/, Pennsylvania/
    s/ VA/, Virginia/
    ' |
    awk -F, '{
    			print $4 ", "  $0;
    		}' |
    sort |
    awk -F, '
    	$1 == LastState {
    		print "\t" $2;
    	}
    	$1 != LastState {
    		LastState = $1; print $1 "\n" "\t" $2;
    	}
    '

replace state code with names, sort by state names
`LastState` is a variable (awk variables are initialized to the empty string, they do not need to be assigned before using)
run the script:

    $ cat list | ./nameByState.sh
     California
         Amy Wilde
     Massachusetts
         Eric Adams
         John Daggett
         Sal Carpenter
     Oklahoma
         Orville Thomas
     Pennsylvania
         Terry Kalkas
     Virginia
         Alice Ford
         Hubert Sims

## Records and Fields

matching a field

if field 5 matches `/MA/`:

```awk
$5 ~ /MA/ {
    print $0
}
```

if field 5 does not matche `/MA/`:

```awk
$5 !~ /MA/ {
    print $0
}
```

## Field Separators

By default, awk use white space as delimiter, leading and trailing spaces are trimed, fields are separated by consecutive spaces

You can set delimiter by the `-F` command line option or in a `BEGIN {}` section

```sh
FS = "\t"  # a single tab
FS = "\t+"  # one or more consecutive tabs
FS = "[ \t,]"  # any one of space, tab or comma

awk -F'.' '{print $NF}'
# or
awk 'BEGIN { FS="." } {print $NF}'
```

## Variables

each variable has a string value(default to '') and a numeric value(default to 0), variables to not need to be declared

    z = "Hello" "World"
    # equivalent to
    z = "HelloWorld"

supply command line variables with `-v`, this will make the variable available in the `BEGIN` section:

```sh
awk -v var=1 'BEGIN {print var, "in BEGIN"} {print var, "in main"}' gary.txt

# 1 in BEGIN
# 1 in main
```

## System variables

    FS      field separator, default ' '
    OFS     output field separator, default ' ', it is generated for each comma used to separate arguments in a `print` statement
    NF      number of fields for current record, you can use `$NF` for the last field of current record

    RS      record separator, default '\n', set `RS=""` make a blank line as record delimiter
    ORS     output record separator, default '\n'
    NR      number of current record
    FNR     number of current record in current input file

    FILENAME    current input file name

    CONVFMT     controls how numbers are converted to strings, default to '%.6g' e.g. 100.12345678 will be converted to 100.123
    OFMT        controls how numbers output by the `print` statement

    ARGV        an array of command line arguments, starts at 0
    ARGC        counts of elements in ARGV
    ENVIRON     an array of enviroment variables

## Output formatting

variable specifier:

`%-width.precision format-specifier`

`%-10.5s` -> a field of width 10, left justified, 5 chars at most

```sh
# specify width and precision dynamically
printf("%*.*g\n", 5, 3, myvar);
```

`printf` do not output newline automatically, while `print` does

direct output to file:

    print var > "var.txt"

direct output to pipe:

    print | command

## Array

associative array:

    for ( item in array ) {
        print item, " -> ", array[item]
    }

testing if a key exists in an array:

    if ( key in array ) {
        print array[key]
    }

delete an element from array:

    delete array[subscript]

**multidimensional arrays**
awk do not support multidimensional arrays, but it has a syntax that looks like one:

    array[1, 2] = 'hello'

the key is actually "1\0342", where "\034" is the default value of system variable `SUBSEP`

test if a multi key exists:

    if ( (x, y) in array ) {
        # do something
    }

## Function

split a string:

    n = split(string, array, separator)

variables defined in a function are global, put them in the parameter list to make them local

a function example(temp, i, j are intended for local use):

    # sort numbers in ascending order
    function sort(ARRAY, ELEMENTS,   temp, i, j) {
        for (i = 2; i <= ELEMENTS; ++i) {
            for (j = i; ARRAY[j-1] > ARRAY[j]; --j) {
                temp = ARRAY[j]
                ARRAY[j] = ARRAY[j-1]
                ARRAY[j-1] = temp
            }
        }
        return
    }

**common variables are passed by value; arrrays are passed by reference**

## `getline`

`next` get the next line from input and return to top of the script

`getline` get the next line from input and continue the script, assigns `$0` and parse it to fields,
`NF`, `NR`, `FNR` are set, the newline becomes the current line

`getline` can read from normal input stream,

- or from a file:

        while ( (getline < "data") > 0 ) # read all lines from the file "data"
            print

- or, from standard input:

        BEGIN { printf "Enter your name: "
            getline < "-"
            print
        }

- or from a pipe:

        "who am i" | getline me

        while ("who" | getline) # read multiple lines, 'who' is executed only once
            who_out[++i] = $0

_read a newline to a variable_, in this case, the `$0` is not changed, `NF` not affected, but `NR` and `NFR`
are incremented

    BEGIN { printf "Enter your name: "
        getline name < "-"
        print name
    }

## Misc

**`BEGIN` only executes once, even for multiple input files**

## Recipes

- Sums up a column of numbers

```sh
gary 20
jack 30
```

```sh
awk '{sum += $2} END {print sum}' ./numbers.txt
# 50
```

[tuanzi]: http://kodango.com
[sedawk2_book]: http://shop.oreilly.com/product/9781565922259.do
