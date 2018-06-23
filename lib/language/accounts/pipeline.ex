defmodule Language.Accounts.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :language,
    error_handler: Language.Accounts.ErrorHandler,
    module: Language.Accounts.Guardian

  @claims %{iss: "language"}
  
  plug Guardian.Plug.VerifySession, claims: @claims
  
  plug Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer"
  
  plug Guardian.Plug.EnsureAuthenticated
  
  plug Guardian.Plug.LoadResource
end