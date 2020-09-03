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

  def store_content(path) do
    store = store()

    case Store.url(store, path) do
      {:ok, url} -> {:url, url}
      :error ->
        with {:ok, content} <- Store.fetch(store, path),
             do: {:content, content}
    end
  end

  @doc "Get name for the current repository"
  def name, do: Application.fetch_env!(:urepo, :name)

  @doc "Get store configuration for current repository"
  def store, do: Application.fetch_env!(:urepo, :store)

  @doc "Get content of PEM encoded file containing private key"
  def private_key do
    perm_get(:private_key, fn ->
      Application.fetch_env!(:urepo, :private_key)
      |> File.read!()
    end)
  end

  @doc "Get content of PEM encoded file containing public key"
  def public_key do
    perm_get(:public_key, fn ->
      case Application.fetch_env(:urepo, :public_key) do
        {:ok, path} ->
          File.read!(path)

        :error ->
          private_key()
          |> :public_key.pem_decode()
          |> Enum.map(&:public_key.pem_entry_decode/1)
          |> hd()
          |> extract_public_key()
          |> pem_encode(:RSAPublicKey)
      end
    end)
  end

  defp perm_get(key, cb) do
    key = {__MODULE__, key}

    case :persistent_term.get(key, nil) do
      nil ->
        data = cb.()
        :ok = :persistent_term.put(key, data)
        data

      data ->
        data
    end
  end

  def generate_keys do
    {:ok, private_key} = generate_rsa_key(2048, 65_537)
    public_key = extract_public_key(private_key)
    {pem_encode(private_key, :RSAPrivateKey), pem_encode(public_key, :RSAPublicKey)}
  end

  require Record

  Record.defrecord(
    :rsa_private_key,
    :RSAPrivateKey,
    Record.extract(:RSAPrivateKey, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecord(
    :rsa_public_key,
    :RSAPublicKey,
    Record.extract(:RSAPublicKey, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  defp pem_encode(key, type) do
    :public_key.pem_encode([:public_key.pem_entry_encode(type, key)])
  end

  defp generate_rsa_key(keysize, e) do
    private_key = :public_key.generate_key({:rsa, keysize, e})
    {:ok, private_key}
  rescue
    FunctionClauseError ->
      {:error, :not_supported}
  end

  defp extract_public_key(rsa_private_key(modulus: m, publicExponent: e)) do
    rsa_public_key(modulus: m, publicExponent: e)
  end
end
