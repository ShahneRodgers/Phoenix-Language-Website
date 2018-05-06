defmodule Language.TestHelpers do

	alias Language.Accounts
  	alias Language.Vocab
	alias Language.Repo

	require Phoenix.ConnTest
	require ExUnit.Assertions

	# The default endpoint for testing
    @endpoint LanguageWeb.Endpoint

    @password "testpassword"

	def ensure_user() do
		user = Accounts.find_by_username("testuser")
		if user do
			user
		else
			{:ok, user} = Accounts.create_user(%{email: "someemail@test.com", username: "testuser", password: @password})
			user
		end
	end

	def ensure_other_user do
		Repo.insert! %Accounts.User{email: "test@test.com", username: "testuser2", password: "password2"}
	end

	def get_raw_test_user_password() do
		@password
	end

	def act_as_user(conn) do
		ensure_user()
		conn = Phoenix.ConnTest.post(conn, "/login", %{"username" => "testuser", "password" => "testpassword"})
		|> Phoenix.ConnTest.recycle

		conn
	end

	def create_word_list(user) do
		Repo.insert! %Vocab.WordList{title: "Test Wordlist", user_id: user.id}
	end

	def create_word_list() do
		ensure_user()
		|> create_word_list
	end

	def create_word(native, replacement, audio \\ nil, notes \\ nil) do
		user = ensure_user()
		word_list = create_word_list(user)

		Repo.insert! %Vocab.Word{native: native, replacement: replacement, 
					audio: audio, notes: notes, word_list_id: word_list.id}
	end
end