defmodule Blog.Repo.Migrations.ChangePostDate do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      modify :date, :date
    end
  end
end
