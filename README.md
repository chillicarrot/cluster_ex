# ClusterEx

## Example

```
  points = [
    {"P1",{1, 2}},
    {"P2",{1, 3}},
    {"P3",{2, 3}},
    {"P4",{2, 3}},
    {"P5",{2, 4}},
    {"P6",{1, 4}},
    {"P7",{2, 5}},
    {"P8",{2, 3}},
    {"P9",{3, 3}},
    {"P10",{4, 2}},
    {"P11",{1, 2}}
  ]
  ClusterEx.cluster(points, 3)
```

## Installation

The package can be installed by adding `cluster_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:cluster_ex, "~> 0.1.0"}]
end
```
The docs can be found at [https://hexdocs.pm/cluster_ex](https://hexdocs.pm/cluster_ex).

