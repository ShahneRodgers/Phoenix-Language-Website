defmodule Language.SessionHelperTest do
  use LanguageWeb.ConnCase

  import Mock

  alias Language.SessionHelper
  alias Language.Authenticator

  test "create session" do
  	with_mock Authenticator, [create_session: fn(_s) -> nil end] do
  		SessionHelper.create_session(%{id: "some id"})

  		assert called Authenticator.create_session(%{user_id: "some id"})
  	end
  end

  test "SessionHelper.add_session/2", %{conn: conn} do
  	conn = SessionHelper.add_session(conn, %{token: "test session"})
	
	assert conn.resp_cookies == %{"token" => %{value: "test session"}}
  end

  test "SessionHelper.get_valid_session/1" do
  	with_mock Authenticator, [find_session_by_token: fn(t) -> %{test: t} end] do
  		val = SessionHelper.get_valid_session(%Plug.Conn{cookies: %{"token" => "some session"}})
  		assert val == %{test: "some session"}

	  	assert called Authenticator.find_session_by_token("some session")
	end
  end

  test "get_valid_session/1 without session", %{conn: conn} do
  	assert SessionHelper.get_valid_session(conn) == nil
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
end