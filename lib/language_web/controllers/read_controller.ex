defmodule LanguageWeb.ReadController do
	use LanguageWeb, :controller

	alias Language.{ExternalSite, TextModifier}

	def browse(conn, %{"site" => site}) do
		case ExternalSite.get_site(site) do
			{:ok, content} ->
				user = Guardian.Plug.current_resource(conn)
				value = ExternalSite.update_site(site, content, 
					%{update_visible_links: &create_local_link/1, 
					update_visible_text: TextModifier.get_update_function(user.id)},\
					get_resources_links(conn))
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

	defp create_local_link(url) do
		read_path(LanguageWeb.Endpoint, :browse, site: url)
	end

	defp get_resources_links(conn) do
		[{"link", [{"rel", "stylesheet"}, {"href", static_path(conn, "/css/readview.css")}], []},
		{"script", [{"src", static_path(conn, "/js/readview.js")}], []},
		{"script", [], ["""
		document.addEventListener('DOMContentLoaded', function() {
			require("js/readview.js").init();
		}, false);
		"""]}]
	end
end