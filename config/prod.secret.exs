use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :blog, Blog.Endpoint,
  secret_key_base: "PdC8bo/03yEGdPR2BT3xew83U7j+O6sXI01tGIsbq5G1+UaEfkher9FHamNY7TQF"

# Configure your database
config :blog, Blog.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "blog_prod",
  hostname: "postgres",
  port: 5432
 
