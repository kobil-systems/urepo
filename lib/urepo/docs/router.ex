defmodule Urepo.Docs.Router do
  @moduledoc false

  use Plug.Router

  import Urepo.Endpoint, only: [route: 2]

  plug(:match)
  plug(:dispatch)

  get "/:package" do
    case Urepo.Repo.get_releases(package) do
      {:ok, [current | _]} ->
        redirect(conn, route(conn, "#{package}/#{current.version}/index.html"))

      _ ->
        send_resp(conn, 404, "")
    end
  end

  get "/:package/:version" do
    case Version.parse(version) do
      {:ok, _} -> redirect(conn, route(conn, "#{package}/#{version}/index.html"))
      _ -> send_resp(conn, 404, "")
    end
  end

  get "/:package/:version/docs_config.js" do
    case Urepo.Repo.get_releases(package) do
      {:ok, releases} ->
        versions =
          for release <- releases do
            %{
              version: "v" <> release.version,
              url: route(conn, "#{package}/#{release.version}")
            }
          end

        send_resp(conn, 200, [
          "var versionNodes=",
          Jason.encode_to_iodata!(versions),
          ";"
        ])

      _ ->
        send_resp(conn, 200, "")
    end
  end

  get "/:package/:version/*path" do
    case Urepo.Docs.file(package, version, Path.join(path)) do
      {:ok, content} -> send_resp(conn, 200, content)
      _ -> send_resp(conn, 404, "")
    end
  end

  @spec redirect(Plug.Conn.t(), binary()) :: Plug.Conn.t()
  defp redirect(conn, url) do
    html = Plug.HTML.html_escape(url)
    body = "<html><body>You are being <a href=\"#{html}\">redirected</a>.</body></html>"

    conn
    |> put_resp_header("location", url)
    |> put_resp_content_type("text/html")
    |> send_resp(conn.status || 302, body)
  end
end
