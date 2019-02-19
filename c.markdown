# C Cheatsheet

## Compile / Assemble / Link

```sh
# print shared library dependencies
ldd pdo.so
#   linux-vdso.so.1 =>  (0x00007fffda9fe000)
#   libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f1557cf5000)
#   /lib64/ld-linux-x86-64.so.2 (0x00007f15582f4000)
```

## Static and dynamic library

Three files:

`hello.cpp`:

```c
#include <iostream>

using namespace std;

void hello(void) {
    cout <<"Hello "<<endl;
}
```

`hello.h`:

```c
void hello(void);
```

`main.cpp`:

```c
#include "hello.h"

int main(int argc, char *argv[]) {
    hello();
    return 0;
}
```

Compile static library:

```sh
ls
# hello.cpp  hello.h  main.cpp

gcc -o hello.o -c hello.cpp
ls
# hello.cpp  hello.h  hello.o  main.cpp

# create static library
ar cqs libHello.a hello.o
ls
# hello.cpp  hello.h  hello.o  libHello.a  main.cpp

# link against static library
g++ -o out_static main.cpp -L./ -lHello
ls
# hello.cpp  hello.h  hello.o  libHello.a  main.cpp  out_static

./out_static
# Hello
```

Compile dynamic library:

```sh
# create dynamic library
g++ -O -fpic -shared -o libHello.so hello.cpp
ls
# hello.cpp  hello.h  hello.o  libHello.a  libHello.so  main.cpp  out_static

# link against dynamic library (this command is the same as when build static executable, libHello.so is preferred over libHello.a)
g++ -o out_dynamic main.cpp -L./ -lHello
ls
# hello.cpp  hello.o     libHello.so  out_dynamic
# hello.h    libHello.a  main.cpp     out_static

./out_dynamic
# Hello
```

Library dependency comparison:

```sh
ldd out_static
#   linux-vdso.so.1 =>  (0x00007fff46304000)
#   ...

ldd out_dynamic
#   linux-vdso.so.1 =>  (0x00007fff533fe000)
#   libHello.so => ./libHello.so (0x00007f786bd8c000)
#   ...
```

Update the dynamic library:

```sh
# replace 'Hello' with 'Dog' in hello.cpp
vi hello.cpp

# rebuild .so file
g++ -O -fpic -shared -o libHello.so hello.cpp

# updated
./out_dynamic
# Dog

# not changed
./out_static
# Hello
```
