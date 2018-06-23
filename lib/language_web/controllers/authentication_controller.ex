defmodule LanguageWeb.AuthenticationController do
  use LanguageWeb, :controller

  alias Language.Accounts

  def login(conn, %{"username" => username, "password" => password}) do
    matching_user = Accounts.find_by_username(username)
    if matching_user do
      if Comeonin.Bcrypt.checkpw(password, matching_user.password) do
        Accounts.Guardian.Plug.sign_in(conn, matching_user)
        |> redirect(to: read_path(conn, :browse))
      else
        fail_login(conn)
      end
    else
      # Still a risk of SQL timing attacks? 
      # Unnecessary currently anyway since usernames can be determined using the signup page.
      Comeonin.Bcrypt.dummy_checkpw()
      fail_login(conn)
    end
  end

  def login(conn, _) do
    render(conn, :login)
  end

  def logout(conn, _) do
    Accounts.Guardian.Plug.sign_out(conn)
    |> redirect(to: authentication_path(conn, :login))
  end

  defp fail_login(conn) do
    put_flash(conn, :warning, "Incorrect username or password")
    |> login(nil)
  end
end