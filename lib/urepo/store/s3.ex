defmodule Urepo.Store.S3 do
  @behaviour Urepo.Store

  @impl true
  def put(path, content, opts) do
    bucket = Keyword.fetch!(opts, :bucket)

    ExAws.S3.put_object(bucket, path, content, acl: :public_read)
    |> ExAws.request!()

    :ok
  end

  @impl true
  def fetch(path, opts) do
    bucket = Keyword.fetch!(opts, :bucket)

    ExAws.S3.get_object(bucket, path)
    |> ExAws.request()
    |> case do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      error -> {:error, error}
    end
  end
end
