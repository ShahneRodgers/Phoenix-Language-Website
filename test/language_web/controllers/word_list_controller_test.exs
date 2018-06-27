defmodule LanguageWeb.WordListControllerTest do
  use LanguageWeb.ConnCase

  alias Language.TestHelpers

  @create_attrs %{title: "Some title", summary: nil}
  @update_attrs %{title: "Updated title", summary: "Summary"}
  @invalid_attrs %{title: nil, summary: nil}

  setup %{conn: conn} do
    conn = TestHelpers.act_as_user(conn)

    {:ok, [conn: conn]}
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

      assert response(conn, 404)
    end

    test "redirects to not found for other users' word list", %{
      conn: conn,
      non_owned_word_list: word_list
    } do
      conn = get(conn, word_list_path(conn, :show, word_list.id))
      assert response(conn, 404)
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

      assert response(conn, 404)
    end
  end

  test "delete non-existing word_list", %{conn: conn} do
    conn = delete(conn, word_list_path(conn, :delete, 1))

    assert response(conn, 404)
  end

  describe "delete wrong word list" do
    setup [:create_non_owned_word_list]

    test "delete other user's word_list fails", %{conn: conn, non_owned_word_list: word_list} do
      conn = delete(conn, word_list_path(conn, :delete, word_list))

      assert response(conn, 404)
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
end
