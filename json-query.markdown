# JSON query tools

- [Overview](#overview)
- [`jq`](#jq)
  - [Simple queries](#simple-queries)
  - [Format JSON](#format-json)
- [`jp` - JMESPath](#jp---jmespath)
  - [Query an object/directory:](#query-an-objectdirectory)
  - [Array operations](#array-operations)
  - [Array filtering](#array-filtering)


## Overview

There are various CLI tools which could be used to query, transform JSON data.

| Tool | Used by    |
| ---- | ---------- |
| `jp` | AZ CLI     |
| `jq` | GitHub CLI |


## `jq`

Command line JSON processor

### Simple queries

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

### Format JSON

```sh
echo '{"name": {"first": "Gary", "last": "Li"}}' | jq .
# {
#   "name": {
#     "first": "Gary",
#     "last": "Li"
#   }
# }
```


## `jp` - JMESPath

Use `jp` (https://github.com/jmespath/jp) on command line to try out expressions.

- Wrap string literals with **single quotes**

    ```sh
    jp -f x.json "people[? contains(name, 'Barney')]"
    ```

- Wrap number literals with **backticks** :

    ```sh
    jp -f x.json "[? age==`27`]"
    ```

- String comparing functions are **case-sensitive**, and seems there are no regular expression functions


### Query an object/directory:

```json
{
  "name": "Fred",
  "age": 28,
  "color": "red"
}
```

```sh
# single property
jp -c -f temp.json "name"
"Fred"

# multiple properties
jp -c -f temp.json "[name, color]"
["Fred","red"]

# rename multiple properties
jp -c -f temp.json "{A:name, B:color}"
{"A":"Fred","B":"red"}
```

### Array operations

Given an example JSON data like this:

```json
{
  "people": [
    {
      "name": "Fred",
      "age": 28
    },
    {
      "name": "Barney",
      "age": 25
    },
    {
      "name": "Wilma",
      "age": 27
    }
  ]
}
```

Some common expressions:

```sh
jp -c -f temp.json "people[1]"
# {"age":25,"name":"Barney"}

jp -c -f temp.json "people[1].name"
# "Barney"

jp -c -f temp.json "people[1:3].name"
# ["Barney","Wilma"]

jp -c -f temp.json "people[].name"
# ["Fred","Barney","Wilma"]

jp -c -f temp.json 'people[? age >= `27`].name'
# ["Fred","Wilma"]

jp -c -f temp.json "people[:1].{N: name, A: age}"
# [{"A":28,"N":"Fred"}]
```

### Array filtering

```json
[
  {
    "name": "Fred",
    "age": 28
  },
  {
    "name": "Barney",
    "age": 25
  },
  {
    "name": "Wilma",
    "age": 27
  }
]
```

Some common operations

```sh
jp -c -f temp.json "[?name == 'Fred']"
# [{"age":28,"name":"Fred"}]

jp -c -f temp.json "[?contains(name, 'F')]"
# [{"age":28,"name":"Fred"}]

jp -c -f temp.json "[? starts_with(name, 'F') || starts_with(name, 'B')].name"
# ["Fred","Barney"]

jp -c -f temp.json "[? starts_with(name, 'F') || starts_with(name, 'B')].name | sort(@) | {names: @}"
# {"names":["Barney","Fred"]}
```
