Graphviz
=============

- [Simple graph](#simple-graph)
- [Graph with attributes](#graph-with-attributes)

## Simple graph

Put the following lines to simple.gv

```
graph simple
{
    a -- b --c;
    b -- d;
}
```

generate a graph using `dot`

```sh
dot -Tpng -O simple.gv
ls
# simple.gv  simple.gv.png
```

![Simple graph](./graph/simple.gv.png)

Use `->` for edges in directional graph:

```
digraph simple
{
    a -> b -> c;
    b -> d;
}
```


## Graph with attributes

```dot
digraph loop
{
    graph [bgcolor="#000000", label="A Loop", fontcolor="white"];

    a [color="green", label="start", fontcolor="white"];
    b [shape="circle", color="green", fontcolor="white"];
    c [shape="circle", color="green", fontcolor="white"];
    d [shape="circle", color="green", fontcolor="white"];
    e [shape="circle", color="green", fontcolor="white"];

    a -> b -> c -> d -> e [color="yellow", arrowhead="open"];
    e -> a [color="yellow", arrowhead="open", style="bold"];
}
```

result image:

![a loop](./graph/loop.gv.png)

