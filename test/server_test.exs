defmodule QueuePersistent.Test.Server do
  use ExUnit.Case

  alias QueuePersistent.Test.Helpers

  setup do
    Helpers.App.reset
  end

  test "#get from empty queue" do
    assert QueuePersistent.get == :empty
  end

  test "#add pushes messages to queue" do
    Enum.map(["one", 2, 3], &QueuePersistent.add/1)

    {q, qw} = QueuePersistent.Server.keys
    assert length(q)  == 3
    assert length(qw) == 0
  end

  test "#get reserves message" do
    [testo_id, mesto_id, pesto_id] =
      ["testo", "mesto", "pesto"]
        |> Enum.map(&QueuePersistent.add/1)
        |> Keyword.values()

    QueuePersistent.get

    assert QueuePersistent.Server.keys == {[mesto_id, pesto_id], [testo_id]}
  end

  test "#get fifo order" do
    messages = ["one", 2, 3]
    Enum.map(messages, &QueuePersistent.add/1)

    result = for _ <- 1..3 do
      {_, m} = QueuePersistent.get
      m
    end

    assert result == messages
  end

  test "#ack removes message" do
    Enum.map(["one", 2, 3], &QueuePersistent.add/1)

    {{:id, msg_id}, msg} = QueuePersistent.get
    QueuePersistent.ack(msg_id)

    {q, qw} = QueuePersistent.Server.keys
    assert length(q)  == 2
    assert length(qw) == 0
    assert        msg == "one"
  end

  test "#reject adds message at the end of the queue" do
    Enum.map(["one", 2, 3], &QueuePersistent.add/1)

    {{:id, msg_id}, msg} = QueuePersistent.get
    {:id, new_msg_id} = QueuePersistent.reject(msg_id)

    {q, qw} = QueuePersistent.Server.keys
    assert [2, 3, new_msg_id] == q
    assert length(qw) == 0
    assert        msg == "one"
  end

  test "#reject & #ack wrong message_id" do
    QueuePersistent.add("my_favorite_msg")
    QueuePersistent.get

    {q, qw} = QueuePersistent.Server.keys
    assert {length(q), length(qw)} == {0, 1}

    assert QueuePersistent.reject(44) == :empty
    assert QueuePersistent.ack(44)    == :empty
  end

end
