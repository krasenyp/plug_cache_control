defmodule Plug.CacheControl.Helpers do
  @moduledoc """
  Contains helper functions for working with cache-control header on Plug
  connections.
  """

  alias Plug.CacheControl.Header
  alias Plug.Conn

  @type unit ::
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
  @type duration :: {integer(), unit()}

  @doc """
  Sets a period after which the response should be considered stale.
  """
  @spec expires_in(Conn.t(), integer() | duration(), Enum.t()) :: Conn.t()
  def expires_in(%Conn{} = conn, duration, opts \\ []) do
    set_expires_in(conn, duration, opts)
  end

  defp set_expires_in(conn, seconds, opts) when is_integer(seconds) and seconds >= 0 do
    set_expires_in(conn, {seconds, :seconds}, opts)
  end

  defp set_expires_in(conn, {_, _} = duration, opts) do
    opts =
      opts
      |> normalize_opts()
      |> Keyword.put(:max_age, duration)

    patch_header_value(conn, opts)
  end

  @doc """
  Marks the response as stale from the get-go.
  """
  @spec expires_now(Conn.t(), Enum.t()) :: Conn.t()
  def expires_now(%Conn{} = conn, opts \\ []) do
    set_expires_now(conn, opts)
  end

  defp set_expires_now(conn, opts) do
    opts =
      opts
      |> normalize_opts()
      |> Keyword.put(:max_age, 0)

    patch_header_value(conn, opts)
  end

  @doc """
  Sets an expiration period of 100 years.
  """
  @spec cached_forever(Conn.t(), Enum.t()) :: Conn.t()
  def cached_forever(%Conn{} = conn, opts \\ []) do
    opts =
      opts
      |> normalize_opts()
      |> Keyword.put(:max_age, {100, :years})

    patch_header_value(conn, opts)
  end

  @doc """
  Marks the response as uncacheable.
  """
  @spec cached_never(Conn.t()) :: Conn.t()
  def cached_never(%Conn{} = conn) do
    put_cache_control(conn, [:no_store])
  end

  @doc """
  Serializes the cache control clauses and sets them on the connection.
  """
  @spec put_cache_control(Conn.t(), [any()]) :: Conn.t()
  def put_cache_control(conn, clauses) do
    value =
      clauses
      |> normalize_opts()
      |> Header.new()
      |> Header.to_string()

    Conn.put_resp_header(conn, "cache-control", value)
  end

  defp patch_header_value(conn, opts) do
    value =
      conn
      |> Conn.get_resp_header("cache-control")
      |> List.first("")
      |> Header.from_string()
      |> Header.put_many(opts)
      |> Header.to_string()

    Conn.put_resp_header(conn, "cache-control", value)
  end

  defp normalize_opts(opts) when is_list(opts) do
    mapper = fn
      {key, _} = tuple when is_atom(key) ->
        tuple

      key when is_atom(key) ->
        {key, true}

      other ->
        raise ArgumentError, "Options' names must be atoms, got: #{inspect(other)}"
    end

    :lists.map(mapper, opts)
  end
end
