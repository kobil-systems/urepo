defmodule Urepo.Store.GoogleCloudStorage do
  @moduledoc """
  Storage that uses Google Cloud Platform's Google Cloud Storage (GCS) for storing packages.

  ## Options

  - `:bucket` - name of GCS bucket that will be used

  ## Additional configuration

  When using `Urepo.Store.S3` store then `:goth` need to be configured accordingly
  with the appropriate service account credentials.

  ```elixir
  config :goth,
    json: "path/to/google/json/creds.json" |> File.read!
  ```

  or

  ```elixir
  config :goth, json: {:system, "GCP_CREDENTIALS"}
  ```
  """

  @behaviour Urepo.Store

  @impl true
  def put(path, content, opts) do
    bucket = Keyword.fetch!(opts, :bucket)

    GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_iodata(
      conn(),
      bucket,
      "multipart",
      %{name: path},
      content
    )
  end

  @impl true
  def fetch(path, opts) do
    bucket = Keyword.fetch!(opts, :bucket)

    GoogleApi.Storage.V1.Api.Objects.storage_objects_get(
      conn(),
      bucket,
      path,
      [alt: "media"],
      decode: false
    )
    |> case do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      error -> {:error, error}
    end
  end

  defp conn() do
    # Authenticate.
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    GoogleApi.Storage.V1.Connection.new(token.token)
  end
end
