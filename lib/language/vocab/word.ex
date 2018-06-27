defmodule Language.Vocab.Word do
  use Ecto.Schema
  import Ecto.Changeset

  alias Language.Vocab.WordList

  schema "words" do
    field(:audio, :string)
    field(:native, :string)
    field(:notes, :string)
    field(:replacement, :string)
    belongs_to(:word_list, WordList)

    timestamps()
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:native, :replacement, :notes, :audio, :word_list_id])
    |> validate_required([:native, :replacement, :word_list_id])
  end
end
