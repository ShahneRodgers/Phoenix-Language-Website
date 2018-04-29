defmodule LanguageWeb.Plugs.Authentication do
	@behaviour Plug
  	import Plug.Conn
  	import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  	alias Language.Authenticator.Session
  	alias Language.SessionHelper

	def init(opts) do 
		opts
	end

	def call(conn, [level: level]) do
		if level == :admin do
			authenticate_admin(conn)
		else
			authenticate(conn)
		end
	end

	def authenticate(conn) do
		case SessionHelper.get_valid_session(conn) do
			%Session{user_id: id} -> assign(conn, :user, id)
			nil -> fail_authentication(conn)
		end
	end

	def authenticate_admin(conn) do
		# Currently allow everyone as admin (authentication already happens)
		conn
	end

	defp fail_authentication(conn) do
		put_flash(conn, :info, "You must be logged in")
		|> redirect(to: "/login")
		|> halt
	end
end