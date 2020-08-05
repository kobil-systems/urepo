defmodule Urepo.Application do
  use Application

  def start(_type, _opts) do
    port = Application.fetch_env!(:urepo, :port)

    children = [
      Urepo.Repo,
      Urepo.Docs,
      {Plug.Cowboy, scheme: :http, plug: Urepo.Endpoint, options: [port: port]}
    ]

    opts = [
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, opts)
  end
end
