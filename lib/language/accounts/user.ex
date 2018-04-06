defmodule Language.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    field :email, :string
    field :password, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:username, :email, :password])
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_length(:username, min: 5)
    |> validate_format(:email, ~r/.+@.+/)
    |> validate_length(:password, min: 8)
    |> put_pass_hash
  end

  defp put_pass_hash(%Ecto.Changeset{ valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password, Comeonin.Bcrypt.hashpwsalt(password))
  end

  defp put_pass_hash(changeset) do
    # The requested changes haven't validated, so just return.
    changeset
  end
end
