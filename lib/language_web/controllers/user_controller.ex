defmodule LanguageWeb.UserController do
  use LanguageWeb, :controller

  alias Language.Accounts
  alias Language.Accounts.User

  require Logger

  plug(:authorise_user when action not in [:new, :create])

  defp authorise_user(%Plug.Conn{params: %{"id" => id}} = conn, _) do
    authorise_user_impl(conn, id)
  end

  defp authorise_user(conn, _) do
    authorise_user_impl(conn)
  end

  defp authorise_user_impl(conn, req_id \\ nil) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      is_nil(user) -> fail_authentication(conn)
      not is_nil(req_id) and Integer.to_string(user.id) == req_id -> conn
      Accounts.is_admin?(user.id) -> conn
      true -> fail_authentication(conn)
    end
  end

  defp fail_authentication(conn) do
    put_status(conn, 404)
    |> render(LanguageWeb.ErrorView, "404.html")
    |> halt()
  end

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> Accounts.Guardian.Plug.sign_in(user)
        |> redirect(to: read_path(conn, :start))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end
end
