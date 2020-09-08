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
        |> Plug.forward(rest, Urepo.API.Router, [])

      %Plug.Conn{path_info: ["repo" | rest]} ->
        conn
        |> put_private(:prefix, "/repo/")
        |> Plug.forward(rest, Urepo.Repo.Redirect, [])

      _ ->
        Urepo.Ui.Router.call(conn, [])
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

  @spec redirect(Plug.Conn.t(), binary()) :: Plug.Conn.t()
  def redirect(conn, url) do
    html = Plug.HTML.html_escape(url)
    body = "<html><body>You are being <a href=\"#{html}\">redirected</a>.</body></html>"

    conn
    |> put_resp_header("location", url)
    |> put_resp_content_type("text/html")
    |> send_resp(conn.status || 302, body)
  end

  def handle_errors(conn, %{kind: type, reason: reason, stack: stack}) do
    send_resp(conn, conn.status, Exception.format(type, reason, stack))
  end

  def handle_errors(conn, error) do
    send_resp(conn, conn.status, "Something went wrong: #{inspect(error)}")
  end
end
