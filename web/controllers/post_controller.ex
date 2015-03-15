defmodule Blog.PostController do
  use Blog.Web, :controller

  alias Blog.Post

  plug :action

  def index(conn, _params) do
    posts = Repo.all(Post)
    render conn, "index.html", posts: posts
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get(Post, id)
    render conn, "show.html", post: post
  end
end
