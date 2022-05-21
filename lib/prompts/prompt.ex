defmodule PerudexCord.Prompts.Prompt do
  alias __MODULE__

  defstruct [
    :message_id,
    :game_id
  ]

  @type t :: %Prompt{
          message_id: message_id,
          game_id: game_id
        }

  @type message_id :: any
  @type game_id :: any
end
