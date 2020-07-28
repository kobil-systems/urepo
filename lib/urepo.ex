defmodule Urepo do
  alias Urepo.Store

  def publish_release(tarball) do
    store = store()

    with {:ok, {name, release}} <- Urepo.Release.from_tarball(tarball) do
      Urepo.Repo.add(name, release)

      Store.put(store, Path.join(["tarballs", "#{name}-#{release.version}.tar"]), tarball)

      {:ok, release}
    end
  end

  def publish_docs(name, version, tarball) do
    store = store()

    with :ok <- Store.put(store, Path.join(["docs", "#{name}-#{version}.tar"]), tarball),
         do: :ok
  end

  def get_docs(name, version) do
    with {:ok, tarball} <- Store.fetch(store(), Path.join(["docs", "#{name}-#{version}.tar"])),
         {:ok, files} <- :hex_tarball.unpack_docs(tarball, :memory),
         do: {:ok, files}
  end

  def name, do: Application.get_env(:urepo, :name, "urepo")

  def store, do: Application.fetch_env!(:urepo, :store)

  def private_key, do: File.read!(Application.get_env(:urepo, :private_key))
  def public_key, do: File.read!(Application.get_env(:urepo, :public_key))
end
