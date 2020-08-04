defmodule Urepo.Docs do
  use GenServer

  @files __MODULE__.Files
  @paths __MODULE__.Paths

  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  def file(name, version, path) do
    files =
      case :ets.lookup(@paths, {name, version}) do
        [{_, files}] when is_map(files) ->
          files

        [] ->
          {:ok, files} = fetch_and_save(name, version)
          files
      end

    with {:ok, hash} <- Map.fetch(files, path),
         [{^hash, content}] <- :ets.lookup(@files, hash),
         do: {:ok, content}
  end

  defp fetch_and_save(name, version) do
    with {:ok, files} <- Urepo.get_docs(name, version) do
      {paths, hashes} =
        Enum.reduce(files, {%{}, []}, fn {path, content}, {paths, hashes} ->
          hash = :crypto.hash(:sha, content)

          {Map.put(paths, to_string(path), hash), [{hash, content} | hashes]}
        end)

      true = :ets.insert(@paths, {{name, version}, Map.new(paths)})
      true = :ets.insert(@files, hashes)

      {:ok, paths}
    end
  end

  def init(_) do
    options = [:named_table, :public, write_concurrency: false, read_concurrency: true]
    _ = :ets.new(@files, options)
    _ = :ets.new(@paths, options)

    {:ok, []}
  end
end
