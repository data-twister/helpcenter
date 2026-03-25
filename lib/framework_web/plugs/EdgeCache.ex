defmodule FrameworkWeb.Plugs.EdgeCache do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.method == "GET" do
      conn
      |> put_resp_header("cache-control", "public, max-age=60")
      |> put_resp_header("vary", "host")
    else
      conn
    end
  end
end
