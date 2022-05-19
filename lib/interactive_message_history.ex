defmodule PerudexCord.InteractiveMessageHistory do
  use GenServer, restart: :transient

  alias PerudexCord.InteractiveMessage

  def start_link(_opts),
    do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl true
  def init(state), do: {:ok, state}

  def lookup(player_id) do
    GenServer.call(__MODULE__, {:lookup, player_id})
  end

  def insert(player_id, message_id, game_id) do
    GenServer.call(__MODULE__, {:insert, player_id, message_id, game_id})
  end

  @impl true
  def handle_call({:lookup, player_id}, _from, state) do
    {:reply, state[player_id], state}
  end

  @impl true
  def handle_call({:insert, player_id, message_id, game_id}, _from, state) do
    new_state =
      Map.put(state, player_id, %InteractiveMessage{message_id: message_id, game_id: game_id})

    {:reply, new_state[player_id], new_state}
  end
end
