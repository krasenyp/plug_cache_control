defmodule Plug.CacheControl.ConnCase do
  use ExUnit.CaseTemplate

  alias Plug.Conn

  using do
    quote do
      import Plug.Conn
      import Plug.CacheControl.ConnCase
    end
  end

  setup tags do
    {:ok, conn: build_conn()}
  end

  def cache_control_header(%Conn{} = conn) do
    conn
    |> Conn.get_resp_header("cache-control")
    |> List.first()
  end

  @doc """
  Creates a connection to be used in upcoming requests.
  """
  @spec build_conn() :: Conn.t()
  defp build_conn() do
    build_conn(:get, "/", nil)
  end

  @doc """
  Creates a connection to be used in upcoming requests
  with a preset method, path and body.

  This is useful when a specific connection is required
  for testing a plug or a particular function.
  """
  @spec build_conn(atom | binary, binary, binary | list | map | nil) :: Conn.t()
  defp build_conn(method, path, params_or_body \\ nil) do
    Plug.Adapters.Test.Conn.conn(%Conn{}, method, path, params_or_body)
    |> Conn.put_private(:plug_skip_csrf_protection, true)
    |> Conn.put_private(:phoenix_recycled, true)
  end
end
