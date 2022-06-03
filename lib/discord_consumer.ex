defmodule PerudexCord.DiscordConsumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Cache.ChannelCache

  alias PerudexCord.{Games}
  alias DiscordCmdTokens

  @prefix PerudexCord.DiscordCmdTokens.prefix()
  @help_cmd PerudexCord.DiscordCmdTokens.help_cmd()
  @rules_short_cmd PerudexCord.DiscordCmdTokens.rules_short_cmd()
  @rules_cmd PerudexCord.DiscordCmdTokens.rules_cmd()
  @presentation PerudexCord.DiscordCmdTokens.presentation()
  @rules PerudexCord.DiscordCmdTokens.rules()
  @join_reaction PerudexCord.DiscordCmdTokens.join_reaction()
  @calza_reaction PerudexCord.DiscordCmdTokens.calza_reaction()
  @dudo_reaction PerudexCord.DiscordCmdTokens.dudo_reaction()
  @start_reaction PerudexCord.DiscordCmdTokens.start_reaction()
  @cancel_reaction PerudexCord.DiscordCmdTokens.cancel_reaction()

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
           emoji: %Nostrum.Struct.Emoji{name: @join_reaction}
         }, _ws_state}
      ) do
    Games.add_player(game_id, user_id)
  end

  def handle_event(
        {:MESSAGE_REACTION_REMOVE,
         %Nostrum.Struct.Event.MessageReactionRemove{
           message_id: game_id,
           user_id: user_id,
           emoji: %Nostrum.Struct.Emoji{name: @join_reaction}
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
           emoji: %Nostrum.Struct.Emoji{name: @start_reaction} = emoji
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
           emoji: %Nostrum.Struct.Emoji{name: @cancel_reaction} = emoji
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
           emoji: %Nostrum.Struct.Emoji{name: @calza_reaction}
         }, _ws_state}
      ) do
    Games.calza(message_id, user_id)
  end

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %Nostrum.Struct.Event.MessageReactionAdd{
           message_id: message_id,
           user_id: user_id,
           emoji: %Nostrum.Struct.Emoji{name: @dudo_reaction}
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
