defmodule PerudoCord.PlayerNotifier do
  @behaviour Perudex.NotifierServer

  alias Nostrum.Api
  alias PerudoCord.{Games, Game, InteractiveMessageHistory}

  def illegal_move(game_id, recipient_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Illegal move for game #{name}! Reply to the last message with a valid move."
      )
    end
  end

  def invalid_bid(game_id, recipient_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Invalid bet for game #{name}! Reply to the last message with a valid move."
      )
    end
  end

  def loser(game_id, recipient_id, loser_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Player #{user(loser_id)} has been eliminated from game #{name}!"
      )
    end
  end

  def unauthorized_move(game_id, recipient_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "It is not your turn to play in game #{name}!"
      )
    end
  end

  def move(game_id, recipient_id, %Perudex.Hand{dice: dice}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id),
         {:ok, message} <-
           Api.create_message(
             dm_channel.id,
             "It is your turn to play in game #{name}. Your current hand is #{inspect(dice)} \nReply to this message with your new bid in the format [count, die] or react with either #{emoji("👎")} for Dudo or #{emoji("👌")} for Calza."
           ) do
      InteractiveMessageHistory.insert(recipient_id, message.id, game_id)
    else
      error -> error
    end
  end

  def new_hand(game_id, recipient_id, %Perudex.Hand{dice: dice}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Your new hand for game #{name} is #{inspect(dice)}"
      )
    end
  end

  def reveal_players_hands(game_id, recipient_id, hands, {count, die}) do
    msg =
      Enum.reduce(hands, "", fn player_hand, acc ->
        "#{acc}#{user(player_hand.player_id)}: #{inspect(player_hand.hand.dice)}\n"
      end)

    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "The hands for the latest round of game #{name} were: \n#{msg}There was #{count} x #{die}."
      )
    end
  end

  def start_game(game_id, recipient_id, participating_players) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Game #{name} has started! Players: #{Enum.map(participating_players, fn p -> "#{user(p)}" end)}"
      )
    end
  end

  def last_move(game_id, recipient_id, move_initiator, {:calza, true}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Player #{user(move_initiator)} in game #{name} called CALZA and was RIGHT!"
      )
    end
  end

  def last_move(game_id, recipient_id, move_initiator, {:calza, false}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Player #{user(move_initiator)} in game #{name} called CALZA and was WRONG!"
      )
    end
  end

  def last_move(game_id, recipient_id, move_initiator, {:dudo, true}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Player #{user(move_initiator)} in game #{name} called DUDO and was RIGHT!"
      )
    end
  end

  def last_move(game_id, recipient_id, move_initiator, {:dudo, false}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Player #{user(move_initiator)} in game #{name} called DUDO and was WRONG!"
      )
    end
  end

  def last_move(game_id, recipient_id, move_initiator, {:outbid, {count, die}}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "Player #{user(move_initiator)} in game #{name} has raised the bid to #{count} x #{die}!"
      )
    end
  end

  def winner(game_id, winner_id, winner_id) do
    with {:ok, dm_channel} <- Api.create_dm(winner_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{emoji("🏆")} Congratulation on WINNING game #{name} #{emoji("🏆")}"
      )
    end
  end

  def winner(game_id, recipient_id, winner_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         %Game{game_name: name} <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{emoji("🏆")} Player #{user(winner_id)} has WON game #{name} #{emoji("🏆")}"
      )
    end
  end

  def player_spec(game_id, recipient_id),
    do: %{id: recipient_id, callback_mod: __MODULE__, callback_arg: game_id}

  defp user(id), do: %Nostrum.Struct.User{id: id}
  defp emoji(emoji), do: %Nostrum.Struct.Emoji{name: emoji}
end
