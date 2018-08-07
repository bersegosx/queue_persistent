defmodule QueuePersistent.Store do
  @moduledoc false

  use Amnesia

  defdatabase Database do
    deftable MessageProgress, [:id, :item], type: :set do; end

    deftable Message, [{:id, autoincrement}, :item], type: :ordered_set do
      def add(message) do
        Amnesia.transaction do
          Message.write(%Message{item: message, id: nil})
        end
      end
    end
    
  end

  def init do
    Amnesia.stop
    Amnesia.Schema.create
    Amnesia.start

    Database.create(disk: [node()])
    Database.wait(15000)
  end

end
