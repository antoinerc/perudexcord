defmodule PerudoCord.ExampleConsumer do
  use Nostrum.Consumer
  @behaviour Perudo.NotifierServer

  alias Nostrum.Api
  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Cache.ChannelCache

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
             {:ok, thread} <- create_game_thread(msg.channel_id, parsed_args[:name]) do
          ChannelCache.create(thread)
        else
          {:error, :no_parsed_args} ->
            reply(
              msg,
              "Please supply a name for your game with the --name (-n) argument.\n ex: !create -n my-test-game"
            )

          _ ->
            reply(msg, "Unable to create a game at the moment.")
        end

      "!start" ->
        with {:ok, channel} <- get_game_thread(msg.channel_id),
             {:ok, thread_members} <- Api.get_thread_members(channel.id) do
          players = get_players_specs(channel.id, thread_members)

          Perudo.Supervisors.MainSupervistor.create_game(msg.channel_id, players)
        else
          _ ->
            reply(msg, "Unable to start game in current channel.")
        end

      "!dudo" ->
        Api.create_message(msg.channel_id, "#{%Member{user: msg.author}} called dudo!")

      "!calza" ->
        Api.create_message(msg.channel_id, "#{%Member{user: msg.author}} called calza!")

      "!outbid" ->
        case OptionParser.parse(tl(message_content),
               strict: [count: :integer, die: :integer],
               aliases: [c: :count, d: :die]
             ) do
          {[{:count, count}, {:die, die}], _, _} ->
            Api.create_message(
              msg.channel_id,
              "#{%Member{user: msg.author}} raised the bid to #{count} x #{die}!"
            )

          {_, _, _} ->
            Api.create_message(
              msg.channel_id,
              "#{%Member{user: msg.author}} invalid outbid command. Please include --count and --die arguments."
            )
        end

      _ ->
        :ignore
    end
  end

  def handle_event(
        {:THREAD_MEMBERS_UPDATE,
         %{removed_member_ids: nil, added_members: added_members, id: channel_id}, _ws_state}
      ) do
    {:ok, channel} = ChannelCache.get(channel_id)

    Enum.map(added_members, fn x ->
      Api.create_message(x.id, "#{%Member{user: %User{id: x.user_id}}} joined game #{channel}")
    end)
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end

  defp get_game_thread(channel_id) do
    case get_channel(channel_id) do
      {:ok, channel} when channel.type == 11 ->
        {:ok, channel}

      {:ok, _} ->
        {:error, :wrong_channel_type}

      error ->
        error
    end
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

  defp create_game_thread(channel_id, game_name) do
    Api.start_thread(channel_id, %{
      name: game_name,
      type: 11,
      auto_archive_duration: 1440
    })
  end

  defp get_players_specs(game_id, thread_members) do
    bot = Nostrum.Cache.Me.get()

    thread_members
    |> Enum.filter(fn player -> player.user_id != bot.id end)
    |> Enum.map(fn player -> player_spec(game_id, player.user_id) end)
  end

  def start_game(game_id, players) do
    Api.create_message(
      game_id,
      "Game #{%Nostrum.Struct.Channel{id: game_id}} is starting. Players: #{Enum.map(players, fn p -> "#{%Nostrum.Struct.User{id: p}}" end)}"
    )
  end

  def new_hand(game_id, player_id, hand) do
    {:ok, dm} = Api.create_dm(player_id)
    {:ok, channel} = get_channel(game_id)

    Api.create_message(
      dm.id,
      "Your new hand for game #{channel} is #{Enum.join(hand.dice, ", ")}."
    )
  end

  def move(game_id, player_id) do
    Api.create_message(
      game_id,
      "It is now #{%Nostrum.Struct.User{id: player_id}} turn to play."
    )
  end

  def reveal_player_hands(game_id, hands) do
    IO.inspect(hands)
  end

  defp player_spec(game_id, player_id) do
    %{id: player_id, callback_mod: __MODULE__, callback_arg: game_id}
  end
end
