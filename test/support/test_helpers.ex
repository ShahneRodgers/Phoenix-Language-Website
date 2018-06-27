defmodule Language.TestHelpers do
  alias Language.Accounts
  alias Language.Vocab
  alias Language.Repo

  require Phoenix.ConnTest
  require ExUnit.Assertions

  @user "testuser"
  @password "testpassword"

  @user2 "testuser2"
  @password2 "password2"

  @admin "admin"
  @admin_password "admin_password"

  def ensure_user() do
    user = Accounts.find_by_username(@user)

    if user do
      user
    else
      password = Comeonin.Bcrypt.hashpwsalt(@password)

      Repo.insert!(%Accounts.User{
        email: "someemail@test.com",
        username: @user,
        password: password
      })
    end
  end

  def ensure_other_user do
    Repo.insert!(%Accounts.User{email: "test@test.com", username: @user2, password: @password2})
  end

  def ensure_admin do
    user = Accounts.find_by_username(@admin)

    if user do
      user
    else
      user =
        Repo.insert!(%Accounts.User{
          email: "admin@domain.com",
          username: @admin,
          password: @admin_password
        })

      Repo.insert!(%Accounts.Admin{user_id: user.id})
      user
    end
  end

  def get_raw_test_user_password() do
    @password
  end

  def act_as_user(conn) do
    user = ensure_user()
    Accounts.Guardian.Plug.sign_in(conn, user)
  end

  def act_as_admin(conn) do
    user = ensure_admin()
    Accounts.Guardian.Plug.sign_in(conn, user)
  end

  def create_word_list(user) do
    Repo.insert!(%Vocab.WordList{title: "Test Wordlist", user_id: user.id})
  end

  def create_word_list() do
    ensure_user()
    |> create_word_list
  end

  def create_word(native, replacement, audio \\ nil, notes \\ nil) do
    user = ensure_user()
    word_list = create_word_list(user)

    Repo.insert!(%Vocab.Word{
      native: native,
      replacement: replacement,
      audio: audio,
      notes: notes,
      word_list_id: word_list.id
    })
  end

  def reauth_as_user(conn) do
    Phoenix.ConnTest.recycle(conn)
    |> act_as_user()
  end

  def reauth_as_admin(conn) do
    Phoenix.ConnTest.recycle(conn)
    |> act_as_admin()
  end
end
