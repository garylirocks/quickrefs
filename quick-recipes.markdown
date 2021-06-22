# Quick Recipes

Quick productivity tips, shortcuts, command line snippets.

- [Shortcuts](#shortcuts)
  - [Ubuntu](#ubuntu)
- [Use CapsLock as Ctrl and Escape](#use-capslock-as-ctrl-and-escape)
- [Add a user as sudoer](#add-a-user-as-sudoer)
- [Change file/directory permissions](#change-filedirectory-permissions)
  - [`setgid`](#setgid)
  - [sticky bit](#sticky-bit)
- [Find out Linux distribution name](#find-out-linux-distribution-name)
- [Find module version](#find-module-version)
- [Disable a service from autostart](#disable-a-service-from-autostart)
- [Display IP address in shell prompt](#display-ip-address-in-shell-prompt)
- [Mount/Unmount device](#mountunmount-device)
  - [`cifs`](#cifs)
- [Relabel usb hard drive](#relabel-usb-hard-drive)
- [Hide default folders in home directory in Ubuntu](#hide-default-folders-in-home-directory-in-ubuntu)
- [Send email](#send-email)
- [Work with ps or pdf files](#work-with-ps-or-pdf-files)
- [SSH login without password](#ssh-login-without-password)
- [Version number specifications](#version-number-specifications)
- [Lorem ipsum](#lorem-ipsum)
- [Extract media from Office files (docx,xlsx,pptx)](#extract-media-from-office-files-docxxlsxpptx)
- [Package files](#package-files)
- [Download all images from a web page](#download-all-images-from-a-web-page)
- [Linux process management](#linux-process-management)
  - [`kill`](#kill)
  - [`pgrep`, `pkill`](#pgrep-pkill)
- [Limit Google Chrome memory usage](#limit-google-chrome-memory-usage)
- [Chrom DevTools](#chrom-devtools)
- [Limit memory/cpu usage using cgroups](#limit-memorycpu-usage-using-cgroups)
- [`resolve.conf`](#resolveconf)
- [Search files (grep)](#search-files-grep)
- [Hash](#hash)
- [Self-signed SSL certs](#self-signed-ssl-certs)
- [DNS tools](#dns-tools)

## Shortcuts

### Ubuntu

```
Alt + F2                # run a command in Dash
Ctrl + Alt + F1 ~ F6    # switch to virtual terminals

# workspaces
Super + s               # spread workspaces

Ctrl + Alt + Left       # move to workspace left
Ctrl + Alt + Right      # move to workspace right
Ctrl + Alt + Down       # move to workspace down
Ctrl + Alt + Up         # move to workspace up

Ctrl + Shift + Alt + Left       # move window to workspace left
Ctrl + Shift + Alt + Right      # move window to workspace right
Ctrl + Shift + Alt + Down       # move window to workspace down
Ctrl + Shift + Alt + Up         # move window to workspace up
```

## Use CapsLock as Ctrl and Escape

Set CapsLock to be Escape when tapped alone, and Ctrl when held down

- Install `xcape`
- Set the following script in autostart:

  ```sh
  # swap Ctrl and CapsLock
  setxkbmap -option ctrl:swapcaps

  # set Ctrl as Escape when tapped alone
  xcape -e 'Control_L=Escape'
  ```

## Add a user as sudoer

add the user to the `sudo` group

```sh
# login as root, add gary to the sudo group (or 'wheel' group for CentOS)
usermod -a -G sudo gary

# login as gary, confirm it had been added to the sudo group
id
# uid=1000(gary) gid=1000(gary) groups=1000(gary),27(sudo)

# crete a file in /etc/sudoers.d/ with the same name of your username
echo "gary ALL=(ALL) ALL" > /etc/sudoers.d/gary
chmod 440 /etc/sudoers.d/gary

# to allow no-password sudo, add this to the end of '/etc/sudoers', using visudo
gary ALL=(ALL) NOPASSWD: ALL
```

## Change file/directory permissions

- Use capital `X` to add execute/seach permission only on directories, not files, this is effective when you want to add search permission ;

```sh
ls -l
# total 4
# -rw-rw-r-- 1 gary gary    0 Nov  7 19:58 a-file
# drw-rw-r-- 2 gary gary 4096 Nov  7 19:58 b-folder

chmod -R ug+X .
ls -l
# total 4
# -rw-rw-r-- 1 gary gary    0 Nov  7 19:58 a-file
# drwxrwxr-- 2 gary gary 4096 Nov  7 19:58 b-folder
```

### `setgid`

when set on a directory, make new files and directories created in it inherit the group id

```sh
ls -dl .
# drwxrwxr-x 2 gary gary 4096 Nov  7 20:03 .

chmod g+s .         # add setgid to current directory

ls -dl .
# drwxrwsr-x 2 gary gary 4096 Nov  7 20:04 .

sudo touch newfile
sudo mkdir newfolder

ls -dl . newfile newfolder
# drwxrwsr-x 3 gary gary 4096 Nov  7 20:18 .
# -rw-r--r-- 1 root gary    0 Nov  7 20:05 newfile
# drwxr-sr-x 2 root gary 4096 Nov  7 20:18 newfolder
```

- `newfile` inherits its group `gary` from the parent folder;
- `newfolder` inherits its group `gary`, its `setgid` bit is set as well;

### sticky bit

```sh
ls -adl /tmp/
# drwxrwxrwt 5 root root 4096 Dec  6 12:32 /tmp/

# add a sticky bit to a directory
chmod +t mydir
```

- the `t` bit above indicates that files in this folder can only be renamed or deleted by the file owner or the super user;
- it's a good practice to add it for world-writable directories;

## Find out Linux distribution name

```sh
ls /etc/*release*
# /etc/lsb-release  /etc/os-release

cat /etc/os-release
# NAME="Ubuntu"
# VERSION="12.04.2 LTS, Precise Pangolin"
# ID=ubuntu
# ID_LIKE=debian
# PRETTY_NAME="Ubuntu precise (12.04.2 LTS)"
# VERSION_ID="12.04"
```

## Find module version

```sh
strings modulename.so | grep "modulename/[0-9]\.[0-9]"
```

## Disable a service from autostart

```sh
sudo update-rc.d nginx disable
```

## Display IP address in shell prompt

add following line to `~/.bashrc`

```sh
MYIP=`ifconfig eth0 | sed -nr 's/^ *inet addr:([0-9.]+) .*$/\1/p'`
export PS1="\u@$MYIP:\w\$ "
```

## Mount/Unmount device

```sh
mount           # show mounted devices
# ...
# //Administrator@192.168.88.3/data on /mnt/data (smbfs)

# create a mount point and mount a network share to it
sudo mkdir -p /mnt/data
sudo mount -t smbfs //Administrator@192.168.88.3/data  /mnt/data

# unmount whatever is mounted at this point
sudo umount /mnt/data
```

- system default mounts are stored in `/etc/fstab`;
- current mounts are in `/etc/mtab`;
- you can specify mount options using `-o`, options available are different for each file system type;

### `cifs`

```sh
# for cifs, specify server user, client uid/gid, file_mode and dir _mode
USER=Administrator mount -o uid=dockeruser,gid=dockeruser,file_mode=0770,dir_mode=0700 //192.168.88.3/data /home/dockeruser/test/mpoint
```

- CIFS is commonly supported in Linux by the cifs module in the kernel;
- If the server does not suppport Unix Extension, then all the files/folders under the mount point are getting user/group and permissions from the mount options, and you can't `chown` or `chmod` after the device is mounted;
- For detailed info, check `man mount.cifs`;

## Relabel usb hard drive

reference: [RenameUSBDrive]

```sh
# find the usb drive
sudo fdisk -l

# unmount the drive
sudo umount /dev/sdc1

# IMPORTANT: 'ntfslabel' is for renaming ntfs drive, for drive of other filesystem, check the reference
# check current label
sudo ntfslabel /dev/sdc1
# My Passport

# change the label
sudo ntfslabel /dev/sdc1 my_passport

# unplug the drive, then plug it again, check the label
sudo blkid
# ...
# /dev/sdc1: LABEL="my_passport" UUID="4E1AEA7B1AEA6007" TYPE="ntfs"
```

## Hide default folders in home directory in Ubuntu

Ubuntu will create some folders in a user's home directory, such as 'Desktop', 'Music', etc

you can change these folders location by editting `~/.config/user-dirs.dirs`

## Send email

use `ssmtp` to send mail

compose message in `msg.txt`:

    To: jack@gmail.com
    Subject: hi

    hello world!

send mail:

```sh
ssmtp jack@gmail.com < msg.txt
```

## Work with ps or pdf files

make a ps(PostScript) file from text

```sh
enscript -p syslog.ps /var/log/syslog
# [ 2 pages * 1 copy ] left in syslog.ps
# 38 lines were wrapped
```

convert ps to pdf

```sh
ps2pdf syslog.ps

pdfinfo syslog.pdf
#     Title:          Enscript Output
#     Creator:        GNU Enscript 1.6.5.90
#     Producer:       GPL Ghostscript 9.10
#     CreationDate:   Mon Aug 11 11:51:07 2014
#     ModDate:        Mon Aug 11 11:51:07 2014
#     Tagged:         no
#     Form:           none
#     Pages:          2
#     Encrypted:      no
#     Page size:      612 x 792 pts (letter)
#     Page rot:       0
#     File size:      5016 bytes
#     Optimized:      no
#     PDF version:    1.4
```

Rotate and combine PDF pages

```sh
# install pdftk
sudo snap install pdftk

# rotate every page in a.pdf, the up side rotates to the left (90 degres anticlockwise)
pdftk a.pdf cat 1-endleft output rotated.pdf

# get page 1,2 rotated upside down from a.pdf, and add page 1 of b.pdf
pdftk A=a.pdf B=b.pdf cat A1-2down B1 output combined.pdf
```

## SSH login without password

login from `a@A` to `b@B` using ssh withoud password, ref: http://www.linuxproblem.org/art_9.html

```
a@A:~> ssh-keygen -t rsa
a@A:~> ssh b@B mkdir -p .ssh
b@B's password:

a@A:~> cat .ssh/id_rsa.pub | ssh b@B 'cat >> .ssh/authorized_keys'
b@B's password:

# you may need to change some permissions (e.g. this is a must on CentOS 6)
b@B:~> chmod 700 .ssh
b@B:~> chmod 640 .ssh/authorized_keys

# then no password, hooray!
a@A:~> ssh b@B
```

simple:

```
$ ssh-copy-id b@B
```

## Version number specifications

when you work with `npm` or `composer`, you may encounter various version numbers, refer to:

```sh
npm help 7 semver
```

## Lorem ipsum

placeholder text generator, install a perl module `libtext-lorem-perl` and use the `lorem` command

```sh
sudo apt-get install libtext-lorem-perl
lorem
```

## Extract media from Office files (docx,xlsx,pptx)

[ref](http://www.howtogeek.com/50628/easily-extract-images-text-and-embedded-files-from-an-office-2007-document/)

A `docx` file is actually a compressed zip file, so we just need to copy that file as a zip file, and then extract it, all media files are in `word/media/`

```sh
cp a.docx the-doc.zip

unzip the-doc.zip
# Archive:  the-doc.zip
#     inflating: [Content_Types].xml
#     inflating: _rels/.rels
# ...

ls
# a.docx  [Content_Types].xml  docProps  _rels  the-doc.zip  word

ls word/media/
# image10.png  image17.png
# ...
```

## Package files

```sh
ls -A -1 * .*
# .secret
# top.txt
# top.zip
#
# foo:
# .secret
# bar
# sub.zip

# package and ignore these files/folders
#   all *.zip files
#   any .secret file
#   all bar/ folders
tar czf /tmp/test.tgz --exclude '*.zip' --exclude '.secret' --exclude 'bar/'  ./

# list result
tar tzf /tmp/test.tgz
./
./foo/
./top.txt
```

## Download all images from a web page

```sh
wget --page-requisites --span-hosts --no-directories --accept jpg,png --execute robots=off --domains="images.example.com"  'http://example.com/page1'
```

- `--page-requisites` get image files, by default, `wget` do not download images in `<img />` tag
- `--span-hosts` download from other hosts
- `--no-directories` do not create separate directory
- `robots=off` do not follow rules in `robots.txt`
- `--domains` specify which domains to download files from
- `--accept` what file types to download

## Linux process management

- `pgrep -a chrome` find processes using RegExp matching
- `lsof -i:8080` list processes listening on port 8080 (`lsof` means list open files)
- `pstree` display a process tree
- `htop` an interactive version of `top`

### `kill`

See `man 7 signal` for a full signal list

- `kill <PID>`

  send the `TERM` (a.k.a `-15`) signal to the process, a soft kill;

- `kill -9 <PID>`

  `SIGKILL`, terminate immediately/hard kill;

### `pgrep`, `pkill`

Find or send signals to processes based on name or other attributes

```sh
pgrep -a zsh

# 5150 /usr/bin/zsh
# 6901 /usr/bin/zsh
# 25781 /bin/zsh

pkill -9 -e node    # send a signal to processes matching 'node' and echo the result
# node killed (pid 30604)
```


## Limit Google Chrome memory usage

**Seems like this limit only applies to the initial page load, a tab can exceed this limit later on**, see the `cgroup` section

```sh
# limit per tab memory usage to be 200MB
google-chrome --js-flags='--max-old-space-size=200'
```

## Chrom DevTools

- Filter out extension resources in the 'Network' tab:

  `-scheme:chrome-extension`

- In the console, use `Shift + Enter` to enter multiple lines of code;

## Limit memory/cpu usage using cgroups

- [cgroups - ArchWiki](https://wiki.archlinux.org/index.php/cgroups)
- [cgroup - Install cgconfig in Ubuntu 16.04 - Ask Ubuntu](https://askubuntu.com/questions/836469/install-cgconfig-in-ubuntu-16-04)
- [using cgroups to limit browser memory+cpu usage](https://gist.github.com/hardfire/7e5d9e7ce218dcf2f510329c16517331)

cgroups can be used to limit a process groups resource(memory/cpu/...) usage

- Install tools

  ```sh
  sudo apt-get install cgroup-tools
  ```

- Create config files

  ```
  # /etc/cgconf.conf

  group chrome {
      perm {
          admin {
              uid = gary;
          }
          task {
              uid = gary;
          }
      }

      cpu {
          cpu.shares = "1000";  # 1000 out of 1024
      }

      memory {
          memory.limit_in_bytes = "1000M";
      }
  }
  ```

  ```
  # /etc/cgrules.conf

  #user:process                            subsystems          groups
  gary:/opt/google/chrome/chrome           cpu,memory          chrome
  ```

  ```
  # /etc/init.d/cgconf

  # ... as in the gist
  ```

- Install and enable the service

  ```
  # make the script executable
  chmod 755 /etc/init.d/cgconf

  # register the service
  sudo update-rc.d cgconf defaults

  # start the service
  sudo /etc/init.d/cgconf start

  # check the status
  sudo /etc/init.d/cgconf status
  ```

- Then the cgroup should be applied when the system starts

## `resolve.conf`

  ```
  search a.com b.com
  nameserver 172.24.16.11
  nameserver 10.10.39.65
  # domain gary.com
  ```

  If you try to query a non FQDN, such as `app`, then it will append domains in the `search` line to it, so it will query `app.a.com`, `app.b.com` in turn;

  `domain` directive is obsolete, replaced by `search`

## Search files (grep)

`ripgrep` is a popular `grep` alternative, it's fast, searchs recursively, ignoring files in `.gitignore` by default

```sh
# search 'foo' in markdown files, show 2 lines context above and below the match
rg -tmd -C2 foo

# see default file type extensions
rg --type-list
```

## Hash

```sh
sha1sum test.txt
# 22596363b3de40b06f981fb85d82312e8c0ed511  test.txt

# checking
sha1sum --check checksum
# test.txt: OK

# can be done with openssl command as well
openssl sha1 test.txt
# SHA1(test.txt)= 22596363b3de40b06f981fb85d82312e8c0ed511
```

`sha1sum` takes any data and produces a 160-bit (40 hexadecimal) output

- Non-revertible - can't get input from output
- Collision resistant - hard to find two input producing same output
- Git uses SHA1 to get a hash for each object (file, tree or commit)

Similar commands, `sha256sum`, `sha384sum` and `sha512sum`, they produce 256-bit, 384-bit and 512-bit hashes respectively.


## Self-signed SSL certs


```sh
# Create CA cert and key

# Generate private key
openssl genrsa -des3 -out gary_ca.key 2048

# Generate root certificate
openssl req -x509 -new -nodes -key gary_ca.key -sha256 -days 825 -out gary_ca.pem
```

```sh
# Create self-signed cert

NAME=$1 # 'localhost' or 'gary.local', or '*.gary.local"

# Generate a private key
openssl genrsa -out $NAME.key 2048

# Create a certificate-signing request
openssl req -new -key $NAME.key -out $NAME.csr

# Create a config file for the extensions
cat > $NAME.ext <<-EOF
	authorityKeyIdentifier=keyid,issuer
	basicConstraints=CA:FALSE
	keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
	subjectAltName = @alt_names
	[alt_names]
	DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
	EOF

# Create the signed certificate
openssl x509 -req \
  -CA gary_ca.pem \
  -CAkey gary_ca.key \
  -CAcreateserial \
  -days 825 \
  -sha256 \
  -in $NAME.csr \
  -extfile $NAME.ext \
  -out $NAME.crt
```

If you want to create a wildcard certificate, use `*.gary.local` as `$NAME`, and use it when prompted for `CN` (it needs to be a properly-structured domain, something like `*.local` is not working in Chrome)

## DNS tools

```sh
# query A records of example.com using server 8.8.8.8
dig @8.8.8.8 example.com

# get name server of a domain
dig example.com ns
```





[RenameUSBDrive]: [https://help.ubuntu.com/community/RenameUSBDrive]