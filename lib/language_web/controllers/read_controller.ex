defmodule LanguageWeb.ReadController do
	use LanguageWeb, :controller

	require HTTPoison

	def index(conn, %{"site" => site}) do
		case HTTPoison.get(site) do
			{:ok, %HTTPoison.Response{status_code: 200, body: content}} ->
				# We need the base site requested so that we can fix relative urls
				value = URI.parse(site)
				|> parse_html(content)
				html(conn, value)
			{:ok, _response} ->
				put_flash(conn, :error, "An error occurred when trying to read from the site")
			{:error, _response} ->
				put_flash(conn, :error, "Invalid URL")
		end
		redirect(conn, to: read_path(conn, :start))
	end

	def index(conn, _params) do 
		redirect(conn, to: read_path(conn, :start))
	end

	def parse_html(site, page) do
		Floki.find(page, "html")
		|> Floki.map(fn({name, attr}) -> mapped_html(site, name, attr) end)
		|> Floki.raw_html
	end

	def mapped_html(site, name, attr) do
		# References to resources (ie, html elements in <head>) should use direct
		# urls rather than being redirected through this website.
		make_local_link = name not in ["title", "style", "meta", "link", "script", "base", "img"]
		{name, Enum.map(attr, fn(value) -> update_html(site, make_local_link, value) end)}
	end

	def update_html(_site, _make_local_link, [text]) when is_binary(text) do
		# TODO: Update text according to transformations.
		[text]
	end

	def update_html(site, make_local_link, value) when is_list(value) do
		Enum.map(value, fn(value) -> update_html site, make_local_link, value end)
	end

	def update_html(site, make_local_link, value) when is_tuple(value) do
		for i <- 0..(tuple_size(value) - 1) do
			element = elem(value, i)
			cond do
				is_binary(element) ->
					# Might be a url
					update_url(site, make_local_link, element)
				true -> 
					# Update the tuple or list
					update_html(site, make_local_link, element)
			end
		end
		|> List.to_tuple
	end

	def update_url(retrieved_uri, convert_local, possible_urls) do
		String.split(possible_urls, ", ")
		|> Enum.map(fn(path) -> update_url_path(retrieved_uri, path, convert_local) end)
		|> Enum.join(", ")
	end

	def update_url_path(retrieved_uri, maybe_uri, convert_local) do
		if String.starts_with?(maybe_uri, "/") do
			if String.starts_with?(maybe_uri, "//") do
				# The uri is absolute so just add the scheme.
				retrieved_uri.scheme <> ":" <> maybe_uri
			else
				# The uri is relative, so add the scheme and the retrieved uri.
				retrieved_uri.scheme <> ":/" <> retrieved_uri.host <> maybe_uri
			end
			|> update_url(convert_local)
		else
			# Presumably not a uri at all
			maybe_uri
		end
	end

	def update_url(absolute_url, convert_local) do
		if convert_local do
			read_path(LanguageWeb.Endpoint, :index, site: absolute_url)
		else
			absolute_url
		end
	end

	def start(conn, _params) do
		render conn, "start.html"
	end
end