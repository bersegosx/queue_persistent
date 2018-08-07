defmodule QueuePersistent.Test do
  alias QueuePersistent.Store.Database

  defmodule Helpers.App do
    @app :queue_persistent

    def start do
      Application.start(@app)
    end

    def reset do
      stop()
      Helpers.Mnesia.reset
      start()
    end

    def stop do
      Application.stop(@app)
    end
  end

  defmodule Helpers.Mnesia do
    def reset do
      Database.destroy
      Database.create
    end
  end

end

ExUnit.start()
