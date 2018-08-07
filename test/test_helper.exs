defmodule QueuePersistent.Test.Helpers do

  def start do
    Application.start(:que)
  end

  def reset do
    stop()
    Helpers.Mnesia.reset
    start()
    :ok
  end

  def stop do
    Helpers.capture_log(fn ->
      Application.stop(:que)
    end)
  end

end

ExUnit.start()
