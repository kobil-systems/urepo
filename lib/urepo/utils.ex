defmodule Urepo.Utils do
  def append_version(enumerable, new) do
    enumerable
    |> Enum.concat(List.wrap(new))
    |> Enum.sort({:desc, Version})
    |> Enum.dedup()
  end

  def append_version(enumerable, new, by) do
    enumerable
    |> Enum.concat(List.wrap(new))
    |> Enum.sort_by(by, {:desc, Version})
    |> Enum.dedup_by(by)
  end

  def sign(data) do
    data
    |> :hex_registry.sign_protobuf(Urepo.private_key())
    |> :zlib.gzip()
  end

  def verify(data) do
    data
    |> :zlib.gunzip()
    |> :hex_registry.decode_and_verify_signed(Urepo.public_key())
  end
end
