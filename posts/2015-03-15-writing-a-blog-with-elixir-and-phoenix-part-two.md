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

You may want to add the file `config/prod.secret.exs` to your gitignore. You'll need to copy `config/prod.secret.exs` somewhere, use `git rm config/prod.secret.exs` to remove it, then once you `git add .gitignore` and commit, you can copy it back in, it should prevent it from getting added back in. In order to deploy to production, you'll need to put production database details in this file, so you'll want to be sure you do not commit those to git. In more sophisticated deployments you may even want to have its creation scripted.

A further step I personally took, was to take local database details out of dev.exs as well. That works like this.

First, change `config/dev.exs` like this:

```elixir
use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :blargh, Blargh.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  cache_static_lookup: false,
  watchers: [{Path.expand("node_modules/brunch/bin/brunch"), ["watch"]}]

# Watch static and templates for browser reloading.
# *Note*: Be careful with wildcards. Larger projects
# will use higher CPU in dev as the number of files
# grow. Adjust as necessary.
config :blargh, Blargh.Endpoint,
  live_reload: [Path.expand("priv/static/js/app.js"),
                Path.expand("priv/static/css/app.css"),
                Path.expand("web/templates/**/*.eex")]

# Enables code reloading for development
config :phoenix, :code_reloader, true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Configure your database
config :blargh, Blargh.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DATABASE_USER"),
  password: System.get_env("DATABASE_PASSWORD"),
  database: System.get_env("DATABASE_NAME"),
  port: (System.get_env("PGPORT") |> String.to_integer)

```
Now, create a file in the root of your project called `.env.example` like so:

```sh
export DATABASE_USER=postgres
export DATABASE_PASSWORD=postgres
export DATABASE_NAME=blargh_dev
export PGPORT=5432
```

Be sure to put default, unspecific examples for the variables. Now, run `cp .env.example .env` and go into the real `.env` file and change the example values for the real one. Now, any time you open a shell to work locally on this app, you can just run `. .env` to load those environment variables into the shell. Your config will pick them up and use them.

This really only has benefits on projects with more than one developer, but because for me this blog is a practice run at doing a "production" Elixir app, I wanted to solve this problem. Now, any other developer who was to work on this project with me could configure for their local environment. Other solutions to this same problem include the use of either a VM image, via something like Vagrant. Or something like docker's linux containers. I plan to experiment with docker soon, as it also solves some other problems with development and deploying that I find interesting. But I've drifted far off topic.

Open `mix.exs` and get ready to make a few changes to prepare it for deploy. First, we're going to add all of our dependencies to the `application` function. This will help when we prepare our release, as it will tell [exrm](https://github.com/bitwalker/exrm) which dependencies to pack into the release.

```elixir
  def application do
    [mod: {Blog, []},
     applications: [:phoenix, :cowboy, :phoenix_ecto, :postgrex, :earmark, :logger]]
  end
```

Now, let's add the previously mentioned `exrm` to our dependencies. At this point they should look about like this:

```elixir
  defp deps do
    [{:phoenix, "~> 0.10.0"},
     {:phoenix_ecto, "~> 0.1"},
     {:postgrex, ">= 0.0.0"},
     {:earmark, "~> 0.1.13"},
     {:exrm, "~> 0.15.3"},
     {:cowboy, "~> 1.0"}]
  end
```

Now once more, `mix deps.get`, `mix deps.compile`. 

Open up `config/prod.exs` and around line 35 find the following line and uncomment it:

```elixir
     config :phoenix, :serve_endpoints, true
```

When we run our project with `mix phoenix.server` it knows to start it as a server, but when we run it in production we won't be starting it that way so we have to tell phoenix to start the server up.

One of the roadbumps I've run into is that when using `exrm` to generate a `release`, you need to do so on an operating system very similar to the operating system it's going to run on. The server I'm planning to deploy to is an [digitalocean](https://www.digitalocean.com/) machine running 64-bit Ubuntu 14.04. Since I primarily develop on OSX, there are a couple of options: build on a VM, use [docker](https://www.docker.com/), or transfer the code to the server and do the build there.

