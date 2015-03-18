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
    Application.ensure_all_started(:blog)
    Mix.shell.info "Accumulating posts..."
    Blog.PostBuilder.add_to_db
    Mix.shell.info "Done!"
  end
end
