defmodule Urepo.Utils do
  @moduledoc false

  @dialyzer no_return: [sign: 1]

  @doc """
  Add new version to the enumerable. Resulting enumerable will be deduplicated
  and will be sorted by versions in decreasing order (highest version first).
  """
  def append_version(enumerable, new) do
    enumerable
    |> Enum.concat(List.wrap(new))
    |> Enum.sort({:desc, Version})
    |> Enum.dedup()
  end

  @doc """
  Add new version to the enumerable and then sort using value returned by
  `by` callback.
  """
  def append_version(enumerable, new, by) do
    enumerable
    |> Enum.concat(List.wrap(new))
    |> Enum.sort_by(by, {:desc, Version})
    |> Enum.dedup_by(by)
  end

  @doc """
  Sign provided binary data using configured private key and compress it
  using `:zlib.gzip/1`.
  """
  def sign(data) when is_binary(data) do
    data
    |> :hex_registry.sign_protobuf(Urepo.private_key())
    |> :zlib.gzip()
  end

  @doc """
  Decompress `data` and check if the signature is correct by using configured
  public key.
  """
  def verify(data) do
    data
    |> :zlib.gunzip()
    |> :hex_registry.decode_and_verify_signed(Urepo.public_key())
  end
end
