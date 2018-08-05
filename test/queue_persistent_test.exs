defmodule QueuePersistentTest do
  use ExUnit.Case
  doctest QueuePersistent

  test "greets the world" do
    assert QueuePersistent.hello() == :world
  end
end
