python cheatsheet
===============

## Preface

Source: 

* [The Quick Python Book, Second Edition][quick_python_book]

## List

copy a list:

    y = x[:]

append items to list:

    >>> x = [1, 2]
    >>> x + [3, 4]
    [1, 2, 3, 4]

multiply a list: 

    >>> a = [1, 3]
    >>> a * 2
    [1, 3, 1, 3]

by default, nested list are copied by reference, use `copy.deepcopy()` to make a deep copy:

    >>> original = [[0], 1]
    >>> shallow = original[:]
    >>> import copy
    >>> deep = copy.deepcopy(original)
    >>> original
    [[0], 1]
    >>> shallow
    [[0], 1]
    >>> deep
    [[0], 1]

    >>> shallow[0][0] = 'zero'
    >>> shallow
    [['zero'], 1]
    >>> original    # the original is modified, too
    [['zero'], 1]
    >>> deep        # deep copy is not affected
    [[0], 1]
           
## Tuples

**NOTES** tuples are more efficient than lists, they are mostly used as dictionary keys

tuples can't be modified, but if it contains modifiable elements, those elements can be modified:

    >>> a = [1, 2]
    >>> b = (a, 3)
    >>> b[0][0]
    1
    >>> b[0][0] = 100
    >>> b
    ([100, 2], 3)
    >>> a[1] = 'first'
    >>> b
    ([100, 'first'], 3)
    >>> b[1] = 'abc'
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
    TypeError: 'tuple' object does not support item assignment

multiple assignments in one line:    

    >>> (one, two) = (1, 2)
    >>> one 
    1
    >>> two
    2

    >>> one, two = 1, 2  # the same, but even more simple
    >>> one 
    1
    >>> two
    2

swapping variables:

    >>> a = 1
    >>> b = 2
    >>> a, b = b, a
    >>> a
    2
    >>> b
    1

in python 3, a even more powerful feature, use a `*` to receive multiple items as a list:

    >>> x = (1, 2, 3, 4)
    >>> a, b, *c = x
    >>> a, b, c
    (1, 2, [3, 4])
    >>> a, *b, c = x
    >>> a, b, c
    (1, [2, 3], 4)
    >>> *a, b, c = x
    >>> a, b, c
    ([1, 2], 3, 4)
    >>> a, b, c, d, *e = x
    >>> a, b, c, d, e
    (1, 2, 3, 4, [])

this can also be done with list:

    >>> [a, b] = 1, 2
    >>> c, d = [10, 20]
    >>> a, b, c, d
    (1, 2, 10, 20)

## Set

set operations:

    >>> s1 = {1, 2}
    >>> s2 = {2, 3}
    >>> s1 | s2
    {1, 2, 3}
    >>> s1 & s2
    {2}
    >>> s1 ^ s2
    {1, 3}

**NOTES** set's elements must be immutable, but set itself is mutable

`frozenset` is immutable, and can be used as set element:

    >>> s = {1, 2}
    >>> s.add(3)
    >>> s
    {1, 2, 3}

    >>> s2 = frozenset(s)
    >>> s2.add(4)
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
    AttributeError: 'frozenset' object has no attribute 'add'

    >>> s.add(s2)
    >>> s
    {1, 2, 3, frozenset({1, 2, 3})}

## Strings vs. Bytes

**Bytes are bytes; characters are an abstraction. An immutable sequence of Unicode characters is called a string. An immutable sequence of numbers-between-0-and-255 is called a bytes object.**

- Bytes

        In [27]: b = b'ab\x63'

        In [28]: b
        Out[28]: b'abc'

`bytes` object is immutable, you can change a single byte by convert it to bytearray first

        In [29]: ba = bytearray(b)

        In [30]: ba
        Out[30]: bytearray(b'abc')

        In [31]: ba[0] = 65

        In [32]: ba
        Out[32]: bytearray(b'Abc')

- Encoding/Decoding

    strings can be encoded to bytes, bytes can be decoded to strings

        In [37]: s = 'a中'

        In [38]: b = s.encode('utf-8')

        In [39]: b
        Out[39]: b'a\xe4\xb8\xad'

        In [40]: s2 = b.decode('utf-8')

        In [41]: s2
        Out[41]: 'a中'

## Functions

lambda function:

    >>> foo = lambda x: x ** 2
    >>> foo(3)
    9

generator funtion:

    def gen():
        x = 0
        while x < 5:
            yield x     # generate a value
            x += 1
            
    for i in gen():
        print(i)

decorators:

    def my_decorator(func):
        print('in my_decorator, decorating', func.__name__)
        def wrapper_func(*args):
            print("Executing", func.__name__)
            func(*args)
        return wrapper_func

    @my_decorator   # decorator's name
    def my_func(x):
        print(x ** 2)
        
    my_func(3)

outputs:

    in my_decorator, decorating my_func
    Executing my_func
    9

## Module

three forms of import:

    import modulename
    from modulename import name1, name2, ...
    from modulename import *

The * stands for all the exported names in modulename. This imports all public names from modulename—that is, those that don't begin with an underscore, and makes them available to the importing code without the necessity of prepending the module name. But if a list of names called `__all__` exists in the module (or the package's `__init__.py`), then the names are the ones imported, whether they begin with an underscore or not.


## Set Module Searching paths

* set the `PYTHONPATH` environment variable (sucha as in `~/.bashrc`), direcotries in `PYTHONPATH` will be prepend to `sys.path`
* add to a `sys.path` directory a file like `xxx.pth`, which contains paths you want append to `sys.path`


## scoping and namespaces

there are always three namespaces in python: *local, global, built-in*

The global namespace of a function is the global namespace of the containing block of the function (where the function is defined). It's **independent** of the dynamic context from which it's called.

## the 'sys' module

    sys.path        module importing paths list
    sys.argv        arguments
    sys.stdin
    sys.stdout
    sys.stderr
    sys.exit

redirect standard out to a file:

    import sys

    class RedirectStdoutTo:
        def __init__(self, out_new):
            self.out_new = out_new

        def __enter__(self):
            self.out_old = sys.stdout
            sys.stdout = self.out_new

        def __exit__(self, *args):
            sys.stdout = self.out_old

    print('A')
    with open('out.log', mode='w', encoding='utf-8') as a_file, RedirectStdoutTo(a_file):
        print('B')
    print('C')
    

## filesystem, path related

create dirs

* `os.makedirs` -> create all necessary dirs
* `os.mkdir` -> do not make any intermediate dirs

remove dirs

* `os.rmdir` -> do not remove non-empty dir
* `shutil.rmtree` -> remove dirs recursively

copy dirs

* `shutil.copytree` -> copy dirs recursively

useful functions:

* `os.getcwd()` Gets the current directory
* `os.name` Provides generic platform identification
* `sys.platform` Provides specific platform information
* `os.environ` Maps the environment
* `os.listdir(path)` Gets files in a directory
* `os.chdir(path)` Changes directory
* `os.path.join(elements)` Combines elements into a path
* `os.path.split(path)` Splits the path into a base and tail (the last element of the path)
* `os.path.splitext(path)` Splits the path into a base and a file extension
* `os.path.basename(path)` Gets the base of the path
* `os.path.commonprefix(list_of_paths)` Gets the common prefix for all paths on a list
* `os.path.expanduser(path)` Expands ~ or ~user to a full pathname
* `os.path.expandvars(path)` Expands environment variables
* `os.path.exists(path)` Tests to see if a path exists
* `os.path.isdir(path)` Tests to see if a path is a directory
* `os.path.isfile(path)` Tests to see if a path is a file
* `os.path.islink(path)` Tests to see if a path is a symbolic link (not a Windows shortcut)
* `os.path.ismount(path)` Tests to see if a path is a mount point
* `os.path.isabs(path)` Tests to see if a path is an absolute path
* `os.path.samefile(path_1, path_2)` Tests to see if two paths refer to the same file
* `os.path.getsize(path)` Gets the size of a file
* `os.path.getmtime(path)` Gets the modification time
* `os.path.getatime(path)` Gets the access time
* `os.rename(old_path, new_path)` Renames a file
* `os.mkdir(path)` Creates a directory
* `os.makedirs` Creates a directory and any needed parent directories
* `os.rmdir(path)` Removes a directory
* `glob.glob(pattern)` Gets matches to a wildcard pattern
* `os.walk(path)` Gets all filenames in a directory tree


## files

use file object as an iterator, iterate all lines in it:

	file_object = open("myfile", 'r')
    count = 0
    for line in file_object:
        count = count + 1
    print(count)
    file_object.close()

read file lines to a list: 

    a = [l.rstrip() for l in open('/path/to/file')]

open and close files using `with` statement:

    with open('path/to/file', encoding='utf-8') as a_file:
        line_count = 0
        for line in a_file:
            line_count += 1
        print(line_count)


## Classes / Object-oriented programming / OOP

* private methods or instance variables: name begin with (but not terminated by) a '\_\_'

* access private variables:

        class Foo:
            def __init__(self):
                self.__x = 100

        f = Foo()
        print(f._Foo__x)  # you can access a private variable this way
        print(f.__x)      # this will result in an error

* @property

        class Temperature:
            def __init__(self):
                self._temp_fahr = 0

            @property
            def temp(self):
                return (self._temp_fahr - 32) * 5 / 9

            @temp.setter
            def temp(self, new_temp):
                self._temp_fahr = new_temp * 9 / 5 + 32

        >>> t = Temperature()
        >>> t._temp_fahr
        0
        >>> t.temp
        -17.777777777777779
        >>> t.temp = 34
        >>> t._temp_fahr
        93.200000000000003
        >>> t.temp
        34.0

## Regular Expressions

### syntax

only syntaxes need attentions are listed here

- `*?`, `+?`, `??`

    by default `*`, `+`, `?` are *greedy*, adding a `?` makes them *un-greedy*

        In [37]: re.sub(r'(<.*>).*', '\g<1>', '<h1>Title</h1>')
        Out[37]: '<h1>Title</h1>'

        In [38]: re.sub(r'(<.*?>).*', '\g<1>', '<h1>Title</h1>')
        Out[38]: '<h1>'

- `{m, n}?`

    makes the qualifier *un-greedy*

- `(...)`

    specify a match group, the content of a group can be *retrived after a match or matched later in the string with the `\number` sequence*

- `(?aiLmsux)`

    doesn't match anything, just add flags to the pattern, can be placed anywhere in the pattern, better at the beginning

        In [57]: re.sub(r'a', r'', 'aAbB')
        Out[57]: 'AbB'

        In [58]: re.sub(r'(?i)a', r'', 'aAbB')
        Out[58]: 'bB'

        In [59]: re.sub(r'a(?i)', r'', 'aAbB')
        Out[59]: 'bB'

- `(?:...)`

    a non-capturing group

        In [62]: re.sub(r'(?:\D+)(\d+)', r'\1', 'Gary2000')
        Out[62]: '2000'

- `(?P<name>...)`

    a named group

    reference a match group:

    - in the same pattern: `(?P=name)`, `\1`
    - in the replacement string: `\1`, `\g<1>`, `\g<name>`
    - when working with match object `m`: `m.group('name')`, `m.end('name')`

- `(?P=name)`
    
    a back reference to a named group

        In [82]: re.sub(r'<(?P<tag>.+?)>(?P<content>.*?)</(?P=tag)>', r'\g<tag>: \g<content>', '<h1>Hello World</h1><p>Python rocks</p>')
        Out[82]: 'h1: Hello World'

- `(?#...)`

    comment

- `(?=...)`

    lookahead assertion, matches if `...` matches next, but doesn't consume any of the string

        In [89]: re.sub(r'Gary(?= Li)', 'XXX', 'Gary Li, Gary Zhang')
        Out[89]: 'XXX Li, Gary Zhang'

- `(?!...)`

    negative lookahead assertion, matches if `...` doesn't match next

- `(?<=...)`

    positive lookbehind assertion, the pattern need to be in fixed length

        In [98]: re.sub(r'(?<=Gary )Li', 'XX', 'Gary Li, Tom Li')
        Out[98]: 'Gary XX, Tom Li'

- `(?<!...)`

    negative lookbehind assertion

- `(?(id/name)yes-pattern|no-pattern)`

    Will try to match with `yes-pattern` if the group with given id or name exists, and with `no-pattern` if it doesn’t. `no-pattern` is optional and can be omitted. For example, `(<)?(\w+@\w+(?:\.\w+)+)(?(1)>|$)` is a poor email matching pattern, which will match with `<user@host.com>` as well as `user@host.com`, but not with `<user@host.com` nor `user@host.com>`.

- `\A`

    matches only at the start of the string

- `\Z` 

    matches only at the end of the string

- `\b` 

    matches only at the beginning or end of a word

- `\B` 

    oppposite of `\b`





### compiled vs. simple functions

    prog = re.compile(pattern)
    result = prog.match(string)

is equivalent to

    result = re.match(pattern, string)

**compiled form is more efficient when the expression will be used several times in a single program**

### flags

- `re.A`, `re.ASCII`  

     make `\w`, `\W`, `\b`, `\B`, `\D`, `\s`, `\S` perform ASCII-only matching instead of full Unicode matching

        In [26]: re.sub('(\w+).*', '\g<1>', 'a中')
        Out[26]: 'a中'

        In [27]: re.sub('(\w+).*', '\g<1>', 'a中', flags=re.A)
        Out[27]: 'a'

- `re.DEBUG`

- `re.I`, `re.IGNORECASE`

- `re.M`, `re.MULTILINE`

    make `^` and `$` works on eache line, not just the beginning and end of the whole string

- `re.S`, `re.DOTALL`

    make `.` match newline

- `re.X`, `re.VERBOSE`

    allows you to add comments in your pattern

    the following are equal functionally:
    
        a = re.compile(r"""\d +  # the integral part
                       \.    # the decimal point
                       \d *  # some fractional digits""", re.X)
        b = re.compile(r"\d+\.\d*")

### raw string notation

**`\` do not have any specail meaning in raw strings**

`r'\n'` means a string with two characters `\` and `n`

`'\n'` is a one-character string containing a newline

so raw strings are often used in regular expression patterns

use triple quotes as delimiter when you want to include a quote mark in the string

    In [71]: r"""hello ' " quotes"""
    Out[71]: 'hello \' " quotes'


### functions

- `re.match` matches only at the beginning of the string, `re.search` checks for a match anywhere in the string

        In [102]: re.match("c", "abcdef")

        In [103]: re.search("c", "abcdef")
        Out[103]: <_sre.SRE_Match at 0x7f97b06bb718>

- `re.findall`

        In [106]: re.findall(r'(G\w+)', 'Gary, Jack, Tom, Gigi')
        Out[106]: ['Gary', 'Gigi']








## Python 3

### encoding

- In Python 3, all strings are sequences of Unicode characters.                    
- In Python 3, source code's default encoding is UTF-8, it's `ASCII` for Python 2

- Use a different encoding by put an encoding declaration on the first line:

        # -*- coding: windows-1252 -*-

### strings

- use `format()` to format strings

        In [11]: a = ['Gary', 20];

        In [12]: '{0} is {1} years old'.format(a[0], a[1])
        Out[12]: 'Gary is 20 years old'

        In [13]: '{info[0]} is {info[1]} years old'.format(info=a)
        Out[13]: 'Gary is 20 years old'

    number formating:

        In [22]: 'the number is {number:8.2f}'.format(number = 12.345)
        Out[22]: 'the number is    12.35'

        In [26]: 'the number is {number:09.2e}'.format(number = 12.345)
        Out[26]: 'the number is 01.23e+01


## Style tips

* Do not use `True|False` in conditional statement, variable name only is ok:

        if var:
            pass
        fi

* For Python 3, use `str.format()` to format strings, do not use `%`

* Use `locals()`, `globals()`, `dir()` for debugging

### naming conventions

    package: all_lower_case
    module: all_lower_case_and_short
    class: CamelCase, _CamelCase for internal use
    exception: SomeError

    function: lower_case
    global variable: lower_case
    
    constants: ALL_CAPS

## uninstall a package

	sudo pip uninstall phpsh

and remove any remaining files

	locate phpsh


    

[quick_python_book]: http://www.manning.com/TheQuickPythonBookSecondEdition
