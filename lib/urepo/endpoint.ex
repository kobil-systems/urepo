defmodule Urepo.Endpoint do
  @moduledoc false

  use Plug.Builder
  use Plug.ErrorHandler

  alias Urepo.Plugs

  plug(Plug.Logger)
  plug(Plugs.Exporter)
  plug(Plugs.Instrumenter)
  plug(:forward)

  defp forward(conn, _opts) do
    case conn do
      %Plug.Conn{path_info: ["docs" | rest]} ->
        conn
        |> put_private(:prefix, "/docs/")
        |> Plug.forward(rest, Urepo.Docs.Router, [])

      %Plug.Conn{path_info: ["api" | rest]} ->
        conn
        |> put_private(:prefix, "/api/")
        |> Plug.forward(rest, Urepo.Repo.Router, [])

      _ ->
        Plug.Conn.send_resp(conn, 404, "Not found")
    end
  end

  @spec route(Plug.Conn.t(), binary()) :: binary()
  def route(conn, path) do
    prefix = conn.private[:prefix]

    uri = %URI{
      authority: "#{conn.host}:#{conn.port}",
      host: conn.host,
      port: conn.port,
      scheme: Atom.to_string(conn.scheme),
      path: prefix
    }

    uri
    |> URI.merge(Path.join(List.wrap(path)))
    |> URI.to_string()
  end

  def handle_errors(conn, error) do
    send_resp(conn, conn.status, "Something went wrong: #{inspect(error)}")
  end
end
