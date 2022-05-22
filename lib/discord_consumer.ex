defmodule PerudexCord.DiscordConsumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Cache.ChannelCache

  alias PerudexCord.{Games}

  @prefix "!per"
  @help_cmd @prefix <> " help"
  @rules_short_cmd @prefix <> " -r"
  @rules_cmd @prefix <> " --rules"
  @presentation ~S"""
  perudexcord - a bot to play Perudo inside of Discord [beta]

  USAGE
    !per [-r | --rules] <game-name>

  EXAMPLES
    `!per my-game`
    Start a game named 'my-game'

    `!per --rules`
    Reply to your message with the rules of the game
  """

  @rules ~S"""
  In a game of Perudo, each player starts with 5 dice in his hand.
  Players are betting on the sum of the count of a specific die value.
  When you increase the bid, you are saying there is AT LEAST the number of specified die value

  **Playing the game**
  The game is played in rounds. The player who goes first in a round sets the starting bid.
  From then, each player has three possible move:
  **Outbid**:
    - Increase the count of the current die value and/or or increase the die value
    - Reduce the current count by turning it into a Paco bid
      - Pacos (1) are aces/wilds
      - To turn a bid into a Paco bid, the count must be at least the current count divided by two rounded up
        - Ex: [4 x 5 turns into 2 x 1], [9 x 3 turns into 5 x 1]
    - Increase the current count and/or change the current value by turning a Paco bid into a normal bid, the count must be at least twice the current count plus one. You decide the value
        - Ex: [3 x 1 turns into 7 x 5], [1 x 1 turns into 3 x 2]
  **Calza**: if you believe the current bid to be exact you can call Calza
    - If you are right, you will add a die back to your hand, unless your hand is already full
    - If you are wrong, you will lose a die from your hand
    - In both cases, you will start the next round
  **Dudo**: if you believe the bid made by the last player is too ambitious
    - The player that is wrong will lose a die and start the next round

  Both Calza and Dudo end the round.

  **End of round**
  When a round end, the players hands are revealed and the bid is validated.
  The bid is calculated using the sum of all the die of current value PLUS the wildcards.
  Example:
    The current bid is 4 x 3
    - Hand 1 : [3, 3, 5]
    - Hand 2 : [2, 5, 3, 4, 1]
    The bid is spot on because Hand 1 contains 2 x 3, and Hand 2 contains 1 x 3 + 1 x 1, making it 4 x 3.

  **End of game**
  The last player standing with at least one die is crowned winner of the game.
  """

  def start_link do
    Consumer.start_link(__MODULE__)
  end


  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           type: 19,
           author: %Nostrum.Struct.User{id: user_id, bot: nil},
           referenced_message: %Nostrum.Struct.Message{id: ref_message_id},
           mentions: [%Nostrum.Struct.User{bot: true}]
         } = msg, _ws_state}
      ) do
    [count, dice] = parse_bid(msg.content)
    Games.outbid(ref_message_id, user_id, {count, dice})
  end

  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           id: id,
           content: @help_cmd,
           channel_id: channel_id,
           type: 0
         }, _ws_state}
      ),
      do: print_presentation(channel_id, id)

  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           id: id,
           content: @prefix,
           channel_id: channel_id,
           type: 0
         }, _ws_state}
      ),
      do: print_presentation(channel_id, id)

  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           id: id,
           content: @rules_cmd,
           channel_id: channel_id,
           type: 0
         }, _ws_state}
      ),
      do: print_rules(channel_id, id)

  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           id: id,
           content: @rules_short_cmd,
           channel_id: channel_id,
           type: 0
         }, _ws_state}
      ),
      do: print_rules(channel_id, id)

  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           content: @prefix <> content,
           channel_id: channel_id,
           author: author
         } = msg, _ws_state}
      ) do
    with {:ok, channel} <- get_channel(channel_id),
         true <- channel.type == 0,
         [game_name | _] = OptionParser.split(content),
         {:ok, invitation} <-
           create_game_invitation(channel_id, msg, game_name, %Member{
             user: author
           }) do
      Games.create(invitation.id, author.id, game_name)
    else
      {:error, :no_parsed_args} ->
        reply(
          msg,
          "Please supply a name for your game."
        )

      _ ->
        reply(msg, "Unable to create a game at the moment.")
    end
  end

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %Nostrum.Struct.Event.MessageReactionAdd{
           message_id: game_id,
           user_id: user_id,
           emoji: %Nostrum.Struct.Emoji{name: "👍"}
         }, _ws_state}
      ) do
    Games.add_player(game_id, user_id)
  end

  def handle_event(
        {:MESSAGE_REACTION_REMOVE,
         %Nostrum.Struct.Event.MessageReactionRemove{
           message_id: game_id,
           user_id: user_id,
           emoji: %Nostrum.Struct.Emoji{name: "👍"}
         }, _ws_state}
      ) do
    Games.remove_player(game_id, user_id)
  end

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %Nostrum.Struct.Event.MessageReactionAdd{
           channel_id: channel_id,
           message_id: game_id,
           user_id: user_id,
           emoji: %Nostrum.Struct.Emoji{name: "▶️"} = emoji
         }, _ws_state}
      ) do
    case Games.start(game_id, user_id) do
      :ok ->
        Api.delete_message(channel_id, game_id)

      {:error, _} ->
        Api.delete_reaction(channel_id, game_id, emoji)
    end
  end

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %Nostrum.Struct.Event.MessageReactionAdd{
           channel_id: channel_id,
           message_id: game_id,
           user_id: user_id,
           emoji: %Nostrum.Struct.Emoji{name: "❌"} = emoji
         }, _ws_state}
      ) do
    case Games.delete(game_id, user_id) do
      :ok ->
        Api.delete_message(channel_id, game_id)

      {:error, _} ->
        Api.delete_reaction(channel_id, game_id, emoji)
    end
  end

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %Nostrum.Struct.Event.MessageReactionAdd{
           message_id: message_id,
           user_id: user_id,
           emoji: %Nostrum.Struct.Emoji{name: "👌"}
         }, _ws_state}
      ) do
    Games.calza(message_id, user_id)
  end

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %Nostrum.Struct.Event.MessageReactionAdd{
           message_id: message_id,
           user_id: user_id,
           emoji: %Nostrum.Struct.Emoji{name: "👎"}
         }, _ws_state}
      ) do
    Games.dudo(message_id, user_id)
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end

  defp get_channel(channel_id) do
    case ChannelCache.get(channel_id) do
      {:ok, channel} ->
        {:ok, channel}

      {:error, :channel_not_found} ->
        Api.get_channel(channel_id)
    end
  end

  defp reply(message_to_reply, message) do
    Api.create_message(message_to_reply.channel_id,
      content: message,
      message_reference: %{message_id: message_to_reply.id}
    )
  end

  defp create_game_invitation(
         channel_id,
         %Nostrum.Struct.Message{id: original_message_id},
         game_name,
         creator
       ) do
    Api.delete_message(channel_id, original_message_id)

    Api.create_message(
      channel_id,
      "#{creator} is creating game #{game_name}. #{%Nostrum.Struct.Emoji{name: ":thumbsup:"}} this post to be included!\n Creator can react with #{%Nostrum.Struct.Emoji{name: ":arrow_forward:"}} to start the game or #{%Nostrum.Struct.Emoji{name: "❌"}} to cancel."
    )
  end

  defp parse_bid(bid) do
    [_, count, dice] = Regex.run(~r/\s*(\d+)\s*x\s*(\d+)\s*/, bid)
    [String.to_integer(count), String.to_integer(dice)]
  end

  defp print_presentation(channel_id, message_id),
    do:
      Api.create_message(
        channel_id,
        message_reference: %{message_id: message_id},
        content: @presentation
      )

  def print_rules(channel_id, message_id),
    do:
      Api.create_message(
        channel_id,
        message_reference: %{message_id: message_id},
        content: @rules
      )
end
