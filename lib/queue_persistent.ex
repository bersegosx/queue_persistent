defmodule QueuePersistent do
  use Application

  def start(_type, _args) do
    QueuePersistent.Supervisor.start_link
  end

  defdelegate add(message),       to: QueuePersistent.Server
  defdelegate get,                to: QueuePersistent.Server
  defdelegate ack(message_id),    to: QueuePersistent.Server
  defdelegate reject(message_id), to: QueuePersistent.Server
end
