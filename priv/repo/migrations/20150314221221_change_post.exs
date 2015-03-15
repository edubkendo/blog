defmodule Blog.Repo.Migrations.ChangePost do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :file, :string
      add :basename, :string
      add :date, :datetime
      remove :author
      remove :body
    end
  end
end
