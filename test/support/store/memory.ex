defmodule Urepo.Store.Memory do
  use GenServer

  @behaviour Urepo.Store

  def start_link(arg),
    do: GenServer.start_link(__MODULE__, arg, name: __MODULE__)

  @impl Urepo.Store
  def put(path, content, _opts),
    do: GenServer.cast(__MODULE__, {:put, path, content})

  @impl Urepo.Store
  def fetch(path, _opts),
    do: GenServer.call(__MODULE__, {:fetch, path})

  @impl GenServer
  def init(state) when is_map(state), do: {:ok, state}
  def init(_), do: {:ok, %{}}

  @impl GenServer
  def handle_call({:fetch, path}, _ref, data) do
    resp =
      with :error <- Map.fetch(data, path),
           do: {:error, :not_exists}

    {:reply, resp, data}
  end

  @impl GenServer
  def handle_cast({:put, path, content}, data) do
    {:noreply, Map.put(data, path, content)}
  end
end
