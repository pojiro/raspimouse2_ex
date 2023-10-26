defmodule Raspimouse2Ex.MixProject do
  use Mix.Project

  def project do
    [
      app: :raspimouse2_ex,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Raspimouse2Ex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rclex, git: "https://github.com/rclex/rclex.git", branch: "0.10.0-dev"}
    ]
  end
end
