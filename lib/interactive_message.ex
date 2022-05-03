defmodule PerudoCord.InteractiveMessage do
  alias __MODULE__

  defstruct [
    :message_id,
    :game_id
  ]

  @type t :: %InteractiveMessage{
    message_id: message_id,
    game_id: game_id,
  }

  @type message_id :: any
  @type game_id :: any

end
