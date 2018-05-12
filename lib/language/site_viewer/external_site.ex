defmodule Language.ExternalSite do
  @moduledoc """
  Helper functions for displaying external sites.
  """
  require HTTPoison

	def get_site(site) do
		case HTTPoison.get(site) do
			{:ok, %HTTPoison.Response{status_code: 200, body: content}} ->
				{:ok, content}
			{:ok, response} ->
				{:error, "The site returned a #{response.status_code} response"}
			{:error, _response} ->
				{:error, "The site could not be reached"}
		end
	end

	def update_site(original_url, site_content, %{:update_visible_links => _func, :update_visible_text => _func2 } = update_functions) do
		#  We need the base site requested so that we can fix relative urls
		URI.parse(original_url)
		|> parse_html(site_content, update_functions)
	end

	defp parse_html(site, page, update_functions) do
		Floki.parse(page)
		|> mapped_html(site, update_functions)
		|> Floki.raw_html
	end

	defp mapped_html({name, attributes, value}, site, update_functions) do
		if name == "html" do
			{name, attributes, Enum.map(value, fn(value) -> mapped_html(value, site, update_functions) end)}
		else
			# References to resources (ie, html elements in <head>) should use direct
			# urls rather than being redirected through this website.
			{name, attributes, Enum.map(value, fn(val) -> update_html(site, update_functions, name=="body", val) end)}
		end
	end

	defp update_html(_site, %{:update_visible_text => update_text}, is_visible, [text]) when is_binary(text) do
		if is_visible do
			update_text.(text)
		else
			[text]
		end
	end

	defp update_html(site, update_functions, is_visible, value) when is_list(value) do
		Enum.map(value, fn(value) -> update_html(site, update_functions, is_visible, value) end)
		# Flatten the list since update_html might need to return a list of new "HTML nodes"
		# rather than just a single HTML node. It seems like Floki never nests lists naturally.
		|> List.flatten
	end

	defp update_html(site, update_functions, is_visible, value) when is_tuple(value) and tuple_size(value) == 3 do
		# Tuples with three elements are in the form of {tag, attributes, child_nodes}
		tag = elem(value, 0)
		# Embedded images don't need to be redirected through this site since they don't have words
		# to update (no OCR support).
		is_visible = is_visible and tag not in ["img"]

		attributes = update_html(site, update_functions, is_visible, elem(value, 1))

		text = update_html(site, update_functions, is_visible, elem(value, 2))

		{tag, attributes, text}
	end

	defp update_html(site, update_functions, is_visible, value) when is_tuple(value) and tuple_size(value) == 2 do
		# Tuples with two elements are attribute pairs.
		attr_type = elem(value, 0)

		# It might be better to check the attr_type for href, link, etc - but there are 18
		# possible attribute types listed here: https://www.w3.org/TR/REC-html40/index/attributes.html
		# and that would require changing the code if anything new is added.
		attr_value = update_possible_urls(site, update_functions, is_visible, elem(value, 1))

		{attr_type, attr_value}
	end

	defp update_html(_site, %{:update_visible_text => update_text}, is_visible, value) do
		if is_binary(value) and is_visible do
			update_text.(value)
		else
			value
		end
	end

	defp update_possible_urls(retrieved_uri, update_functions, is_visible, possible_urls) do
		String.split(possible_urls, ", ")
		|> Enum.map(fn(path) -> update_url_path(retrieved_uri, path, update_functions, is_visible) end)
		|> Enum.join(", ")
	end

	defp update_url_path(retrieved_uri, maybe_uri, update_functions, is_visible) do
		if String.starts_with?(maybe_uri, "/") do
			if String.starts_with?(maybe_uri, "//") do
				# The uri is absolute so just add the scheme.
				retrieved_uri.scheme <> ":" <> maybe_uri
			else
				# The uri is relative, so add the scheme and the retrieved uri.
				retrieved_uri.scheme <> "://" <> retrieved_uri.host <> maybe_uri
			end
			|> update_absolute_url(update_functions, is_visible)
		else
			# Presumably not a uri at all
			maybe_uri
		end
	end

	defp update_absolute_url(absolute_url, %{:update_visible_links => link_update_func}, is_visible) do
		if is_visible do
			link_update_func.(absolute_url)
		else
			absolute_url
		end
	end
end