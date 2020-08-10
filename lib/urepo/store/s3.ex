defmodule Urepo.Store.S3 do
  @moduledoc """
  Storage that uses AWS S3-compatible storage for storing packages.

  ## Options

  - `:bucket` - name of S3 bucket that will be used

  ## Additional configuration

  When using `Urepo.Store.S3` store then the `:ex_aws` need to be configured accordingly
  by setting either AWS standard environment variables, proper IAM roles, or by
  setting `:access_key_id` and `:secret_access_key` values for `:ex_aws`
  application:

  ```elixir
  config :ex_aws,
    access_key_id: "example_key_id",
    secret_access_key: "example_key"
  ```
  """

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

  @impl true
  def url(opts) do
    bucket = Keyword.fetch!(opts, :bucket)

    case ExAws.Config.new(:s3) |> ExAws.S3.presigned_url(:get, bucket, "") do
      {:ok, signed_url} ->
        url =
          signed_url
          |> URI.parse()
          |> struct(query: nil)
          |> URI.to_string()

        {:ok, url}

      _ ->
        :error
    end
  end
end
