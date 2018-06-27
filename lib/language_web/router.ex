defmodule LanguageWeb.Router do
  use LanguageWeb, :router

  alias Language.Accounts.Pipeline

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :authenticate do
    plug(:browser)
    plug(Pipeline)
  end

  scope "/", LanguageWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/login", AuthenticationController, :login)
    post("/login", AuthenticationController, :login)
    get("/logout", AuthenticationController, :logout)
    get("/signup", UserController, :new)
    post("/create", UserController, :create)
  end

  scope "/", LanguageWeb do
    pipe_through(:authenticate)

    get("/start", ReadController, :start)
    get("/", ReadController, :start)
    get("/browse", ReadController, :browse)
    resources("/users", UserController, except: [:new, :create])
  end

  scope "/vocab", LanguageWeb do
    pipe_through(:authenticate)

    resources("/wordlists", WordListController)
    resources("/words", WordController)
  end
end
