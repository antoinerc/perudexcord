defmodule PerudexCord.MixProject do
  use Mix.Project

  def project do
    [
      app: :perudexcord,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {PerudexCord, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, git: "https://github.com/Kraigie/nostrum"},
      {:perudex, "~> 0.6.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:uuid, "~> 1.1"},
      {:logger_file_backend, "~>0.0.12"}
    ]
  end
end
