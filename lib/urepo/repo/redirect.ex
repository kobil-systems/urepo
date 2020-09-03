defmodule Urepo.Repo.Redirect do
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case Urepo.store_content(Path.join(conn.path_info)) do
      {:url, url} ->
        Urepo.Endpoint.redirect(conn, url)
      {:content, content} ->
        send_resp(conn, 200, content)
      :error ->
        send_resp(conn, 404, "")
    end
  end
end
