defmodule LanguageWeb.WordController do
  use LanguageWeb, :controller

  alias Language.Vocab
  alias Language.Vocab.Word

  plug(:authorise_word when action in [:show, :edit, :update, :delete, :create])

  defp authorise_word(%Plug.Conn{params: %{"word" => word_params}} = conn, _) do
    authorise_wordlist(conn, word_params["word_list_id"])
  end

  defp authorise_word(%Plug.Conn{params: %{"id" => id}} = conn, _) do
    word = Vocab.get_word(id)
    if is_nil(word) do
      reply_bad_request(conn)
    else
      authorise_wordlist(conn, word.word_list_id)
    end
  end

  defp authorise_wordlist(conn, word_list_id) do
    list = Vocab.get_word_list(word_list_id)

    user_id = Guardian.Plug.current_resource(conn).id

    cond do
      is_nil(list) ->
        reply_bad_request(conn)

      list.user_id != user_id ->
        reply_bad_request(conn)

      true ->
        conn
    end
  end

  defp reply_bad_request(conn) do
    put_status(conn, 400)
    |> render(LanguageWeb.ErrorView, "400.html")
    |> halt()
  end

  def new(conn, %{"word_list" => word_list_id}) do
    changeset = Vocab.change_word(%Word{word_list_id: word_list_id})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"word" => word_params}) do
    case Vocab.create_word(word_params) do
      {:ok, word} ->
        conn
        |> put_flash(:info, "Word created successfully.")
        |> redirect(to: word_path(conn, :show, word))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    word = Vocab.get_word!(id)
    render(conn, "show.html", word: word)
  end

  def edit(conn, %{"id" => id}) do
    word = Vocab.get_word!(id)
    changeset = Vocab.change_word(word)
    render(conn, "edit.html", word: word, changeset: changeset)
  end

  def update(conn, %{"id" => id, "word" => word_params}) do
    word = Vocab.get_word!(id)

    case Vocab.update_word(word, word_params) do
      {:ok, word} ->
        conn
        |> put_flash(:info, "Word updated successfully.")
        |> redirect(to: word_path(conn, :show, word))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", word: word, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    word = Vocab.get_word!(id)
    {:ok, _word} = Vocab.delete_word(word)

    conn
    |> put_flash(:info, "Word deleted successfully.")
    |> redirect(to: word_path(conn, :index))
  end
end
