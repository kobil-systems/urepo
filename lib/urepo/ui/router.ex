defmodule Urepo.Ui.Router do
  use Plug.Router

  alias Urepo.Endpoint

  plug(:match)
  plug(:dispatch)

  get "/public.pem" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, Urepo.public_key())
  end

  get "/" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, """
    To install this repo run

    mix hex.repo add #{Urepo.name()} <store_url> --public-key <(curl #{
      Endpoint.route(conn, "/public.pem")
    } --auth-key <auth-key>
    """)
  end

  get _ do
    send_resp(conn, 404, "Not found")
  end
end
