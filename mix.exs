defmodule Urepo.MixProject do
  use Mix.Project

  def project do
    [
      app: :urepo,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls],
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
      {:jason, "~> 1.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22.0", only: :dev, runtime: false},
      {:excoveralls, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end
end
