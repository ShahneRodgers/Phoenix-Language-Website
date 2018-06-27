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
    {:ok, [word_list_id: word_list.id, conn: conn]}
  end

  def fixture(:word, context) do
    attr = get_attributes(@create_attrs, context)

    {:ok, word} = Vocab.create_word(attr)
    word
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
  end

  describe "edit word" do
    setup [:create_word]

    test "renders form for editing chosen word", %{conn: conn, word: word} do
      conn = get(conn, word_path(conn, :edit, word))
      assert html_response(conn, 200) =~ "Edit Word"
    end
  end

  describe "update word" do
    setup [:create_word]

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
  end

  describe "delete word" do
    setup [:create_word]

    test "deletes chosen word", %{conn: conn, word: word} do
      conn = delete(conn, word_path(conn, :delete, word))
      assert redirected_to(conn) == word_path(conn, :index)

      conn = TestHelpers.reauth_as_user(conn)

      assert_error_sent(404, fn ->
        get(conn, word_path(conn, :show, word))
      end)
    end
  end

  defp create_word(context) do
    word = fixture(:word, context)
    {:ok, word: word}
  end

  defp get_attributes(attrs, %{word_list_id: id}) do
    Enum.into(%{word_list_id: id}, attrs)
  end
end
