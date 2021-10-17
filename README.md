# Plug.CacheControl

There are two methods of overwriting the default header value - static and
dynamic. The static method can be used by providing a `default` option to the
plug as shown below. The option's value must be a list of clauses and values if
there're not boolean clauses.

```
plug Plug.CacheControl, default: [:public, max_age: {1, :day}]
```

The dynamic method of setting a value to the `cache-control` header can be used
by providing a `dynamic` option to the plug as demonstrated below. The option's
value must be a unary function, taking a `Plug.Conn` as an argument and
returning a list of clauses.

```
plug Plug.CacheControl, dynamic: &SomeMod.get_dynamic_clauses/1
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `plug_cache_control` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plug_cache_control, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/plug_cache_control](https://hexdocs.pm/plug_cache_control).
