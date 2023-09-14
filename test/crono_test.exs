defmodule CronoTest do
  use ExUnit.Case

  doctest Crono

  test "greets the world" do
    assert Crono.hello() == :world
  end
end
