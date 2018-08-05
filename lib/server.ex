defmodule QueuePersistent.Server do
  use GenServer

  @name __MODULE__
  @db_name "queue.db"

  defmodule State do
    defstruct queue: :queue.new, in_progress: %{}, counter: 0
  end

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: @name])
  end

  def state() do
    GenServer.call(@name, :state)
  end

  def add(message) do
    GenServer.call(@name, {:add, message})
  end

  def get() do
    GenServer.call(@name, :get)
  end

  def ack(message_id) do
    GenServer.call(@name, {:ack, message_id})
  end

  def reject(message_id) do
    GenServer.call(@name, {:reject, message_id})
  end

  ## Callbacks impl

  def init(:ok) do
    {:ok, get_saved_state()}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add, message}, _from, state) do
    msg_id = state.counter + 1
    msg = {msg_id, message}
    new_queue = :queue.in(msg, state.queue)

    new_state = %{state | queue: new_queue, counter: msg_id}
    save_state(new_state)

    {:reply, msg_id, new_state}
  end

  def handle_call(:get, _from, state) do
    {message, new_queue} = :queue.out(state.queue)
    {in_progress, result} =
      case message do
        :empty ->
          {state.in_progress, :empty}
        {:value, r} ->
          {msg_id, msg_content} = r
          {Map.put_new(state.in_progress, msg_id, msg_content), r}
      end

    new_state = %{state | queue: new_queue, in_progress: in_progress}
    save_state(new_state)

    {:reply, result, new_state}
  end

  def handle_call({:ack, message_id}, _from, state) do
    {found, in_progress} =
      case Map.has_key?(state.in_progress, message_id) do
        true ->
          {:ok, Map.delete(state.in_progress, message_id)}
        _ ->
          {:not_found, state.in_progress}
      end

    new_state = %{state | in_progress: in_progress}
    save_state(new_state)

    {:reply, found, new_state}
  end

  def handle_call({:reject, message_id}, _from, state) do
    if Map.has_key?(state.in_progress, message_id) do
      message = Map.get(state.in_progress, message_id)
      new_queue = :queue.in({message_id, message}, state.queue)
      new_in_progress = Map.delete(state.in_progress, message_id)

      new_state = %{state | queue: new_queue, in_progress: new_in_progress}
      save_state(new_state)

      {:reply, :ok, new_state}
    else
      {:reply, :not_found, state}
    end
  end

  ## Helpers

  defp get_saved_state() do
    case File.read(@db_name) do
      {:ok, content} -> :erlang.binary_to_term(content)
      _ -> %State{}
    end
  end

  defp save_state(state) do
    File.write!(@db_name, :erlang.term_to_binary(state))
  end

end
