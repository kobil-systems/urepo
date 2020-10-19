defmodule Urepo.Plugs.Health do
  @behaviour Plug

  def init(_), do: []

  def call(%Plug.Conn{path_info: ["health" | _]} = conn, _opts) do
    version = Application.spec(:urepo, :vsn) |> to_string()
    docs_count = Urepo.Docs.count()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(:ok, Jason.encode_to_iodata!(%{
      version: version,
      counts: %{
        docs: docs_count
      }
    }))
    |> Plug.Conn.halt()
  end

  def call(conn, _opts), do: conn
end
