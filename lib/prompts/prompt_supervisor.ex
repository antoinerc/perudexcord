defmodule PerudexCord.Prompts.PromptSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      PerudexCord.Prompts.PromptProcess
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
