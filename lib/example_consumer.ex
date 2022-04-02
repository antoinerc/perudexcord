defmodule PerudoCord.ExampleConsumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Cache.ChannelCache

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    message_content = String.split(msg.content)

    case hd(message_content) do
      "!create" <> _ ->
        {parsed_args, _, _invalig_args} = parse_args(message_content)

        case Api.start_thread(msg.channel_id, %{
               name: parsed_args[:name],
               type: 11,
               auto_archive_duration: 1440
             }) do
          {:ok, channel} ->
            ChannelCache.create(channel)

          _ ->
            Api.create_message(msg.channel_id, "Unable to create a game at the moment.")
        end

      "!start" ->
        case get_channel(msg.channel_id) do
          {:ok, channel} ->
            Api.create_message(msg.channel_id, "Game #{channel} is starting")

          {:error, _} ->
            Api.create_message(msg.channel_id, "Unable to start game in current channel.")
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

  defp get_channel(channel_id) do
    case ChannelCache.get(channel_id) do
      {:ok, channel} -> {:ok, channel}
      {:error, :channel_not_found} -> Api.get_channel(channel_id)
    end
  end

  defp parse_args(msg) do
    args = tl(msg)

    OptionParser.parse(args, strict: [name: :string])
  end
end
