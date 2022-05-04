defmodule Urepo.Repo do
  @moduledoc """
  Repo builder and cache.

  ## TODO

  - Heavily refactor this module as it is currently humongous monster
  """

  @dialyzer no_return: [store: 3], no_unused: [store: 2]

  use GenServer

  require Logger

  alias Urepo.Store
  alias Urepo.Utils

  @name __MODULE__

  defstruct releases: %{}

  def start_link(store) do
    GenServer.start_link(__MODULE__, store, name: @name)
  end

  @doc """
  Add new release to the package `name`
  """
  @spec add(name :: binary(), release :: map()) :: :ok | {:error, term()}
  def add(name, release) do
    GenServer.call(@name, {:add_release, name, release})
  end

  @doc """
  Get releases for given package
  """
  @spec get_releases(name :: binary()) :: {:ok, [map()]} | {:error, term()}
  def get_releases(name) do
    GenServer.call(@name, {:get_releases, name})
  end

  @impl true
  def init(_opts) do
    store = Urepo.store()

    names =
      with {:ok, raw} <- Store.fetch(store, "names"),
           {:ok, data} <- Utils.verify(raw),
           {:ok, names} <- :hex_registry.decode_names(data, Urepo.name()) do
        names
      else
        _ -> []
      end

    Logger.debug("Loaded packages: #{inspect(names)}")

    releases =
      for %{name: name} <- names, into: %{} do
        path = Path.join(["packages", name])

        releases =
          with {:ok, raw} <- Store.fetch(store, path),
               {:ok, data} <- Utils.verify(raw),
               {:ok, package} <- :hex_registry.decode_package(data, Urepo.name(), name) do
            package
          else
            _ -> []
          end

        Logger.debug("Loaded releases for package #{name}")

        {name, releases}
      end

    {:ok, %__MODULE__{releases: releases}}
  end

  @impl true
  def handle_call({:add_release, name, release}, _ref, %{releases: releases} = state) do
    repo_name = Urepo.name()

    by = & &1.version

    {package, releases} =
      Map.get_and_update(releases, name, fn
        nil ->
          {[release], [release]}

        old when is_list(old) ->
          new = Utils.append_version_for_packages(old, release, by)
          {new, new}
      end)

    %{
      releases: package,
      name: name,
      repository: repo_name
    }
    |> store(:package, ["packages", name])

    {names, packages} =
      Enum.reduce(releases, {[], []}, fn {name, releases}, {names, packages} ->
        package = %{name: name, versions: Enum.map(releases, & &1.version), retired: []}
        {[%{name: name} | names], [package | packages]}
      end)

    %{
      packages: names,
      repository: repo_name
    }
    |> store(:names)

    %{
      packages: packages,
      repository: repo_name
    }
    |> store(:versions)

    {:reply, :ok, struct(state, releases: releases)}
  end

  def handle_call({:get_releases, name}, _ref, %{releases: releases} = state) do
    {:reply, Map.fetch(releases, name), state}
  end

  defp store(data, type), do: store(data, type, to_string(type))

  defp store(data, type, path) do
    store = Urepo.store()

    content =
      apply(:hex_registry, :"encode_#{type}", [data])
      |> Urepo.Utils.sign()

    Store.put(store, Path.join(List.wrap(path)), content)
  end
end
