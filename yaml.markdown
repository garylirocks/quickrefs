# YAML

## List and object (associative array)

```yaml
--- # a list of 3 elements, each is an object
- name: Mary Smith
  age: 27
- {name: John Smith, age: 33}   # inline object
- [name, age]: [Rae Smith, 4]   # sequences as keys are supported

--- # an object with 2 keys, each is a list
women:
  - Mary Smith
  - Susan Williams
men: [John Smith, Bill Jones]   # inline list
```

## Syntax example

```yaml
--- # favorite movies
- Casablanca
- North by Northwest
- The Man Who Wasn't There

--- # a full example
receipt:     Oz-Ware Purchase Invoice
date:        2012-08-06
customer:
    first_name:   Dorothy
    family_name:  Gale

items:
    - part_no:   A4786
      descrip:   Water Bucket (Filled)
      price:     1.47
      quantity:  4

    - part_no:   E1628
      descrip:   High Heeled "Ruby" Slippers
      size:      8
      price:     133.7
      quantity:  1

bill-to:  &id001
    street: |
            123 Tornado Alley
            Suite 16
    city:   East Centerville
    state:  KS

ship-to:  *id001

specialDelivery:  >
    Follow the Yellow Brick
    Road to the Emerald City.
    Pay no attention to the
    man behind the curtain.
...
```

- Three hyphens `---` separate documents in a single stream
- Three periods `...` optionally ends a document in a stream
- `items` is a 2-element list, each element is an associative array
- `&` and `*` are for anchors and references

## Multiple lines

To make a long line easier to read and edit, you could break it into multiple lines,

  - `|` keeps trailing spaces and new lines, `>` folds newlines to spaces.
  - In either case, indentation is ignored.

```yaml
include_newlines: |
            exactly as you see
            will appear these three
            lines of poetry

fold_newlines: >
            this is really a
            single line of text
            despite appearances
```


## Gochas

- Most of the time you don't need to quote a string value, but there are exceptions
  - A colon followed by a space or at the end of a line

    ```yaml
    foo: 'a colon followed with a space : here'
    bar: 'a colon at the end of the line c:'
    ```

- Double quotes support escapse sequences, single quotes don't

    ```yaml
    foo: "a TAB \t and a newline \n"
    bar: 'a single quote \' here'
    ```
