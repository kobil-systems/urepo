defmodule Urepo.Docs do
  use GenServer

  @moduledoc """
  In-memory host for the Hex documentation.

  This lazily loades the documentation pages when needed and stores them by hash
  of their content to reduce the memory footprint of the application.
  In addition to storing `{hash, content}` pairs it also stores index of all
  pages per release (which is name/version pair).

  All in-memory storage is backed by ETS tables.
  """

  @files __MODULE__.Files
  @paths __MODULE__.Paths

  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  def file(name, version, path) do
    with {:ok, files} <- lookup(@paths, {name, version}, &fetch_and_save/1),
         {:ok, hash} <- Map.fetch(files, path),
         {:ok, content} <- lookup(@files, hash) do
      {:ok, content}
    else
      _ -> :error
    end
  end

  defp lookup(table, key) do
    case :ets.lookup(table, key) do
      [{^key, data}] -> {:ok, data}
      [] -> :error
    end
  end

  defp lookup(table, key, cb) do
    case :ets.lookup(table, key) do
      [{^key, data}] -> {:ok, data}
      [] -> cb.(key)
    end
  end

  defp fetch_and_save({name, version}) do
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
