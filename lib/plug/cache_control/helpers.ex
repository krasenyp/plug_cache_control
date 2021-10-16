defmodule Plug.CacheControl.Helpers do
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
  Checks whether a connection method is cacheable according to the HTTP
  standard.
  """
  @spec is_cacheable(term()) :: Macro.t()
  defguard is_cacheable(method) when method in ["GET", "HEAD", "POST"]

  @spec expires_in(Conn.t(), integer() | duration(), Enum.t()) :: Conn.t()
  def expires_in(conn, duration, opts \\ [])

  def expires_in(%Conn{method: method} = conn, duration, opts) when is_cacheable(method) do
    set_expires_in(conn, duration, opts)
  end

  def expires_in(conn, _duration, _opts), do: conn

  defp set_expires_in(conn, seconds, opts) when is_integer(seconds) and seconds >= 0 do
    set_expires_in(conn, {seconds, :seconds}, opts)
  end

  defp set_expires_in(%Conn{} = conn, {_, _} = duration, opts) do
    opts =
      opts
      |> normalize_opts()
      |> Keyword.put(:max_age, duration)

    patch_header_value(conn, opts)
  end

  @spec expires_now(Conn.t(), Enum.t()) :: Conn.t()
  def expires_now(conn, opts \\ [])

  def expires_now(%Conn{method: method} = conn, opts) when is_cacheable(method) do
    set_expires_now(conn, opts)
  end

  def expires_now(conn, _opts), do: conn

  defp set_expires_now(%Conn{} = conn, opts) do
    opts =
      opts
      |> normalize_opts()
      |> Keyword.put(:max_age, 0)

    patch_header_value(conn, opts)
  end

  def cached_forever(%Conn{} = conn, opts) do
    opts =
      opts
      |> normalize_opts()
      |> Keyword.put(:max_age, {100, :years})

    patch_header_value(conn, opts)
  end

  def cached_never(%Conn{} = conn, _opts) do
    put_cache_control(conn, [:no_store, max_age: 0])
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
