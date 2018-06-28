defmodule LanguageWeb.WordControllerTest do
  use LanguageWeb.ConnCase

  alias Language.TestHelpers
  alias Language.Vocab

  @create_attrs %{
    audio: "some audio",
    native: "some native",
    notes: "some notes",
    replacement: "some replacement"
  }
  @update_attrs %{
    audio: "some updated audio",
    native: "some updated native",
    notes: "some updated notes",
    replacement: "some updated replacement"
  }
  @invalid_attrs %{audio: nil, native: nil, notes: nil, replacement: nil}

  setup %{conn: conn} do
    conn = TestHelpers.act_as_user(conn)
    word_list = TestHelpers.create_word_list()

    unowned_word_list =
      TestHelpers.ensure_other_user()
      |> TestHelpers.create_word_list()

    {:ok, [word_list_id: word_list.id, conn: conn, unowned_wl_id: unowned_word_list.id]}
  end

  describe "new word" do
    test "renders form", %{conn: conn} do
      conn = get(conn, word_path(conn, :new, word_list: 1))
      assert html_response(conn, 200) =~ "New Word"
    end
  end

  describe "create word" do
    test "redirects to show when data is valid", %{conn: conn} = context do
      conn = post(conn, word_path(conn, :create), word: get_attributes(@create_attrs, context))

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == word_path(conn, :show, id)

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_path(conn, :show, id))

      assert html_response(conn, 200) =~ "Show Word"
    end

    test "renders errors when data is invalid", %{conn: conn} = context do
      conn = post(conn, word_path(conn, :create), word: get_attributes(@invalid_attrs, context))
      assert html_response(conn, 200) =~ "New Word"
    end

    test "fails when attempting to add to inaccessible word list", %{
      conn: conn,
      unowned_wl_id: id
    } do
      conn =
        post(
          conn,
          word_path(conn, :create),
          word: get_attributes(@create_attrs, %{word_list_id: id})
        )

      assert html_response(conn, 400) =~ "Bad Request"
    end
  end

  describe "edit word" do
    setup [:create_word, :create_unowned_word]

    test "renders form for editing chosen word", %{conn: conn, word: word} do
      conn = get(conn, word_path(conn, :edit, word))
      assert html_response(conn, 200) =~ "Edit Word"
    end

    test "renders error when trying to access other user's word", %{
      conn: conn,
      unowned_word: word
    } do
      conn = get(conn, word_path(conn, :edit, word))
      assert html_response(conn, 400) =~ "Bad Request"
    end
  end

  describe "update word" do
    setup [:create_word, :create_unowned_word]

    test "redirects when data is valid", %{conn: conn, word: word} = context do
      conn =
        put(conn, word_path(conn, :update, word), word: get_attributes(@update_attrs, context))

      assert redirected_to(conn) == word_path(conn, :show, word)

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_path(conn, :show, word))

      assert html_response(conn, 200) =~ "some updated audio"
    end

    test "renders errors when data is invalid", %{conn: conn, word: word} = context do
      conn =
        put(conn, word_path(conn, :update, word), word: get_attributes(@invalid_attrs, context))

      assert html_response(conn, 200) =~ "Edit Word"
    end

    test "renders error when word is updated to inaccessible wordlist", %{
      conn: conn,
      word: word,
      unowned_wl_id: id
    } do
      conn =
        put(
          conn,
          word_path(conn, :update, word),
          word: get_attributes(@update_attrs, %{word_list_id: id})
        )

      assert html_response(conn, 400) =~ "Bad Request"
    end

    test "renders errors when word is always inaccessible", %{
      conn: conn,
      unowned_word: word,
      unowned_wl_id: id
    } do
      conn =
        put(
          conn,
          word_path(conn, :update, word),
          word: get_attributes(@update_attrs, %{word_list_id: id})
        )

      assert html_response(conn, 400) =~ "Bad Request"
    end
  end

  describe "delete word" do
    setup [:create_word, :create_unowned_word]

    test "deletes chosen word", %{conn: conn, word: word} do
      conn = delete(conn, word_path(conn, :delete, word))
      assert redirected_to(conn) == word_path(conn, :index)

      conn =
        TestHelpers.reauth_as_user(conn)
        |> get(word_path(conn, :show, word))

      assert html_response(conn, 400) =~ "Bad Request"
    end

    test "renders error if chosen word is not accessible", %{conn: conn, unowned_word: word} do
      conn = delete(conn, word_path(conn, :delete, word))
      assert html_response(conn, 400) =~ "Bad Request"
    end
  end

  defp create_word(context) do
    attr = get_attributes(@create_attrs, context)

    {:ok, word} = Vocab.create_word(attr)
    {:ok, word: word}
  end

  defp create_unowned_word(%{unowned_wl_id: word_list_id}) do
    attr = get_attributes(@create_attrs, %{word_list_id: word_list_id})
    {:ok, word} = Vocab.create_word(attr)
    {:ok, unowned_word: word}
  end

  defp get_attributes(attrs, %{word_list_id: id}) do
    Enum.into(%{word_list_id: id}, attrs)
  end
end
