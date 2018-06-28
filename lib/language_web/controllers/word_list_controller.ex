defmodule LanguageWeb.WordListController do
  use LanguageWeb, :controller

  alias Language.Vocab
  alias Language.Vocab.WordList

  require Logger

  plug(:authorise_wordlist when action in [:show, :edit, :update, :delete])

  defp authorise_wordlist(conn, _) do
    list = Vocab.get_word_list(conn.params["id"])

    user_id = get_user_id(conn)

    if is_nil(list) or list.user_id != user_id do
      if not is_nil(list) do
        Logger.warn(fn ->
          "#{user_id} attempted to access a word list owned by #{list.user_id}"
        end)
      end

      put_status(conn, 404)
      |> render(LanguageWeb.ErrorView, "404.html")
      |> halt()
    else
      conn
    end
  end

  defp get_user_id(conn) do
    Guardian.Plug.current_resource(conn).id
  end

  def index(conn, _) do
    word_lists =
      get_user_id(conn)
      |> Vocab.list_users_wordlists()

    render(conn, "index.html", word_lists: word_lists)
  end

  def new(conn, _) do
    changeset = Vocab.change_word_list(%WordList{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"word_list" => list_params}) do
    params = Enum.into(%{"user_id" => get_user_id(conn)}, list_params)

    case Vocab.create_word_list(params) do
      {:ok, word} ->
        conn
        |> put_flash(:info, "Word list created successfully.")
        |> redirect(to: word_list_path(conn, :show, word))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    word_list = Vocab.get_word_list!(id)
    render(conn, "show.html", word_list: word_list)
  end

  def edit(conn, %{"id" => id}) do
    word_list = Vocab.get_word_list!(id)
    changeset = Vocab.change_word_list(word_list)
    render(conn, "edit.html", word_list: word_list, changeset: changeset)
  end

  def update(conn, %{"id" => id, "word_list" => word_list_params}) do
    word_list = Vocab.get_word_list!(id)
    word_list_params = Enum.into(%{"user_id" => get_user_id(conn)}, word_list_params)

    case Vocab.update_word_list(word_list, word_list_params) do
      {:ok, word_list} ->
        conn
        |> put_flash(:info, "Word list updated successfully.")
        |> redirect(to: word_list_path(conn, :show, word_list))

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.info("Failed to update word list")
        render(conn, "edit.html", word_list: word_list, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    word_list = Vocab.get_word_list!(id)
    {:ok, _word_list} = Vocab.delete_word_list(word_list)

    conn
    |> put_flash(:info, "Word list deleted successfully.")
    |> redirect(to: word_list_path(conn, :index))
  end
end
