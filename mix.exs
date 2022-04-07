defmodule PerudoCord.MixProject do
  use Mix.Project

  def project do
    [
      app: :perudocord,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PerudoCord, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, "~> 0.5.1"},
      {:perudo, path: "~/dev/perudo"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
