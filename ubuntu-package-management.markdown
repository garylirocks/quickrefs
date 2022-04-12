# Ubuntu Package Management

## Query package info

```bash
# while package is not installed
apt-cache show sendmail

# while a package have already been installed
dpkg --status sendmail
```

Find which package provided a command

```sh
dpkg -S `which az`
# azure-cli: /usr/bin/az
```

Find files installed by a package

```bash
dpkg -L python-mysqldb | head

# /.
# /usr
# ...
# /usr/lib/pyshared/python2.6
# /usr/lib/pyshared/python2.6/_mysql.so
# ...
# /usr/share/doc/python-mysqldb/HISTORY
```


## Package versions

```sh
# list available versions
apt list -a my-package

# install a paticular version, it would overwrite the existing version
sudo apt install my-package=2.28.0-1~focal
```
