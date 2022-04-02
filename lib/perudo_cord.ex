defmodule PerudoCord do
  use Application

  @moduledoc """
  Documentation for `PerudoCord`.
  """

  def start(_type, _args) do
    children = [PerudoCord.Supervisor]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
