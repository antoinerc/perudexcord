defmodule PerudexCord.Game do
  @moduledoc """
  Functions to manipulate a Game struct
  """

  alias __MODULE__

  defstruct [
    :id,
    :game_name,
    :creator_id,
    :players
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

  @doc """
  Initialize a new `Game` struct with a supplied `game_id`, `creator_id` and `game_name`

  Returns a `Game` struct

  ## Examples
      iex> PerudexCord.Game.create(1, 123, "coolest-game")
      %PerudexCord.Game{
        id: 1,
        creator_id: 123,
        game_name: "coolest-game",
        players: [123]
      }
  """
  @spec create(game_id, discord_user_id, game_name) :: PerudexCord.Game.t()
  def create(id, creator_id, game_name) do
    %Game{
      id: id,
      creator_id: creator_id,
      game_name: game_name,
      players: [creator_id]
    }
  end

  @doc """
  Add a player id to the game list of players id

  Returns a `Game` struct with the updated list of players.

  ## Examples
      iex> PerudexCord.Game.add_player(%PerudexCord.Game{players: [123]}, 345)
      %PerudexCord.Game{
        players: [345, 123]
      }
  """
  @spec add_player(PerudexCord.Game.t(), discord_user_id) :: PerudexCord.Game.t()
  def add_player(%Game{players: players} = game, player_id) do
    if player_id not in players do
      %Game{game | players: [player_id | players]}
    else
      game
    end
  end

  @doc """
  Remove a player id from the game list of players id

  Returns a `Game` struct with the updated list of players.

  ## Examples
      iex> PerudexCord.Game.remove_player(%PerudexCord.Game{players: [123, 345]}, 345)
      %PerudexCord.Game{
        players: [123]
      }
  """
  @spec remove_player(PerudexCord.Game.t(), discord_user_id) :: PerudexCord.Game.t()
  def remove_player(%Game{creator_id: player_id} = game, player_id) do
    game
  end

  def remove_player(%Game{players: players} = game, player_id) do
    %Game{game | players: List.delete(players, player_id)}
  end
end
