defmodule PerudoCord do
  use Application

  @moduledoc """
  Documentation for `PerudoCord`.
  """

  def start(_type, _args) do
    children = [
      PerudoCord.GameRegistry.child_spec(),
      PerudoCord.Supervisors.ConsumerSupervisor,
      PerudoCord.Supervisors.GameSupervisor
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  def service_name(service_id), do: {:via, Registry, {PerudoCord.GameRegistry, service_id}}
end
