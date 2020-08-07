defmodule Urepo.Docs.RouterTest do
  use ExUnit.Case
  use Plug.Test

  import Urepo.Fixtures

  alias Urepo.Store.Memory, as: Store

  @subject Urepo.Docs.Router

  setup do
    start_supervised!(Store)
    Application.put_env(:urepo, :store, {Store, []})

    Application.ensure_all_started(:urepo)
    on_exit(fn ->
      Application.stop(:urepo)
    end)

    assert :ok = Urepo.Docs.publish("example", "0.1.0", fixture("docs/example-0.1.0.tar"))

    :ok
  end

  test "using just package name redirects to version" do
    conn =
      conn(:get, "/example")
      |> send()

    assert conn.status == 302
    assert ["http://www.example.com/example/0.1.0/index.html"] == get_resp_header(conn, "location")
  end

  test "using package name and version redirect to index" do
    conn =
      conn(:get, "/example/0.1.0")
      |> send()

    assert conn.status == 302
    assert ["http://www.example.com/example/0.1.0/index.html"] == get_resp_header(conn, "location")
  end

  test "can fetch index.html of the package" do
    conn =
      conn(:get, "/example/0.1.0/index.html")
      |> send()

    assert conn.status == 200
  end

  test "docs_config.js contain all versions" do
    conn =
      conn(:get, "/example/0.1.0")
      |> send()

    assert conn.status == 302
    assert ["http://www.example.com/example/0.1.0/index.html"] == get_resp_header(conn, "location")
  end

  defp send(conn), do: @subject.call(conn, [])
end
