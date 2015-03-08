defmodule Blog.PageController do
  use Blog.Web, :controller

  plug :action

  def index(conn, _params) do
    render conn, "index.html"
  end
end
