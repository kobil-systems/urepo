defmodule Urepo.Store do
  @moduledoc """
  Definition of store for repo files
  """

  @callback put(path :: binary(), content :: iodata(), opts :: keyword()) ::
              :ok | {:error, term()}
  @callback fetch(path :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, term()}
  @callback url(opts :: keyword()) :: {:ok, binary()} | :error

  @optional_callbacks url: 1

  def put({mod, state}, path, content, opts \\ []) do
    full_opts = Keyword.merge(state, opts)

    mod.put(path, content, full_opts)
  end

  def fetch({mod, state}, path, opts \\ []) do
    full_opts = Keyword.merge(state, opts)

    mod.fetch(path, full_opts)
  end

  def url({mod, state}, opts \\ []) do
    case function_exported?(mod, :url, 1) do
      true ->
        full_opts = Keyword.merge(state, opts)

        mod.url(full_opts)

      _ ->
        :error
    end
  end
end
