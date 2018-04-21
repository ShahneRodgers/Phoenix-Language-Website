defmodule Language.SessionHelper do

	import Plug.Conn
	alias Language.Authenticator

	@cookie_name "token"

	def get_valid_session(%Plug.Conn{cookies: %{@cookie_name => token}}) do
		session = Authenticator.find_session_by_token(token)
		if session do
			if is_valid? session do
				session
			else
				delete_session(session)
				nil
			end
		else
			nil
		end
	end

	def get_valid_session(_conn) do
		nil
	end

	def create_session(%{id: id}) do
		token = :crypto.strong_rand_bytes(30)
		|> Base.url_encode64
		Authenticator.create_session(%{user_id: id, token: token})
	end

	def add_session(conn, %{token: token}) do
		put_resp_cookie(conn, @cookie_name, token)
	end

	def delete_session(session) do
	    Authenticator.delete_session(session)
    end

    def clear_session(conn) do
    	delete_resp_cookie(conn, @cookie_name)
    end

    defp is_valid?(_session) do
    	# Consider all sessions to be valid currently - maybe add a time limit?
    	#NaiveDateTime.diff(NaiveDateTime.utc_now, session.inserted_at, :second) <= 3600 * 24
    	true
    end
end