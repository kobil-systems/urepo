defmodule Urepo.Application do
  use Application

  def start(_type, _opts) do
    children = [
      Urepo.Repo,
      Urepo.Docs,
      {Plug.Cowboy, scheme: :http, plug: Urepo.Endpoint, options: [port: 4040]}
    ]

    opts = [
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, opts)
  end
end
