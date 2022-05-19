defmodule PerudexCord.GameRegistry do
  @moduledoc """
  This module define the Registry to keep the game state in memory.
  """
  def child_spec(),
    do:
      Registry.child_spec(keys: :unique, name: __MODULE__, partitions: System.schedulers_online())

  def lookup_game(game_id) do
    case Registry.lookup(__MODULE__, game_id) do
      [{game_pid, _}] ->
        {:ok, game_pid}

      [] ->
        {:error, :not_found}
    end
  end
end
