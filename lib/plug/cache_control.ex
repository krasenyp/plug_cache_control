defmodule Plug.CacheControl do
  @moduledoc """
  A plug for overwriting the default `cache-control` header.
  """

  @behaviour Plug

  alias Plug.CacheControl.Helpers

  @impl Plug
  def init(opts), do: do_init(Enum.into(opts, %{}))

  defp do_init(%{directives: dir}) when is_list(dir) do
    %{directives: fn _ -> dir end}
  end

  defp do_init(%{directives: dir}) when is_function(dir, 2) do
    %{directives: dir}
  end

  defp do_init(_) do
    raise ArgumentError,
          "Provide a :directives option with list of directives or a unary \
          function taking connection as first argument and returning a list of \
          directives.."
  end

  @impl Plug
  def call(%Plug.Conn{} = conn, %{directives: dir}) do
    Helpers.put_cache_control(conn, dir.(conn))
  end

  def call(conn, _opts), do: conn
end
