defmodule LanguageWeb.WordListControllerTest do
  use LanguageWeb.ConnCase

  alias Language.TestHelpers

  @create_attrs %{title: "Some title", summary: nil}
  @update_attrs %{title: "Updated title", summary: "Summary"}
  @invalid_attrs %{title: nil, summary: nil}

  setup %{conn: conn} do
    auth_conn = TestHelpers.act_as_user(conn)

    {:ok, [conn: auth_conn, anonymous_conn: conn]}
  end

  describe "list word list" do
    setup [:create_word_list]

    test "shows users word lists", %{conn: conn, word_list: word_list} do
      conn = get(conn, word_list_path(conn, :index))
      body = html_response(conn, 200)
      assert String.contains?(body, word_list.title)
    end
  end

  describe "list no word list" do
    setup [:create_non_owned_word_list]

    test "does not show other users word lists", %{conn: conn, non_owned_word_list: list} do
      conn = get(conn, word_list_path(conn, :index))
      body = html_response(conn, 200)
      assert not String.contains?(body, list.title)
    end
  end

  describe "new word list" do
    test "renders form", %{conn: conn} do
      conn = get(conn, word_list_path(conn, :new))
      assert html_response(conn, 200) =~ "New Word List"
    end
  end

  describe "show word list" do
    setup [:create_word_list, :create_non_owned_word_list]

    test "shows user-owned word list", %{conn: conn, word_list: word_list} do
      conn = get(conn, word_list_path(conn, :show, word_list.id))
      assert html_response(conn, 200) =~ word_list.title
    end

    test "redirects to not found for non-existing word list", %{conn: conn} do
      conn = get(conn, word_list_path(conn, :show, 1_997_893))

      assert response(conn, 400)
    end

    test "redirects to not found for other users' word list", %{
      conn: conn,
      non_owned_word_list: word_list
    } do
      conn = get(conn, word_list_path(conn, :show, word_list.id))
      assert response(conn, 400)
    end
  end

  describe "create word list" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, word_list_path(conn, :create), word_list: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == word_list_path(conn, :show, id)

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_list_path(conn, :show, id))

      assert html_response(conn, 200) =~ @create_attrs.title
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, word_list_path(conn, :create), word_list: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Word List"
    end
  end

  describe "edit word list" do
    setup [:create_word_list]

    test "renders form for editing chosen list", %{conn: conn, word_list: word_list} do
      conn = get(conn, word_list_path(conn, :edit, word_list))
      assert html_response(conn, 200) =~ "Edit Word List"
    end
  end

  describe "update word list" do
    setup [:create_word_list]

    test "redirects when data is valid", %{conn: conn, word_list: word_list} do
      conn = put(conn, word_list_path(conn, :update, word_list), word_list: @update_attrs)
      assert redirected_to(conn) == word_list_path(conn, :show, word_list)

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_list_path(conn, :show, word_list))

      assert html_response(conn, 200) =~ @update_attrs.summary
    end

    test "renders errors when data is invalid", %{conn: conn, word_list: word_list} do
      conn = put(conn, word_list_path(conn, :update, word_list), word_list: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Word"
    end
  end

  describe "delete word list" do
    setup [:create_word_list]

    test "delete user owned word_list", %{conn: conn, word_list: word_list} do
      conn = delete(conn, word_list_path(conn, :delete, word_list))
      assert redirected_to(conn) == word_list_path(conn, :index)

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_list_path(conn, :show, word_list))

      assert response(conn, 400)
    end
  end

  test "delete non-existing word_list", %{conn: conn} do
    conn = delete(conn, word_list_path(conn, :delete, 1))

    assert response(conn, 400)
  end

  describe "delete wrong word list" do
    setup [:create_non_owned_word_list]

    test "delete other user's word_list fails", %{conn: conn, non_owned_word_list: word_list} do
      conn = delete(conn, word_list_path(conn, :delete, word_list))

      assert response(conn, 400)
    end
  end

  describe "shows public word lists" do
    setup [:create_public_list]

    test "allows unauthenticated users access", %{anonymous_conn: conn, public_list: word_list} do
      conn = get(conn, word_list_path(conn, :public))

      response = html_response(conn, 200)
      # Check the response contains the word list
      assert response =~ word_list.title

      # But doesn't contain a button for adding the word list to the user's word (since there is no user)
      refute response =~ "Add to my lists"
    end

    test "allows authenticated users access", %{conn: conn, public_list: word_list} do
      conn = get(conn, word_list_path(conn, :public))

      response = html_response(conn, 200)
      assert response =~ word_list.title
      assert response =~ "Add to my lists"
    end
  end

  describe "sharing of public word lists" do
    setup [:create_word_list, :create_non_owned_word_list]

    test "allows users to share their own word lists", %{conn: conn, word_list: word_list} do
      conn = get(conn, word_list_path(conn, :public))

      refute html_response(conn, 200) =~ word_list.title

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_list_path(conn, :share, word_list.id))

      assert redirected_to(conn) == word_list_path(conn, :public)

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_list_path(conn, :public))

      assert html_response(conn, 200) =~ word_list.title
    end

    test "prevents sharing of other user's word lists", %{
      conn: conn,
      non_owned_word_list: word_list
    } do
      conn = get(conn, word_list_path(conn, :share, word_list.id))

      assert html_response(conn, 400) =~ "Bad Request"
    end
  end

  describe "claiming of public word lists" do
    setup [:create_public_list]

    test "allows users to claim lists", %{conn: conn, public_list: word_list} do
      conn = get(conn, word_list_path(conn, :index))

      refute html_response(conn, 200) =~ word_list.title

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_list_path(conn, :claim, word_list.id))

      assert redirected_to(conn) == word_list_path(conn, :index)

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_list_path(conn, :index))

      assert html_response(conn, 200) =~ word_list.title
    end

    test "redirects unauthenticated users to login", %{
      anonymous_conn: conn,
      public_list: word_list
    } do
      conn = get(conn, word_list_path(conn, :claim, word_list.id))

      assert redirected_to(conn) == authentication_path(conn, :login)
    end
  end

  defp create_non_owned_word_list(_) do
    word_list =
      TestHelpers.ensure_other_user()
      |> TestHelpers.create_word_list()

    {:ok, [non_owned_word_list: word_list]}
  end

  defp create_word_list(_) do
    word_list = TestHelpers.create_word_list()

    {:ok, [word_list: word_list]}
  end

  defp create_public_list(_) do
    word_list = TestHelpers.create_public_list()

    {:ok, [public_list: word_list]}
  end
end
