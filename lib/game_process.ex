defmodule PerudoCord.GameProcess do
  use GenServer, restart: :transient

  alias PerudoCord.{Game, PlayerNotifier}
  alias Perudex.Supervisors.MainSupervisor

  def start_link(%Game{} = game),
    do: GenServer.start_link(__MODULE__, game, name: service_name(game))

  @impl true
  def init(%Game{} = state), do: {:ok, state}

  @impl true
  def handle_call({:add_player, player_id}, _from, %Game{} = state) do
    new_state = Game.add_player(state, player_id)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:remove_player, player_id}, _from, %Game{} = state) do
    new_state = Game.remove_player(state, player_id)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:delete, issued_by}, _from, %Game{creator_id: issued_by} = state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call({:delete, _}, _from, %Game{} = state) do
    {:reply, {:error, :unauthorized}, state}
  end

  @impl true
  def handle_call({:start, issued_by}, _from, %Game{creator_id: issued_by} = state) do
    MainSupervisor.create_game(
      state.id,
      Enum.map(state.players, fn p -> PlayerNotifier.player_spec(state.id, p) end)
    )

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:start, issued_by}, _from, %Game{creator_id: issued_by} = state) do
    {:reply, {:error, :unauthorized}, state}
  end

  @impl true
  def handle_call(:get, _from, %Game{} = state) do
    {:reply, state, state}
  end

  defp service_name(%Game{id: game_id}), do: PerudoCord.service_name(game_id)
end
