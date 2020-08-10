defmodule Urepo.CLI do
  @moduledoc false

  @options [
    public_key: :string,
    private_key: :string
  ]

  def genkeys(args) do
    {parsed, _} = OptionParser.parse!(args, strict: @options)
    private_path = expand(Keyword.get(parsed, :private_key, "private.pem"))

    {private_key, public_key} = Urepo.generate_keys()

    File.write!(private_path, private_key)
    IO.puts("Written private key to: #{private_path}")

    case Keyword.fetch(parsed, :public_key) do
      {:ok, path} ->
        public_path = expand(path)
        File.write!(public_path, public_key)
        IO.puts("Written public key to: #{public_path}")

      _ ->
        :ok
    end
  end

  defp expand(path), do: Path.expand(path, File.cwd!())
end
