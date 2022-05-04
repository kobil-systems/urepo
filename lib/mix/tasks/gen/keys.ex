defmodule Mix.Tasks.Gen.Keys do
  @moduledoc "The mix task to generate public and private keys: `mix help gen.keys`"
  use Mix.Task

  @shortdoc "Generates a public and private key pair"
  def run(command_line_args) do
    Urepo.CLI.genkeys(command_line_args)
  end
end
