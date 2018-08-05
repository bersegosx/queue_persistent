defmodule QueuePersistent.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(QueuePersistent.Server, [])
    ]
    opts = [strategy: :one_for_one]

    supervise(children, opts)
  end

end
