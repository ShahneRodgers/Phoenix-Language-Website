defmodule Language.Repo.Migrations.CreateWordlists do
  use Ecto.Migration

  def change do
    create table(:wordlists) do
      add :title, :string
      add :summary, :text
      add :user_id, references(:users, on_delete: :delete_all, null: false)

      timestamps()
    end

    create index(:wordlists, [:user_id])
  end
end
