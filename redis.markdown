Redis
===============

- [CLI test](#cli-test)

## CLI test

```sh
# start server in background mode
redis-server &

# connet to the server
redis-cli

redis 127.0.0.1:6379> set name gary
# OK
redis 127.0.0.1:6379> get name
# "gary"
```
