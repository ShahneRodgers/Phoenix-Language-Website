defmodule Language.VocabTest do
  use Language.DataCase

  alias Language.Vocab
  alias Language.TestHelpers

  describe "words" do
    alias Language.Vocab.Word

    @valid_attrs %{audio: "http://www.audiofiles.com/f.mp3", native: "some native", notes: "some notes", replacement: "some replacement"}
    @update_attrs %{audio: "ftp://audio_file.mp3", native: "some updated native", notes: "some updated notes", replacement: "some updated replacement"}
    @invalid_attrs %{audio: nil, native: nil, notes: nil, replacement: nil}

    def word_fixture(attrs \\ %{}) do
      {:ok, word} =
        attrs
        |> get_word_attr()
        |> Enum.into(@valid_attrs)
        |> Vocab.create_word()

      word
    end

    test "list_words/0 returns all words" do
      word = word_fixture()
      assert Vocab.list_words() == [word]
    end

    test "get_word!/1 returns the word with given id" do
      word = word_fixture()
      assert Vocab.get_word!(word.id) == word
    end

    test "create_word/1 with valid data creates a word" do
      assert {:ok, %Word{} = word} = Vocab.create_word(get_word_attr(@valid_attrs))
      assert word.audio == @valid_attrs.audio
      assert word.native == @valid_attrs.native
      assert word.notes == @valid_attrs.notes
      assert word.replacement == @valid_attrs.replacement
    end

    test "create_word/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Vocab.create_word(get_word_attr(@invalid_attrs))
    end

    test "update_word/2 with valid data updates the word" do
      word = word_fixture()
      assert {:ok, word} = Vocab.update_word(word, get_word_attr(@update_attrs))
      assert %Word{} = word
      assert word.audio == @update_attrs.audio
      assert word.native == @update_attrs.native
      assert word.notes == @update_attrs.notes
      assert word.replacement == @update_attrs.replacement
    end

    test "update_word/2 with invalid data returns error changeset" do
      word = word_fixture()
      assert {:error, %Ecto.Changeset{}} = Vocab.update_word(word, get_word_attr(@invalid_attrs))
      assert word == Vocab.get_word!(word.id)
    end

    test "delete_word/1 deletes the word" do
      word = word_fixture()
      assert {:ok, %Word{}} = Vocab.delete_word(word)
      assert_raise Ecto.NoResultsError, fn -> Vocab.get_word!(word.id) end
    end

    test "change_word/1 returns a word changeset" do
      word = word_fixture()
      assert %Ecto.Changeset{} = Vocab.change_word(word)
    end
  end

  describe "wordlists" do
    alias Language.Vocab.WordList

    @valid_attrs %{summary: "some summary", title: "some title"}
    @update_attrs %{summary: "some updated summary", title: "some updated title"}
    @invalid_attrs %{summary: nil, title: nil}

    def word_list_fixture(attrs \\ %{}) do
      {:ok, word_list} =
        attrs
        |> get_word_list_attr()
        |> Enum.into(@valid_attrs)
        |> Vocab.create_word_list()

      %{word_list | words: [] }
    end

    test "list_wordlists/0 returns all wordlists" do
      word_list = word_list_fixture()
      assert Vocab.list_wordlists() == [word_list]
    end

    test "get_word_list!/1 returns the word_list with given id" do
      word_list = word_list_fixture()
      assert Vocab.get_word_list!(word_list.id) == word_list
    end

    test "create_word_list/1 with valid data creates a word_list" do
      assert {:ok, %WordList{} = word_list} = Vocab.create_word_list(get_word_list_attr(@valid_attrs))
      assert word_list.summary == @valid_attrs.summary
      assert word_list.title == @valid_attrs.title
    end

    test "create_word_list/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Vocab.create_word_list(get_word_list_attr(@invalid_attrs))
    end

    test "update_word_list/2 with valid data updates the word_list" do
      word_list = word_list_fixture()
      assert {:ok, word_list} = Vocab.update_word_list(word_list, get_word_list_attr(@update_attrs))
      assert %WordList{} = word_list
      assert word_list.summary == @update_attrs.summary
      assert word_list.title == @update_attrs.title
    end

    test "update_word_list/2 with invalid data returns error changeset" do
      word_list = word_list_fixture()
      assert {:error, %Ecto.Changeset{}} = Vocab.update_word_list(word_list, get_word_list_attr(@invalid_attrs))
      assert word_list == Vocab.get_word_list!(word_list.id)
    end

    test "delete_word_list/1 deletes the word_list" do
      word_list = word_list_fixture()
      assert {:ok, %WordList{}} = Vocab.delete_word_list(word_list)
      assert_raise Ecto.NoResultsError, fn -> Vocab.get_word_list!(word_list.id) end
    end

    test "change_word_list/1 returns a word_list changeset" do
      word_list = word_list_fixture()
      assert %Ecto.Changeset{} = Vocab.change_word_list(word_list)
    end
  end

  defp get_word_list_attr(attr) do
    user = TestHelpers.ensure_user()

    Enum.into(%{user_id: user.id}, attr)
  end

  defp get_word_attr(attr) do
    word_list = TestHelpers.create_word_list()

    Enum.into(%{word_list_id: word_list.id}, attr)
  end
end
