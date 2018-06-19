defmodule LanguageWeb.Router do
  use LanguageWeb, :router

  alias LanguageWeb.Plugs.Authentication

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticate do
    plug :browser
    plug Authentication, level: :user
  end

  pipeline :authenticate_admin do
    plug :authenticate
    plug Authentication, level: :admin
  end

  scope "/", LanguageWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/login", SessionController, :login
    post "/login", SessionController, :login
    get "/logout", SessionController, :logout
    get "/signup", UserController, :new
    post "/create", UserController, :create
  end

  scope "/", LanguageWeb do
    pipe_through :authenticate 

    get "/browse", ReadController, :browse
    get "/start", ReadController, :start
  end

  scope "/", LanguageWeb do
    pipe_through :authenticate_admin

    resources "/users", UserController, except: [:new, :create]
  end

  scope "/vocab", LanguageWeb do
    pipe_through :authenticate

    resources "/wordlists", WordListController
    resources "/words", WordController
  end

end
