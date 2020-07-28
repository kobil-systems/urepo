defmodule Urepo.Store do
  @callback put(path :: binary(), content :: iodata(), opts :: keyword()) ::
              :ok | {:error, term()}
  @callback fetch(path :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, term()}

  def put({mod, state}, path, content, opts \\ []) do
    full_opts = Keyword.merge(state, opts)

    mod.put(path, content, full_opts)
  end

  def fetch({mod, state}, path, opts \\ []) do
    full_opts = Keyword.merge(state, opts)

    mod.fetch(path, full_opts)
  end
end
