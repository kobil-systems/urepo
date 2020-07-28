defmodule Urepo.APIRouter do
  use Plug.Router
  use Plug.ErrorHandler

  require Logger

  plug(:match)
  plug(:dispatch)

  get "/docs/:package" do
    case Urepo.Repo.get_releases(package) do
      {:ok, [current | _]} ->
        redirect(conn, route(conn, "/docs/#{package}/#{current.version}/index.html"))

      _ ->
        send_resp(conn, 404, "")
    end
  end

  get "/docs/:package/:version" do
    case Version.parse(version) do
      {:ok, _} -> redirect(conn, route(conn, "/docs/#{package}/#{version}/index.html"))
      _ -> send_resp(conn, 404, "")
    end
  end

  get "/docs/:package/:version/docs_config.js" do
    case Urepo.Repo.get_releases(package) do
      {:ok, releases} ->
        versions =
          for release <- releases do
            %{
              version: "v" <> release.version,
              url: route(conn, "/docs/#{package}/#{release.version}")
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

  get "/docs/:package/:version/*path" do
    case Urepo.Docs.file(package, version, Path.join(path)) do
      {:ok, content} -> send_resp(conn, 200, content)
      _ -> send_resp(conn, 404, "")
    end
  end

  get "/api/packages" do
    conn
    |> put_resp_content_type("application/vnd.hex+erlang")
    |> send_resp(200, :erlang.term_to_binary([]))
  end

  get "/api/packages/:name" do
    case Urepo.Repo.get_releases(name) do
      {:ok, releases} ->
        conn
        |> put_resp_content_type("application/vnd.hex+erlang")
        |> send_erlang(200, %{
          name: name,
          url: route(conn, ""),
          meta: %{
            maintainers: [],
            links: [],
            licenses: []
          },
          releases:
            for(
              rel <- releases,
              do: %{version: rel.version, url: route(conn, "release/#{rel.version}")}
            )
        })

      _ ->
        send_resp(conn, 404, "")
    end
  end

  get "/api/packages/:name/release/:version" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(501, "{}")
  end

  post "/api/publish" do
    {:ok, tarball, conn} = read_tarball(conn)

    {:ok, _release} = Urepo.publish_release(tarball)

    conn
    |> put_resp_content_type("application/vnd.hex+erlang")
    |> send_erlang(201, %{url: route(conn, "/repo")})
  end

  post "/api/packages/:name/releases/:version/docs" do
    {:ok, tarball, conn} = read_tarball(conn)

    case Urepo.publish_docs(name, version, tarball) do
      :ok ->
        conn
        |> put_resp_header("location", route(conn, "/docs/#{name}/#{version}/index.html"))
        |> send_resp(:created, "")

      {:error, _} = error ->
        send_resp(conn, 400, inspect(error))
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  @spec route(Plug.Conn.t(), binary()) :: binary()
  defp route(conn, path) do
    uri = %URI{
      authority: "#{conn.host}:#{conn.port}",
      host: conn.host,
      port: conn.port,
      scheme: Atom.to_string(conn.scheme),
      path: conn.request_path
    }

    uri
    |> URI.merge(path)
    |> URI.to_string()
  end

  defp send_erlang(conn, code, term) do
    conn
    |> put_resp_content_type("application/vnd.hex+erlang")
    |> send_resp(code, encode(term))
  end

  defp encode(term), do: term |> do_encode() |> :erlang.term_to_binary()

  defp do_encode(%{} = map), do: Map.new(map, fn {k, v} -> {to_string(k), do_encode(v)} end)
  defp do_encode(list) when is_list(list), do: Enum.map(list, &do_encode/1)
  defp do_encode(other), do: other

  @spec redirect(Plug.Conn.t(), binary()) :: Plug.Conn.t()
  defp redirect(conn, url) do
    html = Plug.HTML.html_escape(url)
    body = "<html><body>You are being <a href=\"#{html}\">redirected</a>.</body></html>"

    conn
    |> put_resp_header("location", url)
    |> put_resp_content_type("text/html")
    |> send_resp(conn.status || 302, body)
  end

  defp read_tarball(conn, tarball \\ []) do
    case Plug.Conn.read_body(conn) do
      {:more, partial, conn} ->
        read_tarball(conn, [tarball, partial])

      {:ok, body, conn} ->
        {:ok, IO.iodata_to_binary([tarball, body]), conn}

      {:error, _} = error ->
        error
    end
  end

  def handle_errors(conn, error) do
    send_resp(conn, conn.status, "Something went wrong: #{inspect(error)}")
  end
end
