# Writing a Blog with Elixir and Phoenix pt. 2
## Loose Ends & Deployment

To begin, we don't want to have to open up a REPL every time we write a new post, so we'll wrap our `Blog.PostBuilder.add_to_db` method in a `Mix.Task`. Create the file `lib/tasks/accumulate.ex` and give it these contents:

```elixir
defmodule Mix.Tasks.Accumulate do
  use Mix.Task

  @shortdoc "A task for accumulating the posts in `/posts`."

  @moduledoc """
  Running this task will collect all the posts in the `/posts` directory
  (which must be named according to the scheme YYYY-MM-DD-post-name.md)
  and persist information about them to the database, making them available
  on the blog.
  """

  def run([]) do
    Application.ensure_all_started(:blargh)
    Mix.shell.info "Accumulating posts..."
    Blog.PostBuilder.add_to_db
    Mix.shell.info "Done!"
  end
end
```

This is fairly simple. Because of the way Erlang (and Elixir) applications work, we need to make sure everything has been started so that we have access to all the functionality `Blog.PostBuilder` needs, then we output some information to the user so they know the process is working. Finally, we call our function which does most of the work before letting the user know the process finished.

In your shell, run `mix compile`, followed by `mix help` and you should see your task listed near the top as `mix accumulate`. Add a new post to your `/posts` directory and you can then run `mix accumulate` to see it work. The new post should now appear in the posts listed at [http://localhost:4000](http://localhost:4000).
