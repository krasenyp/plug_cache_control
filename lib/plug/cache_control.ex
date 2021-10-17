defmodule Plug.CacheControl do
  @moduledoc """
  A plug for overwriting the default `cache-control` header.
  """

  @behaviour Plug

  alias Plug.CacheControl.Helpers

  @typep dynamic_opt :: {:dynamic, function()}
  @typep default_opt :: {:default, list()}
  @type opt :: dynamic_opt() | default_opt()

  @spec init([opt]) :: [function()]
  def init(opts) do
    defaults = %{dynamic: nil, default: []}

    case Enum.into(opts, defaults) do
      %{dynamic: fun, default: nil} when is_function(fun, 2) ->
        [fun]

      %{dynamic: nil, default: clauses} ->
        [fn _ -> clauses end]

      _ ->
        raise ArgumentError, "Provide either a default or a dynamic option."
    end
  end

  @spec call(Plug.Conn.t(), [function()]) :: Plug.Conn.t()
  def call(%Plug.Conn{} = conn, [fun]) do
    Helpers.put_cache_control(conn, fun.(conn))
  end

  def call(conn, _opts), do: conn
end
