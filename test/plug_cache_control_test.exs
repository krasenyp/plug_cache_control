defmodule Plug.CacheControlTest do
  use ExUnit.Case
  doctest Plug.CacheControl

  test "greets the world" do
    assert Plug.CacheControl.hello() == :world
  end
end
