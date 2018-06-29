defmodule LanguageWeb.Router do
  use LanguageWeb, :router

  alias Language.Accounts.{MaybeAuthenticatedPipeline, AuthenticatedPipeline}

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :authenticate do
    plug(:browser)
    plug(AuthenticatedPipeline)
  end

  pipeline :maybe_authenticate do
    plug(:browser)
    plug(MaybeAuthenticatedPipeline)
  end

  scope "/", LanguageWeb do
    # Use the default browser stack
    pipe_through(:maybe_authenticate)

    get("/login", AuthenticationController, :login)
    post("/login", AuthenticationController, :login)
    get("/logout", AuthenticationController, :logout)
    get("/signup", UserController, :new)
    post("/create", UserController, :create)
    get("/public", WordListController, :public)
  end

  scope "/", LanguageWeb do
    pipe_through(:authenticate)

    get("/start", ReadController, :start)
    get("/", ReadController, :start)
    get("/browse", ReadController, :browse)
    resources("/users", UserController, except: [:new, :create])
    get("/users/grant/admin", UserController, :make_admin)
  end

  scope "/vocab", LanguageWeb do
    pipe_through(:authenticate)

    resources("/wordlists", WordListController)
    resources("/words", WordController)
    get("/share/:id", WordListController, :share)
    post("/share/:id", WordListController, :share)
    get("/claim/:id", WordListController, :claim)
    post("/claim/:id", WordListController, :claim)
  end
end
