defmodule Urepo.Repo.Router do
  @moduledoc false

  use Plug.Router

  import Urepo.Endpoint, only: [route: 2]

  plug(:auth)
  plug(:match)
  plug(:dispatch)

  get "/packages" do
    send_erlang(conn, 200, [])
  end

  get "/packages/:name" do
    case Urepo.Repo.get_releases(name) do
      {:ok, releases} ->
        conn
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

  get "/packages/:name/release/:version" do
    conn
    |> send_erlang(501, %{})
  end

  post "/publish" do
    {:ok, tarball, conn} = read_tarball(conn)

    {:ok, _release} = Urepo.publish_release(tarball)

    conn
    |> put_resp_content_type("application/vnd.hex+erlang")
    |> send_erlang(201, %{url: route(conn, "")})
  end

  post "/packages/:name/releases/:version/docs" do
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

  defp auth(conn, _opts) do
    token = Application.fetch_env!(:urepo, :token)

    with [auth] <- get_req_header(conn, "authorization"),
         true <- Plug.Crypto.secure_compare(auth, token) do
      conn
    else
      _ ->
        send_erlang(conn, 401, "unauthorized")
    end
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
end
