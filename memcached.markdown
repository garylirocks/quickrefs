# Memcached

- [Access it thru CLI](#access-it-thru-cli)

cheatsheet: http://lzone.de/cheat-sheet/memcached

## Access it thru CLI

```sh
telnet localhost 11211

# Trying 127.0.0.1...
# Connected to localhost.
# Escape character is '^]'.

set name 0 600 4
gary
# STORED

get name
# VALUE name 0 4
# gary
# END
```

in `set name 0 600 4`, `0` means no flags, `600` means expire time in seconds, `4` is the size in bytes
