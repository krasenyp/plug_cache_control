defmodule PlugCacheControl do
  @moduledoc """
  A plug + helpers for overwriting the default `cache-control` header. The plug
  supports all the response header directives defined in [RFC7234, section
  5.2.2](https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.2).

  ## Header directives

  The `PlugCacheControl` plug takes a `directives` option which can specify
  either _static_ or _dynamic_ header directives. Static directives are useful
  when you don't need per-request directives. Static directives are defined very
  similarly to a struct's key.

      plug PlugCacheControl, directives: [:public, max_age: {1, :hour}]

  As seen in the above example, directive names with hyphens are mapped to atoms
  by replacing the hyphens with underscores.

  Boolean directives like `public`, `private`, `must-revalidate`, `no-store` and
  so on can be included in the header value by simply including them in the
  directives list e.g. no need for explicit `no_store: true` value. Note that as
  per the standard, `no-cache` can also specify one or more fields. This is
  supported via the definition below.

      plug PlugCacheControl, directives: [no_cache: ["somefield", "otherfield"]]

  The `public` and `private` directives also have somewhat special handling so
  you won't need to explicitly define `private: false` when you've used
  `:public` in the "boolean section" of the directives list. Another important
  thing is that if a directive is not included in the directives list, the
  directive will be _omitted_ from the header's value.

  The values of the directives which have a delta-seconds values can be defined
  directly as an integer representing the delta-seconds.

      plug PlugCacheControl, directives: [:public, max_age: 3600]

  A unit tuple can also be used to specify delta-seconds. The supported time
  units are `second`, `seconds`, `minute`, `minutes`, `hour`, `hours`, `day`,
  `days`, `week`, `weeks`, `year`, `years`. The following example shows how unit
  tuples can be used as a conveniece to define delta-seconds.

      plug PlugCacheControl,
        directives: [
          :public,
          max_age: {1, :hour},
          stale_while_revalidate: {20, :minutes}
        ]

  Dynamic directives are useful when you might want to derive cache control
  directives per-request. Maybe there's some other header value which you care
  about or a dynamic configuration governing caching behaviour, dynamic
  directives are the way to go.

      plug PlugCacheControl, directives: &__MODULE__.dyn_cc/1

      # ...somewhere in the module...

      defp dyn_cc(_conn) do
        [:public, max_age: Cache.get(:max_age)]
      end

  As seen in the previous example, the only difference between static and
  dynamic directives definition is that the latter is a unary function which
  returns a directives list. The exact same rules that apply to the static
  directives apply to the function's return value.

  ## A note on behaviour

  The first time the plug is called on a connection, the existing value of the
  Cache-Control header is _replaced_ by the user-defined one. A private field
  which signifies the header value is overwritten is put on the connection
  struct. On subsequent calls of the plug, the provided directives' definitions
  are _merged_ with the header values. This allows the user to build up the
  Cache-Control header value.

  Of course, if one wants to replace the header value on a connection that has an
  already overwritten value, one can use the
  `PlugCacheControl.Helpers.put_cache_control` function or provide a `replace:
  true` option to the plug.

      plug PlugCacheControl, directives: [...], replace: true

  The latter approach allows for a finer-grained control and conditional
  replacement of header values.

      plug PlugCacheControl, [directives: [...], replace: true] when action == :index
      plug PlugCacheControl, [directives: [...]] when action == :show
  """

  @behaviour Plug

  alias Plug.Conn
  alias PlugCacheControl.Helpers

  @typep static :: Helpers.directive_opt()
  @typep dynamic :: (Plug.Conn.t() -> Helpers.directive_opt())

  @impl Plug
  @spec init([{:directives, static | dynamic}]) :: %{directives: dynamic}
  def init(opts) do
    opts
    |> Enum.into(%{})
    |> with_default_opts()
    |> validate_opts!()
  end

  @impl Plug
  @spec call(Conn.t(), %{directives: static() | dynamic()}) :: Conn.t()
  def call(conn, %{directives: fun}) when is_function(fun, 1) do
    call(conn, %{directives: fun.(conn)})
  end

  def call(%Conn{} = conn, %{directives: dir, replace: true}) do
    Helpers.put_cache_control(conn, dir)
  end

  def call(%Conn{private: %{cach_control_overwritten: _}} = conn, %{directives: dir}) do
    Helpers.merge_cache_control(conn, dir)
  end

  def call(%Conn{} = conn, %{directives: dir}) do
    Helpers.put_cache_control(conn, dir)
  end

  def call(conn, _opts), do: conn

  defp with_default_opts(opts) do
    default_opts = %{
      replace: false
    }

    Map.merge(default_opts, opts)
  end

  defp validate_opts!(%{directives: dir, replace: replace} = opts)
       when (is_list(dir) or is_function(dir, 1)) and is_boolean(replace) do
    opts
  end

  defp validate_opts!(_) do
    raise ArgumentError,
          "Provide a \"directives\" option with list of directives or a unary \
          function taking connection as first argument and returning a list of \
          directives."
  end
end
