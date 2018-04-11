defmodule Language.ExternalSiteTest do
  use Language.DataCase

  import Mock
  import LanguageWeb.Router.Helpers

  alias Language.ExternalSite

  defp get_http_poison_response(status_code, body) do
  	%HTTPoison.Response{status_code: status_code, body: body}
  end

  test "HTTP get returns 200 code" do
  	content = "<html></html>"
  	with_mock HTTPoison, [get: fn(_url) -> {:ok, get_http_poison_response(200, content)} end] do
  		# Check content is correctly returned.
  		assert {:ok, ^content} = ExternalSite.get_site("http://example.com")
  		# And that HTTPoison is called with the correct parameters.
  		assert called HTTPoison.get("http://example.com")
  	end
  end

  test "HTTP get returns 404 code" do
  	with_mock HTTPoison, [get: fn(_url) -> {:ok, get_http_poison_response(404, "not found")} end] do
  		assert {:error, "The site returned a 404 response"} = ExternalSite.get_site("notfound.site")
  		assert called HTTPoison.get("notfound.site")
  	end
  end

  test "Site does not return" do
  	with_mock HTTPoison, [get: fn(_url) -> {:error, "ignored"} end] do
  		assert {:error, "The site could not be reached"} = ExternalSite.get_site("dsf")
  	end
  end

  test "Update site does not change head with no relative urls" do
  	html = "<html><head><title class=\"something\"> test</title>" <> 
      "<style id=\"some_id\"></style><meta name=\"ResourceLoaderDynamicStyles\" content=\"\"/>" <>
  	  "<link rel=\"stylesheet\" href=\"www.somesite.com\"/>" <> 
      "<meta name=\"generator\" content=\"MediaWiki 1.31.0-wmf.27\"/><script>Some script</script>" <>
  	  "<base>Some base</base></head></html>"

  	result = ExternalSite.update_site("original_url", html, 
  		%{:update_visible_links => &assert_false/1, :update_visible_text => &assert_false/1 })
  	assert_string_equal_ignore_space(result, html)
  end

  test "Update site fixes relative urls" do
  	html = "<html><head><link rel=\"stylesheet\" href=\"/some/path\"/>" <> 
           "<img a=\"//test.com\"/></head></html>"

  	result = ExternalSite.update_site("https://original_url.co.nz/initial/path/", html, 
  		%{:update_visible_links => &assert_false/1, :update_visible_text => &assert_false/1 })

    assert_string_equal_ignore_space(result, "<html><head><link rel=\"stylesheet\"" <>
      " href=\"https://original_url.co.nz/some/path\"/><img a=\"https://test.com\"/>" <>
      "</head></html>")
  end

  test "Update site updates body urls" do
    html = "<html><body><p href=\"//abso.lute.url\"></p><a href=\"/relativepath\"></a></body></html>"

    result = ExternalSite.update_site("https://original_url.co.nz/initial/path/", html, 
      %{:update_visible_links => fn value -> "mysite:" <> value end, :update_visible_text => &assert_false/1 })

    expected = String.replace(html, "//abso.lute.url", "mysite:https://abso.lute.url")
    |> String.replace("/relativepath", "mysite:https://original_url.co.nz/relativepath")

    assert_string_equal_ignore_space(result, expected)
  end

  test "Update site updates body text" do
    html = "<html><head><title>This is a title</title></head>" <> 
    "<body><p id=\"some id\">This is a paragraph</p></body></html>"

    result = ExternalSite.update_site("www.site.com", html,
      %{:update_visible_links => &assert_false/1, 
      :update_visible_text => fn value -> "!Updated #{value} !" end})

    expected = String.replace(html, "This is a paragraph", "!Updated This is a paragraph !")

    assert result == expected
  end

  defp assert_string_equal_ignore_space(observed, expected) do
    assert String.replace(observed, ~r/\n\t/, "") == String.replace(expected, ~r/\n\t/, "")
  end

  defp assert_false(_value) do
  	assert false
  end

end