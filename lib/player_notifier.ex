defmodule PerudexCord.PlayerNotifier do
  @behaviour Perudex.NotifierServer

  alias Nostrum.Api
  alias PerudexCord.Games
  alias PerudexCord.Games.Game
  alias PerudexCord.Prompts.PromptProcess
  alias PerudexCord.DiscordCmdTokens

  def illegal_move(game_id, recipient_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} Illegal move! Reply to the last message with a valid move."
      )
    end
  end

  def invalid_bid(game_id, recipient_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} Invalid bet! Reply to the last message with a valid move."
      )
    end
  end

  def loser(game_id, recipient_id, loser_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} #{user(loser_id)} has been eliminated!"
      )
    end
  end

  def unauthorized_move(game_id, recipient_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} It is not your turn to play"
      )
    end
  end

  def move(game_id, recipient_id, %Perudex.Hand{dice: dice}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id),
         {:ok, message} <-
           Api.create_message(
             dm_channel.id,
             "#{prefix(game)} It is your turn to play. Your hand is **#{inspect(dice)}** \nReply to this message with your new bid in the format count x die or react with either #{emoji(DiscordCmdTokens.dudo_reaction())} for Dudo or #{emoji(DiscordCmdTokens.calza_reaction())} for Calza."
           ) do
      PromptProcess.insert(recipient_id, message.id, game_id)
    else
      error -> error
    end
  end

  def new_hand(game_id, recipient_id, %Perudex.Hand{dice: dice}) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} Your new hand is **#{inspect(dice)}**"
      )
    end
  end

  def reveal_players_hands(game_id, recipient_id, hands, {count, die}) do
    msg =
      Enum.reduce(hands, "", fn {player_id, player_hand}, acc ->
        "#{acc}#{user(player_id)}: #{inspect(player_hand.dice)}\n"
      end)

    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} The count was **#{count} x #{die}**.\nThe hands for the latest round were: \n#{msg}"
      )
    end
  end

  def start_game(game_id, recipient_id, participating_players) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} Game has started! Players: #{Enum.map(participating_players, fn p -> "#{user(p)}" end)}"
      )
    end
  end

  def last_move(game_id, move_initiator, move_initiator, move) do
    with {:ok, dm_channel} <- Api.create_dm(move_initiator),
         game <- Games.get(game_id) do
      case move do
        {:outbid, {count, value}} ->
          Api.create_message(
            dm_channel.id,
            "#{prefix(game)} You **raised** the bid to **#{count} x #{value}**"
          )

        other_move ->
          Api.create_message(
            dm_channel.id,
            "#{prefix(game)} You called #{format_own_move(other_move)}"
          )
      end
    end
  end

  def last_move(game_id, recipient_id, move_initiator, move) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      case move do
        {:outbid, {count, value}} ->
          Api.create_message(
            dm_channel.id,
            "#{prefix(game)} #{user(move_initiator)} has **raised** the bid to **#{count} x #{value}**"
          )

        other_move ->
          Api.create_message(
            dm_channel.id,
            "#{prefix(game)} #{user(move_initiator)} called #{format_move(other_move)}"
          )
      end
    end
  end

  def winner(game_id, winner_id, winner_id) do
    with {:ok, dm_channel} <- Api.create_dm(winner_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} #{emoji(DiscordCmdTokens.congratulations_reaction())} Congratulations on WINNING #{emoji(DiscordCmdTokens.congratulations_reaction())}"
      )
    end
  end

  def winner(game_id, recipient_id, winner_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} #{emoji(DiscordCmdTokens.congratulations_reaction())} #{user(winner_id)} has WON #{emoji(DiscordCmdTokens.congratulations_reaction())}"
      )
    end
  end

  def phase_change(game_id, recipient_id, :palifico) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.change_phase(game_id, :palifico) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} Switching to **PALIFICO** phase. During a Palifico round, 1 does not count as wildcards and the value cannot be changed once set at the start of the round, only the count can be increased"
      )
    end
  end

  def phase_change(game_id, recipient_id, :normal) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.change_phase(game_id, :palifico) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} Switching to **NORMAL** phase"
      )
    end
  end

  def next_player(game_id, recipient_id, next_player_id) do
    with {:ok, dm_channel} <- Api.create_dm(recipient_id),
         game <- Games.get(game_id) do
      Api.create_message(
        dm_channel.id,
        "#{prefix(game)} #{user(next_player_id)} is now playing"
      )
    end
  end

  def player_spec(game_id, recipient_id),
    do: %{id: recipient_id, callback_mod: __MODULE__, callback_arg: game_id}

  defp user(id), do: %Nostrum.Struct.User{id: id}
  defp emoji(emoji), do: %Nostrum.Struct.Emoji{name: emoji}
  defp prefix(%Game{game_name: name, phase: :normal}), do: "[#{name}][NL]"
  defp prefix(%Game{game_name: name, phase: :palifico}), do: "[#{name}][PF]"
  defp format_own_move({move, true}), do: "**#{move}** and were **right**"
  defp format_own_move({move, false}), do: "**#{move}** and were **wrong**"
  defp format_move({move, true}), do: "**#{move}** and was **right**"
  defp format_move({move, false}), do: "**#{move}** and was **wrong**"
end
