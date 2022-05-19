defmodule PerudexCord do
  use Application

  @moduledoc """
  Documentation for `PerudexCord`.
  """

  def start(_type, _args) do
    children = [
      PerudexCord.GameRegistry.child_spec(),
      PerudexCord.Supervisors.ConsumerSupervisor,
      PerudexCord.Supervisors.GameSupervisor,
      PerudexCord.Supervisors.InteractiveMessageSupervisor
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  def service_name(service_id), do: {:via, Registry, {PerudexCord.GameRegistry, service_id}}
end
