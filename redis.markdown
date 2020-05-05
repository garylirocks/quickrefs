# Redis

- [CLI test](#cli-test)
  - [Common operations](#common-operations)
  - [Expire time / TTL](#expire-time--ttl)
- [Data types](#data-types)
  - [List](#list)
  - [Hash](#hash)

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

### Common operations

```sh
exists name
# (integer) 1

type name
# string

del name
# (integer) 1

exists name
# (integer) 0
```

### Expire time / TTL

```sh
# set TTL in seconds
expire name 20
# (integer) 1

# get TTL
ttl name
# (integer) 17
```

## Data types

- String
- List
- Hash
- Set
- Sorted Set
- ...

### List

- Redis lists are linked lists, not arrays, so it's fast to add/remove elements from the head/tail of the list;
- Slow to access elements in the middle;
- Use cases:
  - Keep latest 10 posts in a social network;
  - Pub / Sub;

```sh
rpush mylist A
# (integer) 1

rpush mylist B
# (integer) 2

lpush mylist first second
# (integer) 3

lrange mylist 0 -1    # first to last
# 1) "first"
# 2) "A"
# 3) "B"

lpop mylist           # pop out
# "first"
```

Capped list

```sh
rpush mylist A B C D
# (integer) 4

ltrim mylist 0 1      # only keep the first two elements
# OK

lrange mylist 0 -1
# 1) "A"
# 2) "B"
```

### Hash

```sh
hmset me name gary age 20
# OK

hget me age
# "20"

hmget me name age
# 1) "gary"
# 2) "20"

hgetall me
# 1) "name"
# 2) "gary"
# 3) "age"
# 4) "20"

hincrby me age 5
# (integer) 25
```
