defmodule LanguageWeb.SessionController do
  use LanguageWeb, :controller

  alias Language.SessionHelper

  alias Language.Accounts

  def login(conn, %{"username" => username, "password" => password}) do
    matching_user = Accounts.find_by_username(username)
    if matching_user do
      if Comeonin.Bcrypt.checkpw(password, matching_user.password) do
        create_session(conn, matching_user)
      else
        fail_login(conn)
      end
    else
      # Still a risk of SQL timing attacks?
      Comeonin.Bcrypt.dummy_checkpw()
      fail_login(conn)
    end
  end

  def login(conn, _) do
    render(conn, :login)
  end

  def logout(conn, _) do
    session = SessionHelper.get_valid_session(conn)
    if session do
      SessionHelper.delete_session(session)
      SessionHelper.clear_session(conn)
    else
      conn
    end
    |> redirect(to: session_path(conn, :login))
  end

  defp create_session(conn, user) do
    case SessionHelper.create_session(user) do
      {:ok, session} ->
        SessionHelper.add_session(conn, session)
        |> redirect(to: read_path(conn, :browse))
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect changeset
        # Either token already exist, the user has been deleted or the user is already logged in.
        # The first two would be unexpected, so we'll assume the last option for now.
        put_flash(conn, :error, "TODO: maybe not worth enforcing?")
        |> redirect(to: session_path(conn, :login))
    end
  end

  defp fail_login(conn) do
    put_flash(conn, :warning, "Incorrect username or password")
    |> login(nil)
  end
end