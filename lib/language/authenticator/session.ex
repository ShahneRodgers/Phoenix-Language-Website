defmodule Language.Authenticator.Session do
  use Ecto.Schema
  import Ecto.Changeset


  schema "sessions" do
    field :token, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:token, :user_id])
    |> validate_required([:token, :user_id])
    |> unique_constraint(:token)
    |> unique_constraint(:user_id) # The user can only be signed in on one device at a time.
    |> foreign_key_constraint(:user_id)
  end
end
