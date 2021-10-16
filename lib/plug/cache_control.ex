defmodule Plug.CacheControl do
  @moduledoc """
  A plug for overwriting the default `cache-control` header.

  There are two methods of overwriting the default header value - static and
  dynamic. The static method can be used by providing a `default` option to the
  plug as shown below. The option's value must be a list of clauses and values
  if there're not boolean clauses.

  ```
  plug Plug.CacheControl, default: [:public, max_age: {1, :day}]
  ```

  The dynamic method of setting a value to the `cache-control` header can be
  used by providing a `dynamic` option to the plug as demonstrated below. The
  option's value must be a unary function, taking a `Plug.Conn` as an argument
  and returning a list of clauses.

  ```
  plug Plug.CacheControl, dynamic: &SomeMod.get_dynamic_clauses/1
  ```
  """

  @behaviour Plug

  alias Plug.CacheControl.Helpers

  require Plug.CacheControl.Helpers

  @type dynamic_opt :: {:dynamic, function()}
  @type default_opt :: {:default, list()}

  @spec init([dynamic_opt | default_opt]) :: [{:fun, function()}]
  def init(opts) do
    defaults = %{dynamic: nil, default: []}

    case Enum.into(opts, defaults) do
      %{dynamic: fun, default: nil} when is_function(fun, 2) ->
        [fun: fun]

      %{dynamic: nil, default: clauses} ->
        [fun: fn _ -> clauses end]

      _ ->
        raise ArgumentError, "Provide either a default or a dynamic option."
    end
  end

  @spec call(Plug.Conn.t(), [{:fun, function()}]) :: Plug.Conn.t()
  def call(%Plug.Conn{method: method} = conn, fun: fun) when Helpers.is_cacheable(method) do
    Helpers.put_cache_control(conn, fun.(conn))
  end

  def call(conn, _opts), do: conn
end
