defmodule LanguageWeb.ReadController do
	use LanguageWeb, :controller

	alias Language.ExternalSite
	alias Language.TextModifier

	def browse(conn, %{"site" => site}) do
		case ExternalSite.get_site(site) do
			{:ok, content} ->
				value = ExternalSite.update_site(site, content, 
					%{update_visible_links: &create_local_link/1, 
					update_visible_text: TextModifier.get_update_function(conn.assigns[:user])})
				html(conn, value)
			{:error, message} ->
				put_flash(conn, :error, message)
				|> redirect(to: read_path(conn, :start))
		end
	end

	def browse(conn, _params) do 
		redirect(conn, to: read_path(conn, :start))
	end

	def start(conn, _params) do
		render conn, "start.html"
	end

	def create_local_link(url) do
		read_path(LanguageWeb.Endpoint, :browse, site: url)
	end
end