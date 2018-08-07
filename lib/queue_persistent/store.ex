defmodule QueuePersistent.Store do
  use Amnesia

  defdatabase Database do
    deftable MessageProgress, [:id, :item], type: :set do; end

    deftable Message, [{:id, autoincrement}, :item], type: :ordered_set do

      def add(message) do
        Amnesia.transaction do
          %Message{item: message, id: nil} |> Message.write
        end
      end

    end
  end

  def init() do
    Amnesia.stop
    Amnesia.Schema.create
    Amnesia.start

    Database.create(disk: [node()])
    Database.wait(15000)
  end

end
