# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Language.Repo.insert!(%Language.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

defmodule SetUp do
	def get_env(key) do
		Application.get_env(:language, key)
	end

	def get_password_env(key) do
		get_env(key)
		|> Comeonin.Bcrypt.hashpwsalt()
	end
end

admin_user = %Language.Accounts.User{username: SetUp.get_env(:admin_username), password: SetUp.get_password_env(:admin_password)}
			|> Language.Repo.insert!()
Language.Repo.insert %Language.Accounts.Admin{user_id: admin_user.id}
