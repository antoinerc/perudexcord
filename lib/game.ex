defmodule PerudoCord.Game do
  alias __MODULE__

  defstruct [
    :id,
    :game_name,
    :creator_id,
    :players,
  ]

  @type t :: %Game{
          id: game_id,
          game_name: game_name,
          creator_id: discord_user_id,
          players: [discord_user_id]
        }

  @type game_id :: any
  @type message_id :: any
  @type game_name :: String.t()
  @type discord_user_id :: any

  @spec create(game_id, discord_user_id, game_name) :: PerudoCord.Game.t()
  def create(id, creator_id, game_name) do
    %Game{
      id: id,
      creator_id: creator_id,
      game_name: game_name,
      players: [creator_id]
    }
  end

  @spec add_player(PerudoCord.Game.t(), discord_user_id) :: PerudoCord.Game.t()
  def add_player(%Game{players: players} = game, player_id) do
    case player_id not in players do
      true -> %Game{game | players: [player_id | players]}
      false -> game
    end
  end

  @spec remove_player(PerudoCord.Game.t(), discord_user_id) :: PerudoCord.Game.t()
  def remove_player(%Game{creator_id: player_id} = game, player_id) do
    game
  end

  def remove_player(%Game{players: players} = game, player_id) do
    %Game{game | players: List.delete(players, player_id)}
  end
end
