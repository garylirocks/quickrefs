# Ubuntu Package Management

## Query package info

```bash
# while package is not installed
apt-cache show sendmail

# while a package have already been installed
dpkg --status sendmail

# find which package provided a command
dpkg -S `which exiv2`
```

find files installed by a package

```bash
dpkg -L python-mysqldb | head
```

outputs

```
/.
/usr
/usr/lib
/usr/lib/pyshared
/usr/lib/pyshared/python2.6
/usr/lib/pyshared/python2.6/_mysql.so
/usr/share
/usr/share/doc
/usr/share/doc/python-mysqldb
/usr/share/doc/python-mysqldb/HISTORY
```
