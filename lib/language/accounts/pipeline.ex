defmodule Language.Accounts.MaybeAuthenticatedPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :language,
    error_handler: Language.Accounts.ErrorHandler,
    module: Language.Accounts.Guardian

  @claims %{iss: "language"}

  plug(Guardian.Plug.VerifySession, claims: @claims)

  plug(Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer")

  plug(Guardian.Plug.LoadResource, allow_blank: true)
end

defmodule Language.Accounts.AuthenticatedPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :language,
    error_handler: Language.Accounts.ErrorHandler,
    module: Language.Accounts.Guardian

  plug(Language.Accounts.MaybeAuthenticatedPipeline)

  plug(Guardian.Plug.EnsureAuthenticated)

  plug(Guardian.Plug.LoadResource, allow_blank: false)
end
