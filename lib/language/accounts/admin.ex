defmodule Language.Accounts.Admin do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins" do
    field(:user_id, :id)

    timestamps()
  end

  @doc false
  def changeset(admin, attrs) do
    admin
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
