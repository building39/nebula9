defmodule WebulaWeb.PageController do
  use WebulaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
