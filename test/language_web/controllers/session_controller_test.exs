defmodule LanguageWeb.SessionControllerTest do
  use LanguageWeb.ConnCase

  alias Language.TestHelpers

  alias Language.SessionHelper

  setup do
    user = TestHelpers.ensure_user()

    {:ok, [user: user]}
  end

  describe "Login" do
    test "incorrect username", %{conn: conn} do
      conn = post(conn, "/login", %{"username": "test", "password": "a"})
      assert get_flash(conn, :warning) == "Incorrect username or password"
      assert html_response(conn, 200) =~ "Login"
    end

    test "incorrect password", %{conn: conn, user: user} do
      conn = post(conn, "/login", %{"username": user.username, "password": "a"})
      assert get_flash(conn, :warning) == "Incorrect username or password"
    end

    test "succeeds", %{conn: conn, user: user} do
      password = TestHelpers.get_raw_test_user_password()
      
      conn = post(conn, "/login", %{"username": user.username, "password": password})
      assert redirected_to(conn) =~ "/browse"

      assert SessionHelper.get_valid_session(conn) != nil
    end
  end

  describe "Logout" do
    test "logged in", %{conn: conn} do
      conn = TestHelpers.act_as_user(conn)
      |> get("/logout")

      assert redirected_to(conn) =~ "/login"
      assert is_nil(SessionHelper.get_valid_session(conn))
    end

    test "not logged in", %{conn: conn} do
      conn = get(conn, "/logout")
      assert redirected_to(conn) =~ "/login"
    end
  end
end
