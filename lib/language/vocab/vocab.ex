defmodule Language.Vocab do
  @moduledoc """
  The Vocab context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Language.Repo

  alias Language.Vocab.Word

  @doc """
  Returns the list of words.

  ## Examples

      iex> list_words()
      [%Word{}, ...]

  """
  def list_words do
    Repo.all(Word)
  end

  @doc """
  Gets a single word.

  Raises `Ecto.NoResultsError` if the Word does not exist.

  ## Examples

      iex> get_word!(123)
      %Word{}

      iex> get_word!(456)
      ** (Ecto.NoResultsError)

  """
  def get_word!(id), do: Repo.get!(Word, id)

  def get_word(id) do
    Repo.get(Word, id)
  end

  @doc """
  Creates a word.

  ## Examples

      iex> create_word(%{field: value})
      {:ok, %Word{}}

      iex> create_word(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_word(attrs \\ %{}) do
    %Word{}
    |> Word.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a word.

  ## Examples

      iex> update_word(word, %{field: new_value})
      {:ok, %Word{}}

      iex> update_word(word, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_word(%Word{} = word, attrs) do
    word
    |> Word.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Word.

  ## Examples

      iex> delete_word(word)
      {:ok, %Word{}}

      iex> delete_word(word)
      {:error, %Ecto.Changeset{}}

  """
  def delete_word(%Word{} = word) do
    Repo.delete(word)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking word changes.

  ## Examples

      iex> change_word(word)
      %Ecto.Changeset{source: %Word{}}

  """
  def change_word(%Word{} = word) do
    Word.changeset(word, %{})
  end

  alias Language.Vocab.WordList

  @doc """
  Returns a list of all the words belonging to the selected user.
  """
  def list_words_by_user(user_id) do
    query =
      from(
        word in Word,
        join: list in WordList,
        on: word.word_list_id == list.id,
        where: list.user_id == ^user_id,
        select: word
      )

    Repo.all(query)
  end

  @doc """
  Returns the list of wordlists.

  ## Examples

      iex> list_wordlists()
      [%WordList{}, ...]

  """
  def list_wordlists do
    Repo.all(WordList)
    |> Repo.preload(:words)
  end

  @doc """
  Returns the list of wordlists for the given user.
  """
  def list_users_wordlists(user_id) do
    query = from(list in WordList, where: list.user_id == ^user_id)

    Repo.all(query)
    |> Repo.preload(:words)
  end

  @doc """
  Gets a single word_list.

  Raises `Ecto.NoResultsError` if the Word list does not exist.

  ## Examples

      iex> get_word_list!(123)
      %WordList{}

      iex> get_word_list!(456)
      ** (Ecto.NoResultsError)

  """
  def get_word_list!(id) do
    Repo.get!(WordList, id)
    |> Repo.preload(:words)
  end

  def get_word_list(id) do
    list = Repo.get(WordList, id)

    if list do
      Repo.preload(list, :words)
    else
      nil
    end
  end

  @doc """
  Creates a word_list.

  ## Examples

      iex> create_word_list(%{field: value})
      {:ok, %WordList{}}

      iex> create_word_list(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_word_list(attrs \\ %{}) do
    %WordList{}
    |> WordList.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a word_list.

  ## Examples

      iex> update_word_list(word_list, %{field: new_value})
      {:ok, %WordList{}}

      iex> update_word_list(word_list, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_word_list(%WordList{} = word_list, attrs) do
    word_list
    |> WordList.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a WordList.

  ## Examples

      iex> delete_word_list(word_list)
      {:ok, %WordList{}}

      iex> delete_word_list(word_list)
      {:error, %Ecto.Changeset{}}

  """
  def delete_word_list(%WordList{} = word_list) do
    Repo.delete(word_list)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking word_list changes.

  ## Examples

      iex> change_word_list(word_list)
      %Ecto.Changeset{source: %WordList{}}

  """
  def change_word_list(%WordList{} = word_list) do
    WordList.changeset(word_list, %{})
  end

  @doc """
  Copies a word list and all related entities to another user.

  Returns {:ok, changes} or {:error, failed_operation, failed_value, changes_so_far}.

  ## Examples
    iex> copy_word_list(word_list, new_owner.id)
    {:ok, ...} 
  """
  def copy_word_list(word_list_id, user_id) do
    word_list = get_word_list(word_list_id)

    if word_list do
      copy_word_list_impl(word_list, user_id)
    else
      {:error, :word_list, %{errors: [word_list: {"does not exist"}]}, %{}}
    end
  end

  defp copy_word_list_impl(%WordList{} = word_list, user_id) do
    Map.delete(word_list, :id)
    |> Map.delete(:user)

    words = word_list.words

    word_list =
      WordList.changeset(%WordList{}, %{
        title: word_list.title,
        summary: word_list.summary,
        user_id: user_id
      })

    Multi.new()
    |> Multi.insert(:word_list, word_list)
    |> Multi.run(:word, fn val -> copy_words(val, words) end)
    |> Repo.transaction()
  end

  defp copy_words(%{word_list: word_list}, words) do
    # Copy all the words belonging to the wordlist
    words =
      Enum.map(words, fn word ->
        word = Map.delete(word, :id)

        %{word | word_list_id: word_list.id}
        |> Map.delete(:__meta__)
        |> Map.delete(:word_list)
        |> Map.from_struct()
      end)

    try do
      {count, _} = Repo.insert_all(Word, words)
      {:ok, count}
    rescue
      x -> {:error, x}
    end
  end
end
