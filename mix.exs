defmodule Urepo.MixProject do
  use Mix.Project

  def project do
    [
      app: :urepo,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Urepo.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.3.0"},
      {:hex_core, "~> 0.6.0"},
      {:cachex, "~> 3.2.0"},
      {:jason, "~> 1.0"},
      {:dialyxir, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.22.0", only: :dev}
    ]
  end
end
