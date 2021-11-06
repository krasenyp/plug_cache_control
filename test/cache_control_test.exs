defmodule PlugCacheControlTest do
  use PlugCacheControl.ConnCase

  alias PlugCacheControl

  test "puts flag directives correctly", %{conn: conn} do
    opts =
      PlugCacheControl.init(directives: [:public, :no_cache, :must_revalidate, no_cache: false])

    header = conn |> PlugCacheControl.call(opts) |> cache_control_header()

    assert header =~ "public"
    assert header =~ "must-revalidate"
    refute header =~ "no-cache"
  end

  test "puts delta directives correctly", %{conn: conn} do
    opts = PlugCacheControl.init(directives: [max_age: {1, :hour}, s_maxage: 360])
    header = conn |> PlugCacheControl.call(opts) |> cache_control_header()

    assert header =~ "max-age=3600"
    assert header =~ "s-maxage=360"
  end

  test "puts no_cache fields correctly", %{conn: conn} do
    opts = PlugCacheControl.init(directives: [no_cache: ["id", "name"]])
    header = conn |> PlugCacheControl.call(opts) |> cache_control_header()

    assert header =~ "no-cache=\"id, name\""
  end

  test "raises on non-existent directive", %{conn: conn} do
    opts = PlugCacheControl.init(directives: [:nonexistent])

    assert_raise ArgumentError, fn ->
      conn
      |> PlugCacheControl.call(opts)
      |> cache_control_header()
    end
  end

  test "raises on invalid value for directive", %{conn: conn} do
    argument_error(conn, directives: [max_age: "3600"])

    argument_error(conn, directives: [max_age: {"1", :hour}])

    argument_error(conn, directives: [max_age: {1, :moment}])

    argument_error(conn, directives: [public: "true"])
  end

  defp argument_error(conn, directives: dir) do
    assert_raise ArgumentError, fn ->
      opts = PlugCacheControl.init(directives: dir)

      conn |> PlugCacheControl.call(opts) |> cache_control_header()
    end
  end
end
