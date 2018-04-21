defmodule Language.AuthenticatorTest do
  use Language.DataCase

  alias Language.Authenticator

  describe "sessions" do
    alias Language.Authenticator.Session
    alias Language.Accounts

    @valid_attrs %{token: "some token"}
    @invalid_attrs %{token: nil}

    def session_fixture(attrs \\ %{}) do
      user = create_user()

      {:ok, session} =
        attrs
        |> Enum.into(%{user_id: user.id})
        |> Enum.into(@valid_attrs)
        |> Authenticator.create_session()

      session
    end

    def create_user() do
      {:ok, user} = Accounts.create_user(%{email: "email@test.com", 
                                           password: "some password", 
                                           username: "username"})
      user
    end

    test "get_session!/1 returns the session with given id" do
      session = session_fixture()
      assert Authenticator.get_session!(session.id) == session
    end

    test "find_session_by_token returns the sesion with given token" do
      session = session_fixture()
      assert Authenticator.find_session_by_token(session.token) == session
    end

    test "find_session_by_token returns nil if no matching token" do
      session_fixture()
      assert Authenticator.find_session_by_token("not a match") == nil
    end

    test "create_session/1 with valid data creates a session" do
      user = create_user()

      attrs = Enum.into(@valid_attrs, %{user_id: user.id})


      assert {:ok, %Session{} = session} = Authenticator.create_session(attrs)
      assert session.token == "some token"
    end

    test "create_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Authenticator.create_session(@invalid_attrs)
    end

    test "delete_session/1 deletes the session" do
      session = session_fixture()
      assert {:ok, %Session{}} = Authenticator.delete_session(session)
      assert_raise Ecto.NoResultsError, fn -> Authenticator.get_session!(session.id) end
    end
  end
end
