defmodule QueuePersistent.Server do
  @moduledoc false

  use GenServer
  use Amnesia

  alias QueuePersistent.Store.Database

  @name __MODULE__

  ## Client API

  def start_link(opts \\ []) do
    QueuePersistent.Store.init
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: @name])
  end

  def add(message) do
    call({:add, message})
  end

  def get do
    call(:get)
  end

  def ack(message_id) do
    call({:ack, message_id})
  end

  def reject(message_id) do
    call({:reject, message_id})
  end

  def keys do
    call(:keys)
  end

  ## Callbacks impl

  def init(:ok) do
    {:ok, nil}
  end

  @doc "only for tests"
  def handle_call(:keys, _from, state) do
    result = Amnesia.transaction do
      {Database.Message.keys, Database.MessageProgress.keys}
    end
    {:reply, result, state}
  end

  def handle_call({:add, message}, _from, state) do
    item = Database.Message.add(message)
    {:reply, {:id, item.id}, state}
  end

  def handle_call(:get, _from, state) do
    result =
      Amnesia.transaction do
        case Database.Message.first() do
          nil ->
            :empty

          item ->
            Database.Message.delete(item)
            Database.MessageProgress.write(
              struct(Database.MessageProgress, Map.from_struct(item))
            )
            {{:id, item.id}, item.item}
        end
      end

    {:reply, result, state}
  end

  def handle_call({:ack, message_id}, _from, state) do
    found =
      Amnesia.transaction do
        case Database.MessageProgress.read(message_id) do
          nil ->
            :empty

          _ ->
            Database.MessageProgress.delete(message_id)
            :ok
        end
      end

    {:reply, found, state}
  end

  def handle_call({:reject, message_id}, _from, state) do
    result =
      Amnesia.transaction do
        case Database.MessageProgress.read(message_id) do
          nil ->
            :empty

          msg ->
            Database.MessageProgress.delete(message_id)
            item =
              Database.Message.write(%Database.Message{item: msg.item, id: nil})
            {:id, item.id}
        end
      end

    {:reply, result, state}
  end

  ## Helpers

  defp call(message) do
    GenServer.call(@name, message)
  end

end
