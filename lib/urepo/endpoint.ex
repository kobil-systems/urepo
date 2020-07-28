defmodule Urepo.Endpoint do
  use Plug.Builder

  plug(Plug.Static,
    at: "/repo",
    from: "repo"
  )

  plug(Plug.Logger)
  plug(Urepo.APIRouter)
end
