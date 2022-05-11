defmodule PerudoCord.ExampleConsumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Cache.ChannelCache

  alias PerudoCord.{Games}

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    message_content = OptionParser.split(msg.content)

    case hd(message_content) do
      "!create" <> _ ->
        with {:ok, channel} <- get_channel(msg.channel_id),
             true <- channel.type == 0,
             {:ok, parsed_args} <-
               parse_required_args(tl(message_content), [name: :string], n: :name),
             {:ok, invitation} <-
               create_game_invitation(msg.channel_id, msg, parsed_args[:name], %Member{
                 user: msg.author
               }) do
          Games.create(invitation.id, msg.author.id, parsed_args[:name])
        else
          {:error, :no_parsed_args} ->
            reply(
              msg,
              "Please supply a name for your game with the --name (-n) argument.\n ex: !create -n my-test-game"
            )

          _ ->
            reply(msg, "Unable to create a game at the moment.")
        end
      _ ->
        :ignore
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

  defp parse_required_args(args, required_args, aliases) do
    case OptionParser.parse(args, strict: required_args, aliases: aliases) do
      {[], _, _} -> {:error, :no_parsed_args}
      {parsed_args, _, _} -> {:ok, parsed_args}
    end
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

  def start_game(game_id, players) do
    Api.create_message(
      game_id,
      "Game #{%Nostrum.Struct.Channel{id: game_id}} is starting. Players: #{Enum.map(players, fn p -> "#{%Nostrum.Struct.User{id: p}}" end)}"
    )
  end
end
