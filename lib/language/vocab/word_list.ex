defmodule Language.Vocab.WordList do
  use Ecto.Schema
  import Ecto.Changeset

  alias Language.Vocab.Word

  schema "wordlists" do
    field(:title, :string)
    field(:summary, :string)
    has_many(:words, Word)
    belongs_to(:user, Language.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(word_list, attrs) do
    word_list
    |> cast(attrs, [:title, :summary, :user_id])
    |> validate_required([:title, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
