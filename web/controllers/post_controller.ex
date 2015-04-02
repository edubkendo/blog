defmodule Blog.PostController do
  use Blog.Web, :controller

  alias Blog.Post
  import Ecto.Query

  plug :action

  def index(conn, _params) do
    query = from p in Post,
      order_by: [asc: p.date]
    posts = Repo.all(query)
    render conn, "index.html", posts: posts
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get(Post, id)
    output = Path.join("posts", post.file)
      |> File.read!
      |> Earmark.to_html
    put_layout(conn, "post.html")
    |> render "show.html", post: post, output: output
  end
end
