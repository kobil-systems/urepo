defmodule Urepo.Store.Local do
  @behaviour Urepo.Store

  require Logger

  @impl true
  def put(path, content, opts) do
    root = Keyword.fetch!(opts, :path)
    file_path = Path.join(root, path)

    Logger.debug("Saving data to #{file_path}")

    with :ok <-
           file_path
           |> Path.dirname()
           |> File.mkdir_p(),
         :ok <- File.write(file_path, content),
         do: :ok
  end

  @impl true
  def fetch(path, opts) do
    root = Keyword.fetch!(opts, :path)
    file_path = Path.join(root, path)

    Logger.debug("Fetching data form #{file_path}")

    with :ok <-
           file_path
           |> Path.dirname()
           |> File.mkdir_p(),
         {:ok, content} <- File.read(file_path),
         do: {:ok, content}
  end
end
