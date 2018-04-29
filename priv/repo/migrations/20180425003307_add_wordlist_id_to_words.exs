defmodule Language.Repo.Migrations.AddWordlistIdToWords do
  use Ecto.Migration

  def change do
  	alter table(:words) do
      add :word_list_id, references(:wordlists, on_delete: :delete_all, null: false)
  	end

  	create index(:words, [:word_list_id])
  end
end
