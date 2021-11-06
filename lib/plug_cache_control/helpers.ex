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
  Serializes the cache control directives and sets them on the connection.
  """
  @spec put_cache_control(Conn.t(), [directive_opt()]) :: Conn.t()
  def put_cache_control(conn, directives) do
    value =
      directives
      |> directives_to_keyword_list()
      |> Header.new()
      |> Header.to_string()

    Conn.put_resp_header(conn, "cache-control", value)
  end

  @doc """
  Merges directives into the current value of the `cache-control` header.
  """
  @spec merge_cache_control(Conn.t(), [directive_opt()]) :: Conn.t()
  def merge_cache_control(conn, directives) do
    current =
      conn
      |> Conn.get_resp_header("cache-control")
      |> List.first("")
      |> Header.from_string()

    updated =
      directives
      |> directives_to_keyword_list()
      |> Header.new()

    new =
      current
      |> Header.merge(updated)
      |> Header.to_string()

    Conn.put_resp_header(conn, "cache-control", new)
  end

  @spec directives_to_keyword_list([directive_opt()]) :: list()
  defp directives_to_keyword_list(directives) do
    mapper = fn
      {key, _} = tuple when is_atom(key) ->
        tuple

      key when is_atom(key) ->
        {key, true}

      other ->
        raise ArgumentError, "Options' names must be atoms but got #{inspect(other)}"
    end

    :lists.map(mapper, directives)
  end
end
