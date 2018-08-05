defmodule QueuePersistent.Server do
  defmodule State do
    defstruct queue: :queue.new, in_progress: %{}, counter: 0
  end

  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def add(pid, message) do
    GenServer.call(pid, {:add, message})
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def ack(pid, message_id) do
    GenServer.call(pid, {:ack, message_id})
  end

  def reject(pid, message_id) do
    GenServer.call(pid, {:reject, message_id})
  end

  ## Callbacks impl

  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add, message}, _from, state) do
    msg_id = state.counter + 1
    msg = {msg_id, message}
    new_queue = :queue.in(msg, state.queue)
    {:reply, msg_id, %{state | queue: new_queue, counter: msg_id}}
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

    {:reply, result,
      %{state | queue: new_queue, in_progress: in_progress}
    }
  end

  def handle_call({:ack, message_id}, _from, state) do
    {found, in_progress} =
      case Map.has_key?(state.in_progress, message_id) do
        true ->
          {:ok, Map.delete(state.in_progress, message_id)}
        _ ->
          {:not_found, state.in_progress}
      end
    {:reply, found, %{state | in_progress: in_progress}}
  end

  def handle_call({:reject, message_id}, _from, state) do
    {result, new_state} =
      if Map.has_key?(state.in_progress, message_id) do
        message = Map.get(state.in_progress, message_id)
        new_queue = :queue.in({message_id, message}, state.queue)
        new_in_progress = Map.delete(state.in_progress, message_id)

        {:ok, %{state | queue: new_queue, in_progress: new_in_progress}}
      else
        {:not_found, state}
      end
    {:reply, result, new_state}
  end

  ## Helpers
  # defp add_to_queue(queue, message) do
  #
  # end

end
