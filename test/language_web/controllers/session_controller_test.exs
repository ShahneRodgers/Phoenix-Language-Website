defmodule LanguageWeb.SessionControllerTest do
  use LanguageWeb.ConnCase

  import Mock

  alias Language.Accounts
  alias Language.Accounts.User

  alias Language.SessionHelper

  describe "Login" do
    test "incorrect username", %{conn: conn} do
      with_mock Accounts, [find_by_username: fn("test") -> nil end] do
        conn = post(conn, "/login", %{"username": "test", "password": "a"})
        assert get_flash(conn, :warning) == "Incorrect username or password"
        assert html_response(conn, 200) =~ "Login"
      end
    end

    test "incorrect password", %{conn: conn} do
      with_mock Accounts, [find_by_username: fn("name") ->  
          %User{username: "name", password: "incorrect", email: "test"} end] do
        conn = post(conn, "/login", %{"username": "name", "password": "a"})
        assert get_flash(conn, :warning) == "Incorrect username or password"
      end
    end

    test "succeeds", %{conn: conn} do
      username = "name"
      pw = Comeonin.Bcrypt.hashpwsalt("pw")
      user = %User{id: 1, username: username, password: pw, email: "test"}
      session = "some session"

      with_mocks [{Accounts, [], [find_by_username: fn(^username) -> user end]},
         {SessionHelper, [], [create_session: fn(^user) -> {:ok, session} end,
                              add_session: fn(c, ^session) -> c end]}] do

        conn = post(conn, "/login", %{"username": username, "password": "pw"})
        assert redirected_to(conn) =~ "/browse"

        assert called Accounts.find_by_username(username)
        assert called SessionHelper.create_session(user)
        assert called SessionHelper.add_session(:_, session)
      end
    end
  end

  describe "Logout" do

    test "logged in", %{conn: conn} do
      session = "session test"

      with_mocks [{SessionHelper, [], [get_valid_session: fn(_c) -> session end,
                                   delete_session: fn(_s) -> nil end,
                                   clear_session: fn(c) -> c end ]}] do
        conn = get(conn, "/logout")
        assert redirected_to(conn) =~ "/login"

        assert called SessionHelper.get_valid_session(:_)
        assert called SessionHelper.delete_session(session)
        assert called SessionHelper.clear_session(:_)
      end
    end

    test "not logged in", %{conn: conn} do
      with_mock SessionHelper, [get_valid_session: fn(_c) -> nil end] do
        conn = get(conn, "/logout")
        assert redirected_to(conn) =~ "/login"

        assert called SessionHelper.get_valid_session(:_)
      end
    end
  end
end
