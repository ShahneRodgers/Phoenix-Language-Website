defmodule LanguageWeb.ReadControllerTest do
  use LanguageWeb.ConnCase

  alias Language.TestHelpers

  setup %{conn: conn} do
    conn = TestHelpers.act_as_user(conn)
    {:ok, [auth_conn: conn]}
  end

  test "GET /browse", %{auth_conn: conn} do
    # If no site is given, we should be redirected to start
    conn = get(conn, "/browse")
    assert redirected_to(conn) =~ "/start"
  end

  test "GET /browse?site=invalid", %{auth_conn: conn} do
    # Give an invalid site
    conn = get(conn, "/browse", site: "invalid")
    assert redirected_to(conn) =~ "/start"
    assert get_flash(conn, :error) =~ "The site could not be reached"
  end
end
