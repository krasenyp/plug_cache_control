defmodule PlugCacheControl.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Plug.Conn

  using do
    quote do
      import Plug.Conn
      import PlugCacheControl.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: build_conn()}
  end

  def cache_control_header(%Conn{} = conn) do
    conn
    |> Conn.get_resp_header("cache-control")
    |> List.first()
  end

  defp build_conn do
    build_conn(:get, "/")
  end

  defp build_conn(method, path, params_or_body \\ nil) do
    Plug.Adapters.Test.Conn.conn(%Conn{}, method, path, params_or_body)
    |> Conn.put_private(:plug_skip_csrf_protection, true)
    |> Conn.put_private(:phoenix_recycled, true)
  end
end
