# Writing a Blog with Elixir and Phoenix, pt. 1

Get a copy of [Phoenix](http://www.phoenixframework.org/v0.10.0/docs/getting-started) on your local machine:

```
$ git clone https://github.com/phoenixframework/phoenix.git && cd phoenix && git checkout v0.10.0 && mix do deps.get, compile
```

From here, we can have Phoenix set up a new app for us:

```
$ mix phoenix.new ~/tmp/blargh blargh
```

During the install, phoenix asks a couple questions about installing some dependencies. Press "y" to say yes to both of them. We want those deps!

CD into your new blog's directory. Init it as a git repo, add everything and commit.

```
$ cd tmp/blargh/
$ git init
$ git add .
$ git commit -m "Initial commit"
```

Open the directory in your editor of choice and open a second tab for running mix commands in. In the second tab, you can start Phoenix up with `mix phoenix.server`. Navigate to [http://localhost:4000](http://localhost:4000) to see the default page Phoenix generates for you.

As long as you pressed y back when Phoenix was setting up your app and asked if you wanted to install brunch.io dependencies, your application already has support for a really awesome tool called [brunch](http://brunch.io) which means that we get [bower](http://bower.io/) support from it for free. I'm going to assume you can get bower installed onto your machine, so do that if it isn't. We'll tell bower to install a really nice css framework, [Foundation](foundation) for us.

```
$ bower init
```

Bower will ask a bunch of questions, but they mostly don't matter since we aren't making a package to publish. Next:

```
$ bower install foundation --save
```

Unfortunately, this will cause our server to throw a nasty error due to an oversite in one of Foundation's dependencies:

```
error: [Error: Component JSON file "~/tmp/blargh/bower_components/modernizr/.bower.json" must have `main` property. See https://github.com/paulmillr/read-components#README]
```

We can fix this by making sure the bower.json contains an override. Make sure your `bower.json` file (created when we ran `bower init`) looks like this:

```json
{
  "name": "blog",
  "version": "0.0.1",
  "authors": [
    "Eric West <esw9999@gmail.com>"
  ],
  "description": "Eric West's Blog",
  "license": "MIT",
  "homepage": "http://ericwest.io",
  "private": true,
  "ignore": [
    "**/.*",
    "node_modules",
    "bower_components",
    "test",
    "tests"
  ],
  "dependencies": {
    "foundation": "~5.5.1"
  },
  "overrides": {
      "modernizr": {
          "main": "modernizr.js"
      }
  }
}
```

One VERY unfortunate problem is that `modernizr` still seems to cause a bug on the page: `TypeError: modernizr cannot read property 'document' of undefined`. The only solution I've found so far is to go in and edit it by hand. Open `bower_components/modernizr/modernizr.js`, scroll to the very bottom, and where it passes in `(this, this.document)` to the closure, edit that to `(window, window.document)`. If you know a better solution, please leave a comment below.

In the root directory of your project, create a new directory `posts/`. 

```
$ mkdir posts
```

Check `config/dev.exs` for any needed changes to work with your local instance of postgres. For example, I had to alter the port from the default by adding to the configuration block at the bottom so that it looked like:

```elixir
config :blargh, Blargh.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "blargh_dev",
  port: 15432
```

Next we'll create our db by running:

```
$ mix ecto.create
```

We'll generate a resource with:

```
mix phoenix.gen.resource Post posts title:string file:string basename:string date:date
```

This should create a bunch of files for us, with output that looks like:

```
Compiled lib/blargh.ex
Compiled web/web.ex
Compiled lib/blargh/repo.ex
Compiled web/router.ex
Compiled web/views/error_view.ex
Compiled web/views/page_view.ex
Compiled web/controllers/page_controller.ex
Compiled web/views/layout_view.ex
Compiled lib/blargh/endpoint.ex
Generated blargh.app
* creating priv/repo/migrations/20150315120015_create_post.exs
* creating web/controllers/post_controller.ex
* creating web/models/post.ex
* creating web/templates/post/edit.html.eex
* creating web/templates/post/form.html.eex
* creating web/templates/post/index.html.eex
* creating web/templates/post/new.html.eex
* creating web/templates/post/show.html.eex
* creating web/views/post_view.ex

Add the resource to the proper scope in web/router.ex:

resources "/posts", PostController

and then update your repository by running migrations:

    $ mix ecto.migrate
```

Let's do what it says. Open up `web/router.ex` in your editor and make it look like this:

```elixir
defmodule Blargh.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Blargh do
    pipe_through :browser # Use the default browser stack

    # We'll remove the line that was here and replace it with this one.
    resources "/", PostController, only: [:index, :show]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Blargh do
  #   pipe_through :api
  # end
end
```

The line we removed, which mapped the `PageController` to `/` is replaced with a new line mapping `/` to our PostController. Because our blog posts are read-only resources (we make new ones by writing them in the `posts/` dir, not posting them to some web form) we limit this to only the `index` and `show` actions.

Now we should be able to run our migrations:

```
mix ecto.migrate
```

Remove unwanted templates from the `web/templates/post` dir like so:

```
$ rm web/templates/post/new.html.eex
$ rm web/templates/post/edit.html.eex
$ rm web/templates/post/form.html.eex
```

Then, go into `web/controllers/post_controller.ex` and remove all the functions except for `index` and `show` so that it looks just like this:

```elixir
defmodule Blargh.PostController do
  use Blargh.Web, :controller

  alias Blargh.Post

  plug :scrub_params, "post" when action in [:create, :update]
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
```

Add a file to `/posts` called `2015-03-08-new-blog.md` and write a couple lines of markdown in it. This will be useful in just a bit, for testing that we can render a post. Your title can be different if you want, just folow the basic pattern of `YYYY-MM-DD-blog-post-title.md` and it should work fine.

We'll need to change up our remaining templates in order for them to show anything, since we've already monkeyed so much with the controller and router. For starters, change the file in `web/templates/layout/application.html.eex` to this:

```erb
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <title><%= "#{title}" %></title>
    <link rel="stylesheet" href="<%= static_path(@conn, "/css/app.css") %>">
    <link href='http://fonts.googleapis.com/css?family=Rock+Salt' rel='stylesheet' type='text/css'>
  </head>

  <body>
   <%= render "nav.html" %> 
    <div class="row">
      <div class="large-10 column">

        <%= @inner %>

      </div>

      <div class="footer">
      </div>

    </div> <!-- /container -->
    <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
    <script>require("web/static/js/app")</script>
  </body>
</html>
```

Create a new file, also in `layout`, and name it `post.html.eex` with the following contents. We'll be able to have a title based on the title of our blog posts this way. Include the following in it:

```erb
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <title><%= "#{title}: #{@post.title}" %></title>
    <link rel="stylesheet" href="<%= static_path(@conn, "/css/app.css") %>">
    <link href='http://fonts.googleapis.com/css?family=Rock+Salt' rel='stylesheet' type='text/css'>
  </head>

  <body>
    <%= render "nav.html" %>
    
    <div class="row">

      <div class="large-10 column">
        <%= @inner %>
      </div>

      <div class="footer">
      </div>

    </div> <!-- /container -->
    <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
    <script>require("web/static/js/app")</script>
  </body>
</html>
```

You may have noticed we added the following line to each of those layouts: `<%= render "nav.html" %>`. This refers to a partial we haven't written yet. Create it now, also in the layouts folder, `web/templates/layout/nav.html.eex`.

```erb
<nav class="top-bar" data-topbar role="navigation">
  <ul class="title-area">
    <li class="name">
      <h1><a href="/">Blog Name</a></h1>
    </li>
    <!-- Remove the class "menu-icon" to get rid of menu icon. Take out "Menu" to just have icon alone -->
    <li class="toggle-topbar menu-icon"><a href="#"><span>Menu</span></a></li>
  </ul>

  <section class="top-bar-section">
    <!-- Right Nav Section -->
    <ul class="right">
      <li class=""><a href="/">Blog</a></li>
      <li class=""><a href="http://www.github.com/edubkendo">Code</a></li>
    </ul>
  </section>
</nav>
```

Finally, change `web/templates/post/index.html.eex` to resemble:

```erb
<ul class="no-bullet">
  <%= for post <- Enum.reverse(@posts) do %>
      <li>
        <div class="article-entry">
          <h4 class="subheader"><small><%= get_date(post.date) %></small></h4>
          <h4><%= link post.title, to: post_path(@conn, :show, post) %></h4>
        </div>
      </li>
  <% end %>
</ul>
```

And `web/templates/post/show.html.eex` to:

```erb
<div class="content">
  <div class="row">
    <div class="large-3 column">
      <h3 class="subheader date-box"><%= get_date(@post.date) %></h3>
    </div>
    <div class="large-9 column blog-post">
      <%= safe @output %>
    </div>
  </div>
</div>

<div class="link-back">
  <%= link "Back", to: post_path(@conn, :index) %>
</div>
```

Now we just need to make a few additions to our controller and views and we'll be in shape.

Go ahead and open up `web/controllers/post_controller.ex` and make it look like:

```elixir
defmodule Blargh.PostController do
  use Blargh.Web, :controller

  alias Blargh.Post

  plug :action

  def index(conn, _params) do
    posts = Repo.all(Post)
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

Open the file `web/views/layout_view.ex` and add a `title` function to it, like so:

```elixir
defmodule Blargh.LayoutView do
  use Blargh.Web, :view

  def title do
    "Eric West"
  end
end
```

This allows us to re-use that for title generation in our templates.

Next, open up `web/views/post_view.ex` and add a `date` function, for easily getting the date from a given post:

```elixir
defmodule Blargh.PostView do
  use Blargh.Web, :view

  def get_date(date) do
    Ecto.Date.to_string date
  end
end
```

In `lib/blargh` create a new file, `post_builder.ex` and save it with the following code in it:

```elixir
defmodule Blargh.PostBuilder do
  import Ecto.Query, only: [from: 2]

  def add_to_db do
    find_posts
    |> post_data
    |> Enum.reject(&(already_exists?(&1)))
    |> Enum.map(&(create_new(&1)))
  end

  def create_new(post) do
    Blargh.Post.changeset(%Blargh.Post{}, post)
    |> Blargh.Repo.insert
  end

  def already_exists?(post) do
    query = from p in Blargh.Post,
      where: p.basename == ^post.basename
    any = Blargh.Repo.all(query)
    not Enum.empty?(any)
  end

  def basename(post) do
    Path.basename(post)
  end

  def title(post) do
    String.slice(post, 11, 1000)
    |> String.replace(".md", "")
    |> String.split("-")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  def date(post) do
    {:ok, date} = String.slice(post, 0..9)
    |> String.split("-")
    |> Enum.map(&(String.to_integer(&1)))
    |> List.to_tuple
    |> Ecto.Date.load
    date
  end

  def post_data(posts) do
    for p <- posts do
      %{
              file: p,
              title: title(basename(p)),
              basename: basename(p),
              date: date(basename(p))
          }
    end
  end

  def find_posts do
    File.ls!("./posts")
  end
end
```

The code we just added will eventually read any `.md` or markdown files in the `posts/` directory, and add information about them to our database so we can easily list them on our blog's main page.

Those same markdown files will be rendered as `html` and served up as the posts in our blog.

Open up `mix.exs` and find the `deps` function. Add this line to the list of dependencies: `{:earmark, "~> 0.1.13"},` so that the file looks like this:

```elixir
defmodule Blargh.Mixfile do
  use Mix.Project

  def project do
    [app: :blargh,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: ["lib", "web"],
     compilers: [:phoenix] ++ Mix.compilers,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Blargh, []},
     applications: [:phoenix, :cowboy, :logger]]
  end

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 0.10.0"},
     {:phoenix_ecto, "~> 0.1"},
     {:postgrex, ">= 0.0.0"},
     {:earmark, "~> 0.1.13"},
     {:cowboy, "~> 1.0"}]
  end
end
```

Run `mix deps.get` to pull in [earmark](https://hex.pm/packages/earmark), a powerful Markdown parser.

At this point, if you run `mix phoenix.server` and visit (http://localhost:4000)[http://localhost:4000] you should see something working. It won't quite look right though, so let's clean up our css. Open `web/static/css/app.scss` and remove everything. Then add the following:

```scss
$brown_grey: #585b56;
$magenta: #fd446b;
$cream: #ffefc2;
$beige: #fffce5;
$sand: #c9c6bb;

.top-bar {
  background: $brown_grey;
}

.top-bar .name h1 a {
  color: $cream;
  font-family: 'Rock Salt', cursive;
}

.top-bar-section li:not(.has-form) a:not(.button) {
  background: $brown_grey;
  color: $sand;
}

.top-bar-section li:not(.has-form) a:not(.button):hover {
  background: $magenta;
  color: $sand;
}

.article-entry a {
  color: $brown_grey;
}

.article-entry a:hover {
  color: $magenta;
}

.link-back a {
  color: $brown_grey;
}

.link-back a:hover {
  color: $magenta;
}

.date-box {
  text-align: center;
  color: $sand;
}

.blog-post p {
  font-family: 'Open Sans', sans-serif;
  font-size: 20px;
  font-weight: 300;
}
```

Tweak the above to your liking. If you want to add comments, the easiest way is to set up an account with (disqus)[https://disqus.com/]. Click the settings link in the upper-right corner, select, "Add disqus to site" and provide the information (If you do not already have a disqus account you may need to do that first). Take special note of whatever you choose for your unique disqus url.

Add the disqus code near the bottom of `web/templates/post/show.html.eex` so that you wind up with the following:

```erb
<div class="content">
  <div class="row">
    <div class="large-3 column">
      <h3 class="subheader date-box"><%= get_date(@post.date) %></h3>
    </div>
    <div class="large-9 column blog-post">
      <%= safe @output %>
    </div>
  </div>
</div>
<div id="disqus_thread"></div>
<script type="text/javascript">
  /* * * CONFIGURATION VARIABLES * * */
  // Required: on line below, replace text in quotes with your forum shortname
  var disqus_shortname = 'YOUR UNIQUE SHORTNAME GOES HERE';

  /* * * DON'T EDIT BELOW THIS LINE * * */
  (function() {
  var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
  dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
  (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
  })();
</script>
<noscript>Please enable JavaScript to view the <a href="https://disqus.com/?ref_noscript" rel="nofollow">comments powered by Disqus.</a></noscript>
<div class="link-back">
  <%= link "Back", to: post_path(@conn, :index) %>
</div>
```

Finally, if you plan to blog about code, and especially about elixir, you'll want to bring in [highlight.js](https://highlightjs.org/) so go to their site, choose "Get version ..." (the version will change with time, of course) and then scroll down. They allow you to customize the languages you pull in, so select any you want, be sure to include elixir, and then click the download button. This will pull down a zip file. After extracting that file, you'll need two files from the directory it creates. First, copy or move `highlight.pack.js` into `web/static/vendor` to sit alongside `phoenix.js`. Brunch will pull this in for us, adding it to the final javascript output on the page. Next, inside the `highlight/styles` folder, select one of the various styles of syntax highlighting. You can probably tell I went with `solarized_dark.css`. Move or copy that into `web/static/css`.

```
$ cp highlight.pack.js ~/tmp/blargh/web/static/vendor/
$ cp styles/solarized_dark.css ~/tmp/blargh/web/static/css/
```

Now, open up `web/static/js/app.js` and add a line to the end so it looks like:

```javascript
import {Socket} from "phoenix"

// let socket = new Socket("/ws")
// socket.join("topic:subtopic", {}, chan => {
// })

let App = {
}

export default App

hljs.initHighlightingOnLoad();
```

And you are now all set! Enjoy your blog! In the next episode, I'll discuss how to get your site set up on a server, but if you're impatient, you can always read more at [Phoenix Framework](http://www.phoenixframework.org/) where they have guides specifically on deployment.
