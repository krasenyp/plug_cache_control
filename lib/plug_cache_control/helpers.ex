defmodule PlugCacheControl.Helpers do
  @moduledoc """
  Contains helper functions for working with cache-control header on Plug
  connections.
  """

  alias Plug.Conn
  alias PlugCacheControl.Header

  @typep unit ::
           :second
           | :seconds
           | :minute
           | :minutes
           | :hour
           | :hours
           | :day
           | :days
           | :week
           | :weeks
           | :year
           | :years

  @typep delta(t) :: {t, integer | {integer(), unit()}}
  @typep flag(t) :: t | {t, boolean()}

  @typep flag_directive ::
           :must_revalidate
           | :no_cache
           | :no_store
           | :no_transform
           | :proxy_revalidate
           | :private
           | :public

  @typep delta_directive :: :max_age | :s_maxage | :stale_while_revalidate | :stale_if_error

  @type directive_opt :: flag(flag_directive) | delta(delta_directive) | {:no_cache, String.t()}

  @doc """
  Serializes the cache control directives and sets them on the connection,
  overwriting the existing header value.
  """
  @spec put_cache_control(Conn.t(), [directive_opt()]) :: Conn.t()
  def put_cache_control(conn, directives) do
    value =
      directives
      |> directives_to_map()
      |> Header.new()
      |> Header.to_string()

    Conn.put_resp_header(conn, "cache-control", value)
  end

  @doc """
  Merges directives into the current value of the `cache-control` header.
  """
  @spec patch_cache_control(Conn.t(), [directive_opt()]) :: Conn.t()
  def patch_cache_control(conn, directives) do
    new_value =
      conn
      |> Conn.get_resp_header("cache-control")
      |> List.first("")
      |> merge_cache_control_value(directives)

    Conn.put_resp_header(conn, "cache-control", new_value)
  end

  defp merge_cache_control_value(value, directives) when is_binary(value) do
    current = map_from_header(value)
    updated = directives_to_map(directives)

    current
    |> Map.merge(updated)
    |> Header.new()
    |> Header.to_string()
  end

  defp directives_to_map(directives) do
    mapper = fn
      {key, _} = tuple when is_atom(key) ->
        tuple

      key when is_atom(key) ->
        {key, true}
    end

    directives
    |> Enum.map(mapper)
    |> Enum.into(%{})
  end

  defp map_from_header(str) when is_binary(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.split(&1, "=", trim: true))
    |> Enum.map(fn
      [key] -> {directive_to_atom(key), true}
      [key, value] -> {directive_to_atom(key), value}
    end)
    |> Enum.into(%{})
  end

  defp directive_to_atom(directive) when is_binary(directive) do
    directive
    |> camel_to_snake_case()
    |> String.to_existing_atom()
  end

  defp camel_to_snake_case(str) do
    String.replace(str, "-", "_")
  end
end
