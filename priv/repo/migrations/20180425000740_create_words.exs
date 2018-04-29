defmodule Language.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words) do
      add :native, :string
      add :replacement, :string
      add :notes, :text
      add :audio, :string

      timestamps()
    end

  end
end
