defmodule Blog.PostView do
  use Blog.Web, :view

  def get_date(date) do
    {:ok, loaded_date} = Ecto.Date.load(date)
    Ecto.Date.to_string loaded_date
  end
end
