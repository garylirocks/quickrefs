# JSON query tools

- [Overview](#overview)
- [`jq`](#jq)


## Overview

There are various CLI tools which could be used to query, transform JSON data.


## `jq`

Command line JSON processor

Use an example JSON file `example.json`

```json
{
  "name": {
    "first": "Gary",
    "last": "Li"
  },
  "fruits": [
    "apple",
    "banana",
    "kiwifruit"
  ]
}
```

```sh
# default, output as JSON
jq '.name.first' example.json
# "Gary"

# output raw text
jq -r '.name.first' example.json
# Gary

# array element
jq -r '.fruits[1]' example.json
# banana

# get object keys
jq ".name | keys[]" example.json
# "first"
# "last"
```

Format JSON text:

```sh
echo '{"name": {"first": "Gary", "last": "Li"}}' | jq .
# {
#   "name": {
#     "first": "Gary",
#     "last": "Li"
#   }
# }
```
