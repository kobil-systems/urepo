defmodule Urepo do
  alias Urepo.Store
  alias Urepo.Repo

  @type tarball() :: iodata()

  @doc """
  Publish release for given tarball.
  """
  @spec publish_release(tarball()) :: {:ok, map()} | {:error, term()}
  def publish_release(tarball) do
    store = store()

    with {:ok, {name, release}} <- Repo.Release.from_tarball(tarball) do
      Repo.add(name, release)

      Store.put(store, Path.join(["tarballs", "#{name}-#{release.version}.tar"]), tarball)

      {:ok, release}
    end
  end

  @doc """
  Publish documentation for package `name` with `version` using `tarball`.
  """
  @spec publish_docs(name :: binary(), version :: binary(), tarball()) ::
          :ok | {:error, term()}
  def publish_docs(name, version, tarball) do
    store = store()

    with :ok <- Store.put(store, Path.join(["docs", "#{name}-#{version}.tar"]), tarball),
         do: :ok
  end

  @doc """
  Load documentation from the store for given package and version.
  """
  @spec get_docs(name :: binary(), version :: binary()) ::
          {:ok, [{Path.t(), iodata()}]} | {:error, term()}
  def get_docs(name, version) do
    with {:ok, tarball} <- Store.fetch(store(), Path.join(["docs", "#{name}-#{version}.tar"])),
         {:ok, files} <- :hex_tarball.unpack_docs(tarball, :memory),
         do: {:ok, files}
  end

  @doc "Get name for the current repository"
  def name, do: Application.fetch_env!(:urepo, :name)

  @doc "Get store configuration for current repository"
  def store, do: Application.fetch_env!(:urepo, :store)

  @doc "Get content of PEM encoded file containing private key"
  def private_key, do: File.read!(Application.get_env(:urepo, :private_key))

  @doc "Get content of PEM encoded file containing public key"
  def public_key, do: File.read!(Application.get_env(:urepo, :public_key))
end
