defmodule PlugCacheControlTest do
  use PlugCacheControl.ConnCase, async: true

  alias PlugCacheControl

  test "puts flag directives correctly", %{conn: conn} do
    {header, _} = apply_directives(conn, [:public, :no_cache, :must_revalidate, no_cache: false])

    assert header =~ "public"
    assert header =~ "must-revalidate"
    refute header =~ "no-cache"
  end

  test "puts delta directives correctly", %{conn: conn} do
    {header, _} = apply_directives(conn, max_age: {1, :hour}, s_maxage: 360)

    assert header =~ "max-age=3600"
    assert header =~ "s-maxage=360"
  end

  test "puts no_cache fields correctly", %{conn: conn} do
    {header, _} = apply_directives(conn, no_cache: ["id", "name"])

    assert header =~ "no-cache=\"id, name\""
  end

  test "applies dynamic directives correctly", %{conn: conn} do
    {header, _} = apply_directives(conn, fn _ -> [:public, :no_cache, :must_revalidate] end)

    assert header =~ "public"
    assert header =~ "no-cache"
    assert header =~ "must-revalidate"
  end

  test "calls dynamic directives function multiple times", %{conn: conn} do
    {:ok, pid} = Agent.start_link(fn -> 0 end)

    dyn_directives = fn _ ->
      Agent.update(pid, &(&1 + 1))

      [:public, :no_cache, :must_revalidate]
    end

    apply_directives(conn, dyn_directives)
    apply_directives(conn, dyn_directives)

    assert 2 = Agent.get(pid, & &1)
  end

  test "merges directives on subsequent calls", %{conn: conn} do
    {fheader, conn} = apply_directives(conn, [:public, :no_cache, :must_revalidate])

    assert fheader =~ "no-cache"

    {sheader, _} = apply_directives(conn, no_cache: false)

    refute sheader =~ "no-cache"
  end

  test "replaces directives on subsequent calls when configured", %{conn: conn} do
    {_, conn} = apply_directives(conn, [:public, :no_cache, :must_revalidate])
    {sheader, _} = apply_directives(conn, [max_age: 3600], replace: true)

    assert sheader =~ "max-age=3600"
    refute sheader =~ "public"
    refute sheader =~ "no-cache"
    refute sheader =~ "must-revalidate"
  end

  test "raises on non-existent directive", %{conn: conn} do
    assert_raise ArgumentError, fn ->
      apply_directives(conn, [:nonexistent])
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
      apply_directives(conn, dir)
    end
  end
end
