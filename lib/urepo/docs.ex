defmodule Urepo.Docs do
  @moduledoc """
  In-memory host for the Hex documentation.

  This lazily loades the documentation pages when needed and stores them by hash
  of their content to reduce the memory footprint of the application.
  In addition to storing `{hash, content}` pairs it also stores index of all
  pages per release (which is name/version pair).

  All in-memory storage is backed by ETS tables.
  """

  @dialyzer no_match: [fetch_and_save: 1]

  use GenServer
  require Logger

  alias Urepo.Store
  alias Urepo.Utils

  @name __MODULE__

  @files __MODULE__.Files
  @paths __MODULE__.Paths

  @prefix "docs"

  def names, do: GenServer.call(@name, :names)

  def newest(name) do
    with {:ok, [newest | _]} <- versions(name),
         do: {:ok, newest}
  end

  def versions(name) do
    GenServer.call(@name, {:versions, name})
  end

  def count do
    GenServer.call(@name, :count)
  end

  @doc """
  Publish documentation for package `name` with `version` using `tarball`.
  """
  @spec publish(name :: binary(), version :: binary(), Urepo.tarball()) ::
          :ok | {:error, term()}
  def publish(name, version, tarball) do
    with :ok <- GenServer.call(@name, {:publish, name, version, tarball}),
         {:ok, _} <- fetch_and_save({name, version}) do
      :ok
    else
      error ->
        Logger.debug("Urepo.Docs.publish/3 error: #{inspect(error)}")
        error
    end
  end

  def file(name, version, path) do
    with {:ok, files} <- lookup(@paths, {name, version}, &fetch_and_save/1),
         {:ok, hash} <- Map.fetch(files, path),
         {:ok, content} <- lookup(@files, hash) do
      {:ok, content}
    else
      error ->
        Logger.debug("Urepo.Docs.file/3 error: #{inspect(error)}")
        error
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
    store = GenServer.call(@name, :store)

    with {:ok, tarball} <- Store.fetch(store, Path.join(@prefix, "#{name}-#{version}.tar")),
         {:ok, files} <- :hex_tarball.unpack_docs(tarball, :memory) do
      {paths, hashes} =
        Enum.reduce(files, {%{}, []}, fn {path, content}, {paths, hashes} ->
          hash = :crypto.hash(:sha, content)

          {Map.put(paths, to_string(path), hash), [{hash, content} | hashes]}
        end)

      if Map.has_key?(paths, "index.html") do
        true = :ets.insert(@paths, {{name, version}, Map.new(paths)})
        true = :ets.insert(@files, hashes)

        {:ok, paths}
      else
        paths_keys = Map.keys(paths)

        # the implementation of this server assumes there to exist an 'index.html' as an entrypoint into a given tarball
        Logger.error(
          "Urepo.Docs.fetch_and_save/2 index.html not found in paths.keys: #{inspect(paths_keys)}"
        )

        {:error, {:index_missing, paths_keys}}
      end
    end
  end

  ## Server implementation

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: @name)

  @impl true
  def init(_) do
    options = [:named_table, :public, write_concurrency: false, read_concurrency: true]
    _ = :ets.new(@files, options)
    _ = :ets.new(@paths, options)

    store = Urepo.store()

    index =
      with {:ok, raw} <- Store.fetch(store, Path.join(@prefix, "index.etf")),
           {:ok, data} <- Utils.verify(raw),
           {:ok, map} when is_map(map) <- decode(data) do
        map
      else
        _ -> %{}
      end

    {:ok, {store, index}}
  end

  @impl true
  def handle_call({:publish, name, version, tarball}, _ref, {store, index}) do
    reply = Store.put(store, Path.join(@prefix, "#{name}-#{version}.tar"), tarball)

    new_index = Map.update(index, name, [version], &Utils.append_version(&1, version))

    Store.put(
      store,
      Path.join(@prefix, "index.etf"),
      Utils.sign(:erlang.term_to_binary(new_index))
    )

    {:reply, reply, {store, new_index}}
  end

  def handle_call({:versions, name}, _ref, {_, index} = state) do
    {:reply, Map.fetch(index, name), state}
  end

  def handle_call(:names, _ref, {_, index} = state) do
    {:reply, Map.keys(index), state}
  end

  def handle_call(:count, _ref, {_, index} = state) do
    {:reply, map_size(index), state}
  end

  def handle_call(:store, _ref, {store, _} = state) do
    {:reply, store, state}
  end

  defp decode(binary) when is_binary(binary) do
    {:ok, :erlang.binary_to_term(binary)}
  rescue
    ArgumentError -> :error
  end
end
