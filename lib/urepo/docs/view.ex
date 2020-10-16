defmodule Urepo.Docs.View do
  @moduledoc false

  require EEx

  import Urepo.Endpoint, only: [route: 2]

  def send(conn, status \\ 200, name, assigns) do
    rendered = apply(__MODULE__, name, [Keyword.put(assigns, :conn, conn)])

    Plug.Conn.send_resp(conn, status, rendered)
  end

  EEx.function_from_string(:def, :index, """
  <html>
    <head><title>Documented packages</title></head>
    <body>
      <ul>
        <%= for name <- @names do %>
          <li><a href="<%= route(@conn, name) %>"><%= name %></a></li>
        <% end %>
      </ul>
    </body>
  </html>
  """, [:assigns])
end
