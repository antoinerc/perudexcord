defmodule PerudoCord.PlayerNotifier do
  @behaviour Perudex.NotifierServer

  alias Nostrum.Api
  alias PerudoCord.{Games, Game, InteractiveMessageHistory}

  def illegal_move(game_id, player_id) do
  end

  def invalid_bid(game_id, player_id) do
  end

  def loser(game_id, player_id, loser_id) do
  end

  def move(game_id, player_id) do
  end

  def new_bid(game_id, player_id, {count, die}) do
  end

  def new_hand(game_id, player_id, hand) do
  end

  def reveal_players_hands(game_id, player_id, hands) do
  end

  def start_game(game_id, player_id, participating_players) do
    {:ok, dm_channel} = Api.create_dm(player_id)
    %Game{game_name: name} = Games.get(game_id)
    case Api.create_message(
      dm_channel.id,
      "Game #{name} has started! Players: #{Enum.map(participating_players, fn p -> "#{%Nostrum.Struct.User{id: p}}" end)}"
    ) do
      {:ok, message} ->
        InteractiveMessageHistory.insert(player_id, message.id, game_id)
        |> IO.inspect()
      error -> error
    end
  end

  def successful_dudo(game_id, player_id) do
  end

  def successful_calza(game_id, player_id) do
  end

  @spec unauthorized_move(any, any) :: nil
  def unauthorized_move(game_id, player_id) do
  end

  def unsuccessful_calza(game_id, player_id) do
  end

  def unsuccessful_dudo(game_id, player_id) do
  end

  def winner(game_id, player_id, winner_id) do
  end

  def player_spec(game_id, player_id) do
    %{id: player_id, callback_mod: __MODULE__, callback_arg: game_id}
  end
end
