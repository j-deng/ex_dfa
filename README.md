# ExDfa

A simple DFA filter for sensitive words filter. 简单敏感词过滤Elixir版。

## Installation

Add `ex_dfa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_dfa, git: "https://github.com/j-deng/ex_dfa.git"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_dfa](https://hexdocs.pm/ex_dfa).

## Usage

build filter

```elixir
ExDfa.build_filter([{0, ["Fuck", "Fucku"]}, {1, ["傻逼", "傻帽"]}])

%{
  "f" => %{"u" => %{"c" => %{"k" => %{'0' => 0, "u" => %{'0' => 0}}}}},
  "傻" => %{"帽" => %{'0' => 1}, "逼" => %{'0' => 1}}
}
```

do filter

```elixir
ExDfa.do_filter(%{
  "F" => %{"u" => %{"c" => %{"k" => %{'0' => 0, "u" => %{'0' => 0}}}}},
  "傻" => %{"帽" => %{'0' => 1}, "逼" => %{'0' => 1}}
}, "你是大傻逼")

{:error, [1]}
```
