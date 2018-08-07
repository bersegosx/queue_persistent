# QueuePersistent

## Installation

```shell
mix deps.get
```

## Usage

```elixir
iex(1)> QueuePersistent.add "some_message"
{:id, 7}
iex(2)> QueuePersistent.add {:second}
{:id, 8}
iex(3)> QueuePersistent.add "third"
{:id, 9}
iex(4)> QueuePersistent.get
{{:id, 7}, "some_message"}
iex(5)> QueuePersistent.get
{{:id, 8}, {:second}}
iex(6)> QueuePersistent.ack 7
:ok
iex(7)> QueuePersistent.reject 8
{:id, 10}
iex(8)> QueuePersistent.get
{{:id, 9}, "third"}
iex(9)> QueuePersistent.get
{{:id, 10}, {:second}}
```
