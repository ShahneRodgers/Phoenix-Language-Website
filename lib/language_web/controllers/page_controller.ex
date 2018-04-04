defmodule LanguageWeb.PageController do
  use LanguageWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
