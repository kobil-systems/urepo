defmodule Urepo.Repo do
  use GenServer

  alias Urepo.Store

  @name __MODULE__

  defstruct releases: %{}

  def start_link(store) do
    GenServer.start_link(__MODULE__, store, name: @name)
  end

  def add(name, release) do
    GenServer.call(@name, {:add_release, name, release})
  end

  def get_releases(name) do
    GenServer.call(@name, {:get_releases, name})
  end

  @impl true
  def init(_opts) do
    store = Urepo.store()

    {:ok, names} =
      with {:ok, data} <- Store.fetch(store, "names") do
        data
        |> :hex_registry.decode_signed()
        |> Map.fetch!(:payload)
        |> :hex_registry.decode_names(Urepo.name())
      else
        _ -> {:ok, []}
      end

    releases =
      for %{name: name} <- names, into: %{} do
        path = Path.join(["packages", name])

        releases =
          case Store.fetch(store, path) do
            {:ok, content} ->
              content
              |> :hex_registry.decode_signed()
              |> Map.fetch!(:payload)
              |> :hex_registry.decode_package(Urepo.name(), name)

            _ ->
              []
          end

        {name, releases}
      end

    {:ok, %__MODULE__{releases: releases}}
  end

  @impl true
  def handle_call({:add_release, name, release}, _ref, %{releases: releases} = state) do
    repo_name = Urepo.name()
    store = Urepo.store()
    private_key = Urepo.private_key()

    releases =
      Map.update(releases, name, [release], fn releases ->
        [release | releases]
        |> Enum.sort_by(& &1.version, {:desc, Version})
        |> Enum.dedup_by(& &1.version)
      end)

    Store.put(
      store,
      Path.join("packages", name),
      encode(
        :package,
        %{
          releases: Map.fetch!(releases, name),
          name: name,
          repository: repo_name
        },
        private_key
      )
    )

    names = Map.keys(releases) |> Enum.map(&%{name: &1})

    packages =
      Enum.map(releases, fn {name, releases} ->
        %{name: name, versions: Enum.map(releases, & &1.version), retired: []}
      end)

    Store.put(
      store,
      "names",
      encode(
        :names,
        %{
          packages: names,
          repository: repo_name
        },
        private_key
      )
    )

    Store.put(
      store,
      "versions",
      encode(
        :versions,
        %{
          packages: packages,
          repository: repo_name
        },
        private_key
      )
    )

    {:reply, :ok, struct(state, releases: releases)}
  end

  def handle_call({:get_releases, name}, _ref, %{releases: releases} = state) do
    {:reply, Map.fetch(releases, name), state}
  end

  defp encode(type, data, private_key) do
    apply(:hex_registry, :"encode_#{type}", [data])
    |> :hex_registry.sign_protobuf(private_key)
    |> :zlib.gzip()
  end
end
