# Quick Recipes

Quick productivity tips, shortcuts, command line snippets.

- [Shortcuts](#shortcuts)
  - [Ubuntu](#ubuntu)
- [Update keyboard layout](#update-keyboard-layout)
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
  - [Kill a process](#kill-a-process)

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

## Update keyboard layout

[treat the `CapsLock` key as `Ctrl`](http://askubuntu.com/a/633539)

To permanently change the behaviour:

- run `dconf-editor`
- select `org.gnome.desktop.input-sources`
- Change `xkb-options` to `['ctrl:nocaps']` (or add it to any existing options)

OR

on the command line (Warning -- this overwrites your existing settings!):

```sh
gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
```

OR

see method at this link: http://askubuntu.com/a/633539

```sh
sudo vi /etc/default/keyboard

# edit the XKBOPTIONS line as below
# XKBOPTIONS="ctrl:swapcaps"

sudo dpkg-reconfigure keyboard-configuration
```

## Add a user as sudoer

add the user to the `sudo` group

```sh
# login as root, add gary to the sudo group
usermod -a -G sudo gary

# login as gary, confirm it had been added to the sudo group
id
# uid=1000(gary) gid=1000(gary) groups=1000(gary),27(sudo)

# crete a file in /etc/sudoers.d/ with the same name of your username
echo "gary ALL=(ALL) ALL" > /etc/sudoers.d/gary
chmod 440 /etc/sudoers.d/gary
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
sudo mkdir -p /mnt/data
sudo mount -t smbfs //Administrator@192.168.88.3/data  /mnt/data

sudo ls /mnt/data
# ...

mount           # show mounted devices
# ...
# //Administrator@192.168.88.3/data on /mnt/data (smbfs)

sudo umount /mnt/data
```

- system default mounts are stored in `/etc/fstab`;
- current mounts are in `/etc/mtab`;
- you can specify mount options using `-o`, options available are different for each file system type;

### `cifs`

```sh
# for cifs, specify server user, client uid/gid, file_mode and dir _mode
USER=Administrator mount -o uid=dockeruser,gid=dockeruser,file_mode=0770,dir_mode=0700 //192.168.88.3/data /home/dockeruser/test/mpoint

# you can't chown or chmod after the device is mounted
```

- `cifs` is an implementation of `smb`, it's outdated, you should use `smb 2` or `smb 3` when possible (https://www.varonis.com/blog/cifs-vs-smb/)

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

# extract first page of a pdf file
pdftk A=syslog.pdf cat A1 output syslog-firstpage.pdf

# rotate pages of a pdf file
pdftk A=syslog.pdf cat A1-endright output syslog-rotated.pdf
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

- `lsof -i:8080` list processes listening on port 8080

### Kill a process

- `kill <PID>`

  send the `TERM` (a.k.a `-15`) signal to the process, a soft kill;

- `kill -9 <PID>`

  `SIGKILL`, terminate immediately/hard kill;

[RenameUSBDrive]: [https://help.ubuntu.com/community/RenameUSBDrive]
