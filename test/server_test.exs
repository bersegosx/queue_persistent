defmodule QueuePersistent.Test.Server do
  use ExUnit.Case

  alias QueuePersistent.Test.Helpers

  setup do
    Helpers.App.reset
  end

  test "#get from empty queue" do
    assert :empty == QueuePersistent.get
  end

  test "#add pushes messages to queue" do
    ["one", 2, 3] |>
      Enum.map(&QueuePersistent.add/1)

    {q, qw} = QueuePersistent.Server.keys
    assert length(q)  == 3
    assert length(qw) == 0
  end

  test "#get reserves message" do
    {:id, testo_id} = QueuePersistent.add "testo"
    {:id, mesto_id} = QueuePersistent.add "mesto"
    {:id, pesto_id} = QueuePersistent.add "pesto"
    QueuePersistent.get

    {q, qw} = QueuePersistent.Server.keys
    assert q  == [mesto_id, pesto_id]
    assert qw == [testo_id]
  end

  test "#get fifo order" do
    messages = ["one", 2, 3]
    messages |>
      Enum.map(&QueuePersistent.add/1)

    result = for _ <- 1..3 do
      {_, m} = QueuePersistent.get
      m
    end

    assert messages == result
  end

  test "#ack removes message" do
    ["one", 2, 3] |>
      Enum.map(&QueuePersistent.add/1)

    {{:id, msg_id}, msg} = QueuePersistent.get
    QueuePersistent.ack msg_id

    {q, qw} = QueuePersistent.Server.keys
    assert length(q)  == 2
    assert length(qw) == 0
    assert        msg == "one"
  end

  test "#reject adds message at the end of the queue" do
    ["one", 2, 3] |>
      Enum.map(&QueuePersistent.add/1)

    {{:id, msg_id}, msg} = QueuePersistent.get
    {:id, new_msg_id} = QueuePersistent.reject msg_id

    {q, qw} = QueuePersistent.Server.keys
    assert [2, 3, new_msg_id] == q
    assert length(qw) == 0
    assert        msg == "one"
  end

end
