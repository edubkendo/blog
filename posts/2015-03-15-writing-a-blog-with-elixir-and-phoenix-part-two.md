# Writing a Blog with Elixir and Phoenix pt. 2 (& Docker)
## Loose Ends & Deployment

To begin, we don't want to have to open up a REPL every time we write a new post, so we'll wrap our `Blargh.PostBuilder.add_to_db` method in a `Mix.Task`. Create the file `lib/tasks/accumulate.ex` and give it these contents:

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
    Blargh.PostBuilder.add_to_db
    Mix.shell.info "Done!"
  end
end
```

This is fairly simple. Because of the way Erlang (and Elixir) applications work, we need to make sure everything has been started so that we have access to all the functionality `Blargh.PostBuilder` needs, then we output some information to the user so they know the process is working. Finally, we call our function which does most of the work before letting the user know the process finished.

In your shell, run `mix compile`, followed by `mix help` and you should see your task listed near the top as `mix accumulate`. Add a new post to your `/posts` directory and you can then run `mix accumulate` to see it work. The new post should now appear in the posts listed at [http://localhost:4000](http://localhost:4000).

You may want to add the file `config/prod.secret.exs` to your gitignore. You'll need to copy `config/prod.secret.exs` somewhere, use `git rm config/prod.secret.exs` to remove it, then once you `git add .gitignore` and commit, you can copy it back in, it should prevent it from getting added back in. In order to deploy to production, you'll need to put production database details in this file, so you'll want to be sure you do not commit those to git. In more sophisticated deployments you may even want to have its creation scripted.

Open `mix.exs` and get ready to make a few changes to prepare it for deploy. First, we're going to add all of our dependencies to the `application` function.

```elixir
  def application do
    [mod: {Blargh, []},
     applications: [:phoenix, :cowboy, :phoenix_ecto, :postgrex, :earmark, :logger]]
  end
```

I've found the path to deployment a little bit bumpy. One of the problems revolves around how configuration happens. In the ruby world, we'd use a tool like [`dotenv`](https://github.com/bkeepers/dotenv) to bake configuration into the environment rather than the app, and to allow for flexibility in the development environment. I experimented with [Avdi Grimm's](http://devblog.avdi.org/) very nice [`dotenv_elixir`](https://github.com/avdi/dotenv_elixir) library. It's quite nice for local development, but there is one problem. If you plan to use [`exrm`](https://github.com/bitwalker/exrm) then the config gets baked in when you create the release.

With some scripting, it would probably be quite possible to make that work. However, I have been curious about docker for a while, and wanted to see if I could come up with a setup that would solve these problems. I'm pretty happy with what I've come up with. It will require some further changes to your app though.

First, you'll need to get and install [docker](https://www.docker.com/). Next, create a docker file in the root of your project.

```dockerfile
FROM trenpixster/elixir
MAINTAINER Eric West "esw9999@gmail.com"

ENV REFRESHED_AT 2015-03-21-10-51

RUN apt-get update
RUN apt-get -y install postgresql-client
RUN mkdir -p /opt/app/blargh/prod
RUN mkdir -p /opt/app/blargh/dev
ADD . /opt/app/blargh/prod
WORKDIR /opt/app/blargh/prod

ENV MIX_ENV prod
RUN mix deps.get
RUN mix deps.compile

ENV PORT 4000

EXPOSE 4000
CMD [ "/opt/app/blargh/prod/setup" ]
```

Obviously, you will want to change some of those details. Next, create a simple shell script, also in the root of the project:

```bash
#!/bin/bash

mix setup
mix phoenix.server
```

Make sure to make this file executable:

```bash
$ chmod +x $PWD/setup
```

Now you'll need to make some changes to your `mix.exs` file.

```elixir
defmodule Blargh.Mixfile do
  use Mix.Project

  def project do
    [app: :blargh,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: ["lib", "web"],
     compilers: [:phoenix] ++ Mix.compilers,
     aliases: aliases,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Blargh, []},
     applications: [:phoenix, :cowboy, :phoenix_ecto, :postgrex, :earmark, :logger]]
  end

  defp aliases do
    [
        setup: ["ecto.create", "ecto.migrate", "accumulate"],
    ]
  end

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 0.10.0"},
     {:phoenix_ecto, "~> 0.1"},
     {:postgrex, ">= 0.0.0"},
     {:earmark, "~> 0.1.13"},
     {:exrm, "~> 0.15.3"},
     {:cowboy, "~> 1.0"}]
  end
end
```

Specifically, we added aliases to the `project`, and created an aliases function. You can read about how aliases work in [Mix documentation](http://elixir-lang.org/docs/stable/mix/). The `setup` alias is what we're calling in our `setup` shell script, and we call that script from our `Dockerfile`. This will create and initialize the database, and add our blog posts to it.

Next, we'll make some updates to our config files:

`config/dev.exs`

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
  username: "postgres",
  password: "postgres",
  database: "blargh_dev",
  hostname: "postgres",
  port: 5432
```

`config/prod.secret.exs`

```elixir
use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :blargh, Blargh.Endpoint,
  secret_key_base: "PdC8bo/03yEGdPR2BT3xew83U7j+O6sXI01tGIsbq5G1+UaEfkher9FHamNY7TQF"

# Configure your database
config :blargh, Blargh.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "blargh_prod",
  hostname: "postgres",
  port: 5432
```

`config/test.exs`

```elixir
use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :blargh, Blargh.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :blargh, Blargh.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "blargh_test",
  hostname: "postgres",
  size: 1,
  max_overflow: false
```

We set our username and password to `postgres`, I'll leave it to you to configure this to something safe for production. Next, we set our `hostname` to `postgres` as well. We'll link our app's container to one running [postgresql](http://www.postgresql.org/) and when we do, we'll give the link the reference `postgres`. Docker will then create an entry of `postgres` in our container's `/etc/hosts` file, which will allow the our app, in it's container, to communicate, via Docker, with postgres in it's container. We'll never need to know the specific ip at all (though it is possible to get this information if needed). You can read all about how this works in [The Docker Book](http://dockerbook.com/) if you are at all inclined.

Our next step is to get that `postgres` container running.

```bash
$ docker run -d --name blog-postgres postgres
```

Now, in the root directory of the project, build your `image`. (Swap out `edubkendo` for your username on [Docker Hub](https://hub.docker.com/)).

```bash
 $ docker build -t edubkendo/blog .
```
This will take a minute or two to complete. Next we'll test out the prod version of our app by running:

```bash
$ docker run -p 4000 --name blog --link blog-postgres:postgres -d edubkendo/blog
```

We've linked together our app with the `blog-postgres` container, giving the link an alias of `postgres`, the same thing we earlier configured our `hostname` to use. With that running, you should be able to visit your blog. First, if your on OSX like I am, you are probably using [boot2docker](http://boot2docker.io/) to run docker. If so, you'll need to get an ip from boot2docker with (If you're on Linux you can skip this part and just go to `localhost`):

```bash
$ boot2docker ip
```

Next, we need to get the port docker has forwarded for our blog.

```bash
$ docker port blog
```

With host (either `localhost` or whatever `boot2docker ip` returned) and port in hand, combine the two (for me this looks like http://192.168.59.103:49182/ (yours will certainly be different)) and visit that address in the browser. You should see your blog.

"But, what about development?", you ask. I'm glad you asked. Remember how the Dockerfile made 2 directories? First, stop the prod version with:

```bash
$ docker stop blog
```

We'll create a new container for local dev, once again linking the postgres container to our own, but this time also mounting our local directory inside the container.

```bash
$ docker run -p 4000 --name blog_dev --link blog-postgres:postgres -v $PWD:/opt/app/blargh/dev -t -i edubkendo/blog /bin/bash
```

This will leave us in a bash prompt inside the container. Switch to the directory with the mounted volume and run our little setup script:

```bash
$ export MIX_ENV=dev
$ cd ../dev
$ ./setup
```

This should setup the database and start up phoenix server. Since the filesystem is mounted, you can work in your normal editor, making changes, and visit the page in your browser to see them. There's one tiny problem with this. While our host has remained the same, the port has changed, and since we're currently in an interactive session with the docker daemon, we can't query it to find out what the port is. I've typically been able to guess it though, and simply try it in the browser. Usually, it's just whatever the last port was, incremented by one or two (or sometimes three or four. While trying it out just now, the port had jumped from the last example of `49182` to `49185`).

This is annoying. We can work around it in a couple of ways. First, we could write a second setup script `./setup-dev` that changed directories for us, set the `MIX_ENV` to `dev` and then ran the other steps. I dislike this. One bash script is already one to many.

Another option, is to use `docker build`'s `-f` flag and pass it a second docker file, this one intended for development. I'm not 100% sure I like this better. For now, since the app is essentially already complete, I'm going to leave it alone. On my next app, I'll experiment with having a `.dev.docker` second docker file. However that works out, I'll come back and blog about it here.

For now, let's see about getting this thing deployed.

Create a new directory (outside your app's dir) laid out like this:

```
nginx
|
----nginx
        
```

In the root of this file, create a Dockerfile with these contents:

```dockerfile
FROM nginx
MAINTAINER Eric West "esw9999@gmail.com"

ENV REFRESHED_AT 2015-03-22-5-56

RUN rm /etc/nginx/nginx.conf

COPY nginx/nginx.conf /etc/nginx/nginx.conf
```
        
Obviously, the maintainer for yours will be different.
        
Create a file, `nginx.conf`, in the `nginx/nginx` dir.
        
`nginx/nginx/nginx.conf`
        
```
worker_processes 1;

events { worker_connections 1024; }

http {

    sendfile on;

    gzip              on;
    gzip_http_version 1.0;
    gzip_proxied      any;
    gzip_min_length   500;
    gzip_disable      "MSIE [1-6]\.";
    gzip_types        text/plain text/xml text/css
                      text/comma-separated-values
                      text/javascript
                      application/x-javascript
                      application/atom+xml;

    # List of application servers
    upstream app_servers {

        server blargh:4000;

    }

    # Configuration for the server
    server {

        # Running port
        listen 80;

        # Proxying the connections connections
        location / {

            proxy_pass         http://app_servers;
            proxy_redirect     off;
            proxy_set_header   Host $host;
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host $server_name;

        }
    }
}
```

I got the template for this file from [Docker Explained: How to Containerize and Use NGINX as a Proxy: DigitalOcean](https://www.digitalocean.com/community/tutorials/docker-explained-how-to-containerize-and-use-nginx-as-a-proxy) and I'm a bit of an nginx noob so please let me know if I've made any mistakes.

Now in the root directory, run:

```bash
$ docker build -t edubkendo/nginx .
```

Obviously use your docker hub username. Now we'll push our two images up to our docker hub account:

```bash
$ docker push edubkendo/blog
$ docker push edubkendo/nginx
```

SSH to your server, install docker, then :

```bash
$ docker run -d --name blog-postgres postgres
$ docker run -p 4000 --name blog --link blog-postgres:postgres -d edubkendo/blog
$ docker run --name nginx --link blog:blog -p 80:80 -d edubkendo/nginx
```

Now visit your site and see it live!
