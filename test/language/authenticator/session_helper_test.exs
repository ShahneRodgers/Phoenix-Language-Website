defmodule Language.SessionHelperTest do
  use LanguageWeb.ConnCase

  alias Language.SessionHelper
  alias Language.TestHelpers
  alias Language.Authenticator

  setup do
    user = TestHelpers.ensure_user()

    {:ok, [user_id: user.id]}
  end

  test "create session", %{user_id: id} do
  	{:ok, session} = SessionHelper.create_session(%{id: id})

    assert not is_nil(session)
  	assert Authenticator.get_session!(session.id) == session
  end

  test "SessionHelper.add_session/2", %{conn: conn} do
  	conn = SessionHelper.add_session(conn, %{token: "test session"})

    assert conn.resp_cookies == %{"token" => %{value: "test session"}}
  end

  test "SessionHelper.get_valid_session/1" , %{user_id: id} do
    {:ok, session} = create_session(id, "some token")

    val = SessionHelper.get_valid_session(%Plug.Conn{cookies: %{"token" => "some token"}})

  	assert val == session
  end

  test "get_valid_session/1 without session", %{conn: conn} do
  	assert SessionHelper.get_valid_session(conn) == nil
  end

  test "get_valid_session/1 with invalid session" do
    val = SessionHelper.get_valid_session(%Plug.Conn{cookies: %{"token" => "some token"}})

    assert is_nil(val)
  end

  describe "SessionHelper.clear_session/1" do
  	test "round trip", %{conn: conn} do
      session = conn
	  	|> SessionHelper.add_session(%{token: "a session"})
	  	|> SessionHelper.clear_session
	  	|> SessionHelper.get_valid_session

	  	assert session == nil
	  end

    test "doesn't blow up without session", %{conn: conn} do
      SessionHelper.clear_session(conn)
    end
  end

  defp create_session(user_id, token) do
    Authenticator.create_session(%{user_id: user_id, token: token})
  end
end