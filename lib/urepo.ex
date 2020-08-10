defmodule Urepo do
  @moduledoc """
  Entyrpoint module for μRepo
  """

  alias Urepo.Repo
  alias Urepo.Store

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

  @doc "Get name for the current repository"
  def name, do: Application.fetch_env!(:urepo, :name)

  @doc "Get store configuration for current repository"
  def store, do: Application.fetch_env!(:urepo, :store)

  @doc "Get content of PEM encoded file containing private key"
  def private_key, do: File.read!(Application.get_env(:urepo, :private_key))

  @doc "Get content of PEM encoded file containing public key"
  def public_key, do: File.read!(Application.get_env(:urepo, :public_key))
end
