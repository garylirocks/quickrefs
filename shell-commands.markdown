# Shell Commands Tips

- [Preface](#preface)
- [`cd`](#cd)
- [`echo`](#echo)
- [`sort`](#sort)
- [`paste`](#paste)
- [`cut`](#cut)
- [`tr`](#tr)
- [`column`](#column)
- [`update-alternatives`](#update-alternatives)
- [`rename`](#rename)
- [`pwd`](#pwd)
- [`ls`](#ls)
- [`touch`](#touch)
- [`whatis`](#whatis)
- [`whereis`](#whereis)
- [`logrotate`](#logrotate)
- [`watch`](#watch)
- [`od`](#od)
- [`mktemp`](#mktemp)
- [`expand`](#expand)
- [`find`](#find)
- [`xargs`](#xargs)
- [`pushd`, `popd`, `dirs`](#pushd-popd-dirs)
- [`rsync`](#rsync)
- [`envsubst`](#envsubst)
- [System](#system)
- [Networking](#networking)
  - [`netstat`](#netstat)
  - [`nc`, `netcat`](#nc-netcat)
    - [Port scanning](#port-scanning)
    - [Data transfer](#data-transfer)
  - [`tcpdump`](#tcpdump)
  - [`ssh`](#ssh)
    - [ProxyJump](#proxyjump)
  - [`curl`](#curl)
- [One liner](#one-liner)
- [Helpful tools](#helpful-tools)

## Preface

Some useful tips of shell commands
Source: [团子的小窝][tuanzi]

## `cd`

usually if `cd` is followed by a relative path, it's relative to current working directory, you can change this by setting environment variable `CDPATH`:

    $ pwd
    /home/lee
    $ CDPATH='/etc'; cd apache2
    /etc/apache2
    $ pwd
    /etc/apache2

## `echo`

useful options, `-e` to enable escaping, `-n` to suppress default-added-newline at the end

    $ echo "hello\nworld"
    hello\nworld
    $ echo -e "hello\nworld"
    hello
    world
    $ echo -n "hello\nworld"
    hello\nworld$

## `sort`

Common options:

- `-n` sort as number;
- `-h` compare human readable numbers (e.g., 2K 1G);

    ```sh
    du -sh * | sort -h

    # 4.0K    x.sh
    # 44K     test
    # 12M	    screenshots
    ```

- `-r` sort from big to small;
- `-u` output only first of equal values;
- `-t` for delimiter, if you need to use tab as separator, use `-t$'\t'`;
- `-k` specify sorting fields(`-k3,3` to sort for the third field), and options of each field;

    ```sh
    # sort according to user id from big to small:
    sort -t':' -k3nr,3 /etc/passwd

    # ...
    # bin:x:2:2:bin:/bin:/bin/sh
    # daemon:x:1:1:daemon:/usr/sbin:/bin/sh
    # root:x:0:0:root:/root:/bin/bash
    ```

**CAUTION** if you want to output sort result to the same file as input file, do not use redirection, this will empty the file, as the file will be emptied even before sorting, use `-o` instead:

```sh
sort -o input.file input.file   # use -o
```

## `paste`

merge lines of files, if `-s` is set, merge one file at a time, quite useful for join lines of a file

    $ cat text1
    hello
    world
    $ cat text2
    happy
    new
    year

    $ paste -d'|' text1 text2
    hello|happy
    world|new
    |year

    $ paste -s -d',' text1 text2
    hello,world
    happy,new,year

## `cut`

    $ cut -d: -f1,3 --output-delimiter=' ' /etc/passwd | head -2
    root 0
    daemon 1

## `tr`

```sh
# delete a charater
echo 'a-------------b' | tr -d '-'
# ab

# squeeze multiple occurrences of a character to one
echo 'a-------------b' | tr -s '-'
# a-b

# delete characters not in specified range
# same as: only keep characters from a specified range
echo abc123 | tr -dc 0-9
# 123

# lower to upper case
echo 'ab' | tr -s '[:lower:]' '[:upper:]'
# AB
```

## `column`

columnate text

    $ cat temp.txt
    asia.china
    america.usa
    europe.france

    $ column -s '.' -t temp.txt
    asia     china
    america  usa
    europe   france

## `update-alternatives`

installed multiple version of a program in system, such as:

    $ sudo update-alternatives --display node
    node - auto mode
      link currently points to /usr/bin/nodejs
    /usr/bin/nodejs - priority 50
      slave node.1.gz: /usr/share/man/man1/nodejs.1.gz
    Current 'best' version is '/usr/bin/nodejs'.

    $ node -v
    v0.10.37

there is only one option for node now, we can add another version:

    $ sudo update-alternatives --install /usr/bin/node node /usr/local/n/versions/node/5.4.1/bin/node 80
    update-alternatives: using /usr/local/n/versions/node/5.4.1/bin/node to provide /usr/bin/node (node) in auto mode
    update-alternatives: warning: not removing /usr/share/man/man1/node.1.gz since it's not a symlink

    $ node -v
    v5.4.1

## `rename`

rename multiple files

    $ ls
    greatwall-001.jpg  greatwall-002.jpg  greatwall-003.jpg  greatwall-004.jpg

    $ rename -n 's/-00/-/' *.jpg # see what files would be renamed withoud actual actions
    greatwall-001.jpg renamed as greatwall-1.jpg
    greatwall-002.jpg renamed as greatwall-2.jpg
    greatwall-003.jpg renamed as greatwall-3.jpg
    greatwall-004.jpg renamed as greatwall-4.jpg

    $ rename 's/-00/-/' *.jpg

    $ ls
    greatwall-1.jpg  greatwall-2.jpg  greatwall-3.jpg  greatwall-4.jpg

sanitize filenames

    $ ls 'Hello world (2014) - 720p.mp4'
    Hello world (2014) - 720p.mp4
    $ rename 's/[ \._()-]+/./g' 'Hello world (2014) - 720p.mp4'
    $ ls Hello.world.2014.720p.mp4
    Hello.world.2014.720p.mp4

change file name extensions to lower case

    $ ls hello.world.*
    hello.world.TXT
    $ rename 's/\.([^.]+)$/.\L$1/' hello.world.TXT
    $ ls hello.world.*
    hello.world.txt

change file name to lowercase:

    $ rename 'y/A-Z/a-z/' Apple.Txt
    $ ls
    apple.txt

or

    $ rename 's/(.)/\l$1/g' *

## `pwd`

show working directory, use `-P` to ignore symlinks

    $ ll test
    lrwxrwxrwx 1 lee lee 19 2012-12-19 10:07 test -> /home/lee/code/php//
    $ cd test
    $ pwd
    /var/www/test
    $ pwd -P
    /home/lee/code/php

## `ls`

ouput one file per line, use `-1`

    $ ls
    bar.txt  foo.txt
    $ ls -1
    bar.txt
    foo.txt

## `touch`

update access and modification times of a file, if a file does not exists, it will be created
`-a`: change only access time; `-m`: change only modification time, `-t`: update to a specified time instead of current time

**ctime will always be updated to current time**

atime: file access time
mtime: file content modification time
ctime: file properties modification time

    $ stat hello.txt
      File: `hello.txt'
      Size: 0           Blocks: 0          IO Block: 4096   regular empty file
    Device: 801h/2049d  Inode: 145477      Links: 1
    Access: (0644/-rw-r--r--)  Uid: ( 1000/     lee)   Gid: ( 1000/     lee)
    Access: 2013-05-06 20:03:16.274190365 +0800
    Modify: 2013-05-06 20:03:16.274190365 +0800
    Change: 2013-05-06 20:03:16.274190365 +0800
    $ touch hello.txt
    $ stat hello.txt
      File: `hello.txt'
      Size: 0           Blocks: 0          IO Block: 4096   regular empty file
    Device: 801h/2049d  Inode: 145477      Links: 1
    Access: (0644/-rw-r--r--)  Uid: ( 1000/     lee)   Gid: ( 1000/     lee)
    Access: 2013-05-06 20:03:23.290897995 +0800
    Modify: 2013-05-06 20:03:23.290897995 +0800
    Change: 2013-05-06 20:03:23.290897995 +0800

## `whatis`

`-w`: wildcards, `-s`: limit section

    # search command start with 'wh'
    $ whatis -s 1 -w 'wh*'
    whatis (1)           - display manual page descriptions
    whereis (1)          - locate the binary, source, and manual page files for a com...
    which (1)            - locate a command
    whiptail (1)         - display dialog boxes from shell scripts
    who (1)              - show who is logged on
    whoami (1)           - print effective userid
    whois (1)            - client for the whois directory service

`-r`: regex

    # search command end with 'fox'
    $ whatis -s 1 -r 'fox$'
    firefox (1)          - a free and open source web browser from Mozilla

## `whereis`

    $ whereis php
    php: /usr/bin/php /usr/bin/X11/php /usr/share/man/man1/php.1.gz

    # only search binary path
    $ whereis -b php
    php: /usr/bin/php /usr/bin/X11/php

    # only search manual path
    $ whereis -m php
    php: /usr/share/man/man1/php.1.gz

## `logrotate`

add a custom logrotate config to `/etc/logrotate.d/`

    $ cat apache-rewrite
    /lee/log/rewrite.log {
        #rotate daily
        daily
        #rotate if size greater than this
        size 10M
        #if log file missing, go on withoud issuing an error msg
        missingok
        #how many log files to keep
        rotate 365
        #user, group, mod for newly created log file
        create 640 lee lee
        #add date extension to old log files
        dateext
    }

## `watch`

execute a program periodically, showing output fullscreen

    # run the date command every 1 seconds, and highlight difference
    $ watch -n 1 -d=culmulative date +%H:%M:%S

## `od`

dump files in octal format

    # make sure your console is using utf8 encoding
    $ echo 'a 李' > t.utf8
    $ cat t.utf8
    a 李

    # make a gbk encoded version of the file
    $ iconv -f utf8 -t gbk t.utf8 > t.gbk
    $ cat t.gbk
    a �

    # the utf8 version uses 6 bytes, gbk version uses 5 bytes
    $ wc -c t.utf8 t.gbk
     6 t.utf8
     5 t.gbk
    11 total

    # checkout the actual octals using od
    $ od -t x1c t.utf8
    0000000  61  20  e6  9d  8e  0a
              a     346 235 216  \n
    0000006
    $ od -t x1c t.gbk
    0000000  61  20  c0  ee  0a
              a     300 356  \n
    0000005

the '李' is encoded as `e6 9d 8e` in utf8, `c0 ee` in gbk

to make ubuntu terminal to correctly display gbk characters, see: http://blog.sina.com.cn/s/blog\_a5b3ccfd0101a0u9.html

## `mktemp`

Create temporary files or folders

```sh
# a temporary file with random characters and current time
mktemp data_XXXX_$(date +%Y%m%d-%H%M%S)
# data_vFl7_20221208-154803

# make a directory
mktemp -d /tmp/data-folder.XXXX   # create directory
# /tmp/data-folder.0Fss
```

## `expand`

expand tabs to whitespace, can be used to align text in columns

    $ cat imagesize
    a.jpg   469x705
    long-name.jpg   705x470
    really-really-long-long-name.jpg    705x470

    $ cat imagesize | expand -t 40
    a.jpg                                   469x705
    long-name.jpg                           705x470
    really-really-long-long-name.jpg        705x470

or use `column`

    $ cat imagesize | column -t
    a.jpg                             469x705
    long-name.jpg                     705x470
    really-really-long-long-name.jpg  705x470

## `find`

```sh
# common usage, matching basename only (both files and directories)
find . -name '*gary*'

# match full path, including basename
find . -path '*/js/*'

# match multiple names
find . -name '*.html' -o -name '*.md'

# or use extended RegEx, matches full path
find . -regextype posix-extended -regex '.*(php)|(phtml)'

# anything last modified at least 10 days ago
find . -mtime +10

# exclude current directory (at least one level deep)
find . -mindepth 1 -type d

# execute a command on matched files
# `{}` is a placeholder for matched files, `\;` is required
find . -type f -regex '\./[1-9]+' -exec cp {} dest \;

# use with xargs, and use null as separator, to handle file names containing white spaces
find . -name '*.png' -print0 | xargs -0 ls -al
```

Given a directory like this:

```
.
├── a.txt
└── subdir
    └── a.txt
```

`-prune -o (...) -print` is a common pattern to ignore a directory:

```sh
find . -name 'subdir' -prune -o -name 'a.txt' -print
# ./a.txt

# equivalent to
find . \( -name 'subdir' -prune \) -o \( -name 'a.txt' -print \)
# ./a.txt

# -print is essential here,
# otherwise a global -print will be applied and './subdir' is output as well
find . \( -name 'subdir' -prune \) -o \( -name 'a.txt' \)
# ./subdir
# ./a.txt
```


## `xargs`

Some shell commands don't take standard input, `xargs` allow you to convert standard input to arguments;

* Print/Confirm commands

    ```sh
    # -t enables printing out commands before execution
    echo A B C | xargs -t echo
    # echo A B C
    # A B C

    # Confirm before execution
    echo A B C | xargs -p echo
    # echo A B C ?...y
    # A B C
    ```

* Placeholder

    Use `{}` as a placeholder, so the argument can be at any position

    ```sh
    find . -name '*.txt' | xargs -i cp {} newFolder
    ```

* How to split inputs

    ```sh
    # By default, all input lines are concatenated:
    echo -e 'a\nb\nc' | xargs -t echo
    # echo a b c
    # a b c

    # You can run one command per input line:
    echo -e 'a\nb\nc' | xargs -t -L 1 echo
    # echo a
    # a
    # echo b
    # b
    # echo c
    # c

    # Or, you can specify how many arguments per command line:
    echo {0..5} | xargs -t -n 2 echo
    # echo 0 1
    # 0 1
    # echo 2 3
    # 2 3
    # echo 4 5
    # 4 5
    ```

* Run multiple processes

    ```sh
    # run multiple processes at the same time to speed up
    docker ps -q | xargs -n 1 --max-procs 2 docker kill
    ```

## `pushd`, `popd`, `dirs`

`pushd` can create an dirs stack, which can be inspected by `dirs`, and then you can use `cd ~` to jump between different dirs

    $ pwd
    /home/lee/playground/testing

    $ mkdir dir1 dir2
    $ dirs -v
     0  ~/playground/testing

    $ pushd dir1
    ~/playground/testing/dir1 ~/playground/testing
    $ pushd ../dir2
    ~/playground/testing/dir2 ~/playground/testing/dir1 ~/playground/testing
    $ pushd .
    ~/playground/testing/dir2 ~/playground/testing/dir2 ~/playground/testing/dir1 ~/playground/testing

    $ dirs -v
     0  ~/playground/testing/dir2
     1  ~/playground/testing/dir2
     2  ~/playground/testing/dir1
     3  ~/playground/testing

    $ cd ~2
    $ pwd
    /home/lee/playground/testing/dir1

    $ dirs -v
     0  ~/playground/testing/dir1
     1  ~/playground/testing/dir2
     2  ~/playground/testing/dir1
     3  ~/playground/testing

    $ cd ~1
    $ pwd
    /home/lee/playground/testing/dir2

## `rsync`

```sh
# sync everything in src/ folder to dest/ folder
rsync -avp src/ ./dest

# sync everything including src/ folder to dest/
rsync -avp src ./dest

# everything only in dest/ will be deleted
rsync -avp --delete src/ ./dest
```

## `envsubst`

Replace variables in standard input

```sh
export fruit1=Apple
export fruit2=Orange
export fruit3=Banana

# all variables are replaced by default
echo '$fruit1, $fruit2, and ${fruit3}' | envsubst
Apple, Orange, and Banana

# only target specified vars
# $var1 and ${var1} are equivalent format
echo '$fruit1, $fruit2, and ${fruit3}' | envsubst '${fruit2}, $fruit3'
$fruit1, Orange, and Banana
```

## System

- `uptime`  system uptime
- `who`     who is logged in
- `whoami`  current username
- `uname`   kernel info
- `lsb_release -a`  Linux distro info
- `lsof | grep fileName` find what program opened a file


## Networking

### `netstat`

```sh
# show listening processes
netstat -lntp
# ...
# Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
# tcp        0      0 127.0.0.1:5037          0.0.0.0:*               LISTEN      9772/adb
# ...
```

`ss` and `lsof` can do similar things

### `nc`, `netcat`

#### Port scanning

```sh
# time out in 3 seconds
nc -zvw3 localhost 22
# Connection to localhost 22 port [tcp/ssh] succeeded!

# scan a port range
nc -zvw3 host.example.com 20-30
```

#### Data transfer

using nc to send files

at remote host `dev`:

```sh
$ cat test.txt
hello world
$ nc -l 5555 < test.txt     # start listening
```

at localhost:

```sh
$ nc dev 5555               # connect to a remote port
hello world
```

### `tcpdump`

- Capture hosts based on IP address

    ```sh
    # -nn: don't resolve host and port
    sudo tcpdump -nn host 8.8.8.8

    # ...
    # 20:49:09.586763 IP 172.27.247.166.47917 > 8.8.8.8.53: 55856+ [1au] A? apple.com. (50)
    # 20:49:09.622909 IP 8.8.8.8.53 > 172.27.247.166.47917: 55856 1/0/1 A 17.253.144.10 (54)
    ```


### `ssh`

- Port Forwarding (tunneling)

    ![ssh tunnel](images/ssh_tunnel.png)

    Port forwarding, any connection to local port 123 is forwarded to `localhost:456` on `remotehost`

    ```sh
    ssh -L 123:localhost:456 -N -T remotehost
    ssh -L 123:farawayhost:456 -N -T remotehost
    ```

    - `-N` do not execute any remote commands
    - `-T` disable pseudo tty allocation


- Reverse tunneling

    ![ssh reverse tunneling](images/ssh_reverse-tunnel.png)

    Any connection to remotehost's port 123 is forwarded to `localhost:456` on your host

    ```sh
    ssh -R 123:localhost:456 -N -T remotehost
    ssh -R 123:nearhost:456 -N -T remotehost
    ```

- Use ssh as a SOCKS proxy:

    ```sh
    # start a SOCKS proxy: localhost:8080
    ssh -fnNC -D 8080 remotehost
    ```

#### ProxyJump

In `~/.ssh/config`, use `ProxyJump` to SSH via a hop:

```sh
Host hop
    User gary
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id1.pem

Host dest
    User gary
    HostName destHostName
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id2.pem
    ProxyJump hop
```

then `ssh dest` will login you to `dest` via `hop`

- `id1.pem` and `id2.pem` are on local;
- `hop` need to be able to resolve `destHostName`;

Then we could also forward a local port to a port on `dest` like:

```sh
ssh -L 80:localhost:8080 -N dest
```

### `curl`

- Post JSON data

    ```sh
    curl -X POST 'https://example.com' \
        -H 'Content-Type: application/json' \
        -d '{ "name": "Gary" }'
    ```

- Output connection time info
    ```sh
    curl -I -w "\n namelookup: \t\t%{time_namelookup} \n connect: \t\t%{time_connect} \n appconnect: \t\t%{time_appconnect} \n pretransfer: \t\t%{time_pretransfer} \n starttransfer: \t%{time_starttransfer} \n total: \t\t%{time_total}\n" https://www.google.com

    ...

    namelookup:            0.001128
    connect:               0.033624
    appconnect:            0.173827
    pretransfer:           0.174055
    starttransfer:         0.372834
    total:                 0.373073
    ```

  - `connect` TCP connect time
  - `appconnect` includes SSL/SSH connect/handshake time
  - `starttransfer` includes `pretransfer` and the time the server needed to calculate the result

- Fake the `Host:` header

    ```sh
    curl -H 'Host: example.com' http://127.0.0.1
    ```

  - Works for HTTP only
  - If you follow redirects, the fake `Host:` header would be sent to those requests as well

- Domain fronting

    ```sh
    curl -H 'Host: forbidden.com' "https://allowed.com" -verbose
    ```

  - Use "allowed.com" to bypass Firewall, establish SSL connection, but actually get contents from "forbidden.com"

- For HTTPS

    ```sh
    curl --resolve example.com:443:127.0.0.1 https://example.com/
    ```

    - This populates curl's DNS cache with a custom entry for `example.com` port 443 with the address `127.0.0.1`
    - `example.com` is used as the SNI field in TLS handshake, so the server can send the correct certificate back
    - `example.com` is used as `Host:` header as well

- Output headers only

    ```sh
    # -s : silent
    # -S : show-error
    # -L : follow redirection
    # '-D -': dump header to stdout
    # '-o /dev/null': discard data
    curl -sSL -D - -o /dev/null www.example.com.org
    ```

- Could be used to test port connection

    See discussions here about how to exit immediately after successful connection: https://stackoverflow.com/a/71962683

    ```sh
    curl --telnet-option 'BOGUS=1' --connect-timeout 2 -s telnet://google.com:443 </dev/null
    ```


## One liner

- `man 7 ascii` get ASCII table


## Helpful tools

`tldr` gives you usage examples for commands, so you don't need to read lengthy man pages

```sh
npm install -g tldr

tldr tar
```



[tuanzi]: http://kodango.com
