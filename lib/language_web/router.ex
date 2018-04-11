defmodule LanguageWeb.Router do
  use LanguageWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", LanguageWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/browse", ReadController, :browse
    get "/start", ReadController, :start
    resources "/users", UserController
  end

end
