defmodule Blog.PostBuilder do
  import Ecto.Query, only: [from: 2]

  def add_to_db do
    find_posts
    |> post_data
    |> Enum.reject(&(already_exists?(&1)))
    |> Enum.map(&(create_new(&1)))
  end

  def create_new(post) do
    Blog.Post.changeset(%Blog.Post{}, post)
    |> Blog.Repo.insert
  end

  def already_exists?(post) do
    query = from p in Blog.Post,
      where: p.basename == ^post.basename
    any = Blog.Repo.all(query)
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
    String.slice(post, 0..9)
    |> String.split("-")
    |> Enum.map(&(String.to_integer(&1)))
    |> List.to_tuple
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
