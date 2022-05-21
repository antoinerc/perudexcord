defmodule PerudexCord do
  use Application

  @moduledoc """
  Documentation for `PerudexCord`.
  """

  def start(_type, _args) do
    children = [
      PerudexCord.Games.GameRegistry.child_spec(),
      PerudexCord.ConsumerSupervisor,
      PerudexCord.Games.GameSupervisor,
      PerudexCord.Prompts.PromptSupervisor
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  def service_name(service_id), do: {:via, Registry, {PerudexCord.Games.GameRegistry, service_id}}
end
