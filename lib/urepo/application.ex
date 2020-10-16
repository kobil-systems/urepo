defmodule Urepo.Application do
  @moduledoc false

  require Logger

  use Application

  def start(_type, _opts) do
    _ = :logger.remove_handler(:default)
    :ok = :logger.add_handlers(:urepo)

    port = Application.fetch_env!(:urepo, :port)

    children = [
      Urepo.Repo,
      Urepo.Docs,
      {Plug.Cowboy, scheme: :http, plug: Urepo.Endpoint, options: [port: port]},
      :systemd.ready(),
      {Task, fn -> Logger.info("Listening on :#{port}") end},
      {Plug.Cowboy.Drainer, refs: :all}
    ]

    opts = [
      strategy: :one_for_one
    ]

    _ = setup()

    Supervisor.start_link(children, opts)
  end

  defp setup do
    [
      Urepo.Plugs.Exporter,
      Urepo.Plugs.Instrumenter
    ]
    |> Enum.each(& &1.setup())
  end
end
