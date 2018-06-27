defmodule LanguageWeb.UserControllerTest do
  use LanguageWeb.ConnCase

  alias Language.Accounts
  alias Language.TestHelpers

  @create_attrs %{email: "some@email", password: "some password", username: "some username"}
  @update_attrs %{
    email: "some@updated email",
    password: "some updated password",
    username: "some updated username"
  }
  @invalid_attrs %{email: nil, password: nil, username: nil}

  setup %{conn: conn} do
    conn = TestHelpers.act_as_user(conn)
    admin_conn = TestHelpers.act_as_admin(conn)
    {:ok, [user_conn: conn, admin_conn: admin_conn]}
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  describe "index" do
    test "lists all users", %{admin_conn: conn} do
      conn = get(conn, user_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Users"
    end

    test "normal user cannot list all users", %{user_conn: conn} do
      conn = get(conn, user_path(conn, :index))
      assert html_response(conn, 404) =~ "Not Found"
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, user_path(conn, :new))
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    test "redirects when data is valid", %{conn: conn} do
      conn = post(conn, user_path(conn, :create), user: @create_attrs)

      assert redirected_to(conn) == read_path(conn, :start)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, user_path(conn, :create), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "edit user" do
    setup [:create_user]

    test "renders form for editing current user by admin", %{admin_conn: conn, user: user} do
      conn = get(conn, user_path(conn, :edit, user))
      assert html_response(conn, 200) =~ "Edit User"
    end

    test "renders form for editing current user by current user", %{user_conn: conn} do
      user = Guardian.Plug.current_resource(conn)
      conn = get(conn, user_path(conn, :edit, user))
      assert html_response(conn, 200) =~ "Edit User"
    end

    test "prevents normal user from editing other user", %{user_conn: conn, user: user} do
      conn = get(conn, user_path(conn, :edit, user))
      assert html_response(conn, 404) =~ "Not Found"
    end
  end

  describe "update user" do
    setup [:create_user]

    test "redirects when data is valid and user is admin", %{admin_conn: conn, user: user} do
      conn = put(conn, user_path(conn, :update, user), user: @update_attrs)
      assert redirected_to(conn) == user_path(conn, :show, user)

      conn =
        TestHelpers.reauth_as_admin(conn)
        |> get(user_path(conn, :show, user))

      assert html_response(conn, 200) =~ "some@updated email"
    end

    test "404s when normal user tries to update another user", %{user_conn: conn, user: user} do
      conn = put(conn, user_path(conn, :update, user), user: @update_attrs)

      assert html_response(conn, 404) =~ "Not Found"
    end

    test "redirects when data is valid and user updates self", %{user_conn: conn} do
      user = Guardian.Plug.current_resource(conn)
      conn = put(conn, user_path(conn, :update, user), user: @update_attrs)
      assert redirected_to(conn) == user_path(conn, :show, user)

      conn =
        TestHelpers.reauth_as_admin(conn)
        |> get(user_path(conn, :show, user))

      assert html_response(conn, 200) =~ "some@updated email"
    end

    test "renders errors when data is invalid", %{user_conn: conn} do
      user = Guardian.Plug.current_resource(conn)
      conn = put(conn, user_path(conn, :update, user), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit User"
    end

    test "404s when user tries to update other user", %{user_conn: conn, user: user} do
      conn = put(conn, user_path(conn, :update, user), user: @invalid_attrs)
      assert html_response(conn, 404) =~ "Not Found"
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "by admin", %{admin_conn: conn, user: user} do
      conn = delete(conn, user_path(conn, :delete, user))
      assert redirected_to(conn) == user_path(conn, :index)

      conn = TestHelpers.reauth_as_admin(conn)

      assert_error_sent(404, fn ->
        get(conn, user_path(conn, :show, user))
      end)
    end

    test "by normal user", %{user_conn: conn, user: user} do
      conn = delete(conn, user_path(conn, :delete, user))
      assert html_response(conn, 404) =~ "Not Found"
    end

    test "by self", %{user_conn: conn} do
      user = Guardian.Plug.current_resource(conn)
      conn = delete(conn, user_path(conn, :delete, user))
      assert redirected_to(conn) == user_path(conn, :index)

      conn =
        recycle(conn)
        |> get(user_path(conn, :index))

      assert redirected_to(conn) == authentication_path(conn, :login)
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
