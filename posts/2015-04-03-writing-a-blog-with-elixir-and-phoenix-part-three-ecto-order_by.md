# Writing A Blog With Elixir And Phoenix Part 3 (Ecto's order_by)

It was brought to my attention that on the blog's index page, posts were out of order. This was a very simple fix, we simply use an `Ecto` query with an `order_by` parameter in our index function.

`web/controllers/post_controller.ex`

```elixir
defmodule Blog.PostController do
  use Blog.Web, :controller

  alias Blog.Post
  import Ecto.Query

  plug :action

  def index(conn, _params) do
    query = from p in Post,
      order_by: [asc: p.date]

    # we pass the query now, instead of the Post model module
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
```

A simple fix. Then we just rebuild the docker image with a new version number like:

```
$ docker build -t edubkendo/blog:v8.3.4 .
```

Push that up to docker-hub with:

```
$ docker push edubkendo/blog:v8.3.4
```

SSH onto our server, and pull down the new image:

```
$ docker pull edubkendo/blog:v8.3.4
```

Now stop and remove the blog and nginx containers:

```
$ docker stop blog
$ docker rm blog
$ docker stop nginx
$ docker rm nginx
```

Then just re-run them both:

```
$ docker run -p 4000 --name blog --link blog-postgres:postgres -d edubkendo/blog:v8.3.4
$ docker run --name nginx --link blog:blog -p 80:80 -d edubkendo/nginx
```

And visit it in the browser to be sure everything is working. Of course, be sure to substitute your own user, image and container names.
