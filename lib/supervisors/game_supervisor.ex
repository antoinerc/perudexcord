defmodule PerudoCord.Supervisors.GameSupervisor do
  use DynamicSupervisor

  alias PerudoCord.{Game, GameProcess}

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_game_to_supervisor(%Game{} = game) do
    child_spec = %{
      id: GameProcess,
      start: {GameProcess, :start_link, [game]},
      restart: :transient
    }

    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
