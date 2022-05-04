defmodule Urepo.Utils do
  @moduledoc false

  @dialyzer no_return: [sign: 1]

  @doc """
  Add new version to the enumerable. Resulting enumerable will be deduplicated
  and will be sorted by versions in decreasing order (highest version first).
  """
  def append_version_for_docs(enumerable, new) do
    enumerable
    |> Enum.concat(List.wrap(new))
    |> Enum.sort({:desc, Version})
    |> Enum.dedup()
  end

  @doc """
  Add new version to the enumerable. Resulting enumerable will be deduplicated
  and sorted using value returned by the `by` callback in
  ascending order (lowest version first).
  """
  def append_version_for_packages(enumerable, new, by) do
    enumerable
    |> Enum.concat(List.wrap(new))
    |> Enum.sort_by(by, {:asc, Version})
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
