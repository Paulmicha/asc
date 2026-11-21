# Graphviz ER fixture

Legend and a small editorial slice.
Primary entities are ellipses (`#ffffcc`), classifications are boxes (`#d4e1f5`),
nested entities are ellipses (`#ffcc99`).

## Visual language

```dot
digraph legend {
  rankdir=LR;
  graph [bgcolor="transparent"];
  node [fontname="Source Sans 3", fontsize=11, color="#000000"];
  edge [fontname="Source Sans 3", fontsize=9, color="#000000", arrowhead=normal];

  ct [label="Primary entity", shape=ellipse, style=filled, fillcolor="#ffffcc"];
  tax [label="Classification", shape=box, style=filled, fillcolor="#d4e1f5"];
  pg [label="Nested entity", shape=ellipse, style=filled, fillcolor="#ffcc99"];
  rel [label="Relation linking entity", shape=ellipse, style=filled, fillcolor="#ffcce6"];

  ct -> tax [label="reference field"];
  ct -> pg [label="reference field"];
}
```

## Editorial content (sample)

```dot
digraph editorial {
  rankdir=TB;
  graph [bgcolor="transparent"];
  node [fontname="Source Sans 3", fontsize=11, color="#000000"];
  edge [fontname="Source Sans 3", fontsize=9, color="#000000", arrowhead=normal];

  subgraph cluster_ct {
    label="Primary entities";
    style=rounded;
    ct_article [label="Article", shape=ellipse, style=filled, fillcolor="#ffffcc"];
    ct_author [label="Author", shape=ellipse, style=filled, fillcolor="#ffffcc"];
  }
  subgraph cluster_tx {
    label="Classifications";
    style=rounded;
    tax_article_categorie [label="Article category", shape=box, style=filled, fillcolor="#d4e1f5"];
  }
  subgraph cluster_pg {
    label="Nested entities";
    style=rounded;
    pg_wysiwyg [label="Body", shape=ellipse, style=filled, fillcolor="#ffcc99"];
    pg_push_info [label="Sidebar", shape=ellipse, style=filled, fillcolor="#ffcc99"];
  }

  ct_article -> ct_author [label="Author"];
  ct_article -> tax_article_categorie [label="Categories"];
  ct_article -> pg_wysiwyg [label="Body"];
  ct_article -> pg_push_info [label="Sidebar"];
}
```
