defmodule Urepo.Docs do
  @cache __MODULE__.Cache

  def child_spec(_) do
    import Cachex.Spec

    opts = [
      expiration: expiration(default: :timer.hours(24))
    ]

    %{
      id: __MODULE__,
      start: {Cachex, :start_link, [@cache, opts]},
      type: :supervisor
    }
  end

  def file(name, version, path) do
    files =
      case Cachex.get(@cache, {:paths, name, version}) do
        {:ok, nil} ->
          {:ok, files} = fetch_and_save(name, version)
          files

        {:ok, files} when is_map(files) ->
          files
      end

    with {:ok, hash} <- Map.fetch(files, path),
         {:ok, content} <- Cachex.get(@cache, {:content, hash}),
         do: {:ok, content}
  end

  defp fetch_and_save(name, version) do
    with {:ok, files} <- Urepo.get_docs(name, version) do
      {paths, hashes} =
        Enum.reduce(files, {%{}, []}, fn {path, content}, {paths, hashes} ->
          hash = :crypto.hash(:sha, content)

          {Map.put(paths, to_string(path), hash), [{{:content, hash}, content} | hashes]}
        end)

      {:ok, _} = Cachex.put(@cache, {:paths, name, version}, Map.new(paths))
      {:ok, _} = Cachex.put_many(@cache, hashes)

      {:ok, paths}
    end
  end
end
