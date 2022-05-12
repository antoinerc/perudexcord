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
    with {:ok, dm_channel} <- Api.create_dm(player_id),
         %Game{game_name: name} <- Games.get(game_id),
         {:ok, message} <-
           Api.create_message(
             dm_channel.id,
             "It is your turn to play in game #{name}. Reply to this message with your new bid in the format [count, die] or react with either #{%Nostrum.Struct.Emoji{name: "👎"}} for Dudo or #{%Nostrum.Struct.Emoji{name: "👌"}} for Calza."
           ) do
      InteractiveMessageHistory.insert(player_id, message.id, game_id)
    else
      error -> error
    end
  end

  def new_bid(game_id, player_id, {count, die}) do
  end

  def new_hand(game_id, player_id, %Perudex.Hand{dice: dice}) do
    with {:ok, dm_channel} <- Api.create_dm(player_id),
         %Game{game_name: name} <- Games.get(game_id),
         {:ok, message} <-
           Api.create_message(
             dm_channel.id,
             "Your new hand for game #{name} is #{inspect(dice)}"
           ) do
      InteractiveMessageHistory.insert(player_id, message.id, game_id)
    end
  end

  def reveal_players_hands(game_id, player_id, hands) do
  end

  def start_game(game_id, player_id, participating_players) do
    with {:ok, dm_channel} <- Api.create_dm(player_id),
         %Game{game_name: name} <- Games.get(game_id),
         {:ok, message} <-
           Api.create_message(
             dm_channel.id,
             "Game #{name} has started! Players: #{Enum.map(participating_players, fn p -> "#{%Nostrum.Struct.User{id: p}}" end)}"
           ) do
      InteractiveMessageHistory.insert(player_id, message.id, game_id)
    end
  end

  def successful_dudo(game_id, player_id) do
  end

  def successful_calza(game_id, player_id) do
  end

  def unauthorized_move(game_id, player_id) do
  end

  def unsuccessful_calza(game_id, player_id) do
  end

  def unsuccessful_dudo(game_id, player_id) do
  end

  def winner(game_id, winner_id, winner_id) do
    with {:ok, dm_channel} <- Api.create_dm(winner_id),
         %Game{game_name: name} <- Games.get(game_id),
         {:ok, _} <-
           Api.create_message(
             dm_channel.id,
             "#{%Nostrum.Struct.Emoji{name: "🏆"}} Congratulation on WINNING game #{name} #{%Nostrum.Struct.Emoji{name: "🏆"}}"
           ) do
      InteractiveMessageHistory.insert(winner_id, winner_id, game_id)
    end
  end

  def winner(game_id, player_id, winner_id) do
    with {:ok, dm_channel} <- Api.create_dm(player_id),
         %Game{game_name: name} <- Games.get(game_id),
         {:ok, message} <-
           Api.create_message(
             dm_channel.id,
             "#{%Nostrum.Struct.Emoji{name: "🏆"}} Player #{%Nostrum.Struct.User{id: winner_id}} has WON game #{name} #{%Nostrum.Struct.Emoji{name: "🏆"}}"
           ) do
      InteractiveMessageHistory.insert(player_id, message.id, game_id)
    end
  end

  def player_spec(game_id, player_id) do
    %{id: player_id, callback_mod: __MODULE__, callback_arg: game_id}
  end
end
