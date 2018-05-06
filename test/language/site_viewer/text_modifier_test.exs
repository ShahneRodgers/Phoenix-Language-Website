defmodule Language.TextModifierTest do
	use Language.DataCase

	alias Language.{TestHelpers, TextModifier}

	setup do
		user = TestHelpers.ensure_user()

		{:ok, [user: user.id]}
	end

	describe "Simple word translation" do
		setup [:create_word]

		test "translates single word", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).(orig)
			|> Floki.raw_html
			assert obs == expected_html(orig, updated)
		end

		test "ignores case", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).(String.upcase(orig))
			|> Floki.raw_html

			assert String.downcase(obs) == String.downcase(expected_html(String.upcase(orig), String.upcase(updated)))
		end

		test "retains capitalization", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).(String.capitalize(orig))
			|> Floki.raw_html
			assert obs == expected_html(String.capitalize(orig), String.capitalize(updated))
		end

		test "keeps punctuation", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).(orig <> "!")
			|> Floki.raw_html

			assert obs == expected_html(orig, updated <> "!")
		end

		test "doesn't translate unknown word", %{user: id} do
			obs = TextModifier.get_update_function(id).("unknownword")
			assert obs == ["unknownword "]
		end

		test "translates word in sentence", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).("Some sentence containing #{orig}")
			|> Floki.raw_html

			assert obs == "Some sentence containing " <> expected_html(orig, updated)
		end

		test "translates every matching word in the sentence", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).("Some #{orig} sentence #{orig} containing #{orig}")
			|> Floki.raw_html

			orig_translated = expected_html(orig, updated)

			assert obs == "Some #{orig_translated}sentence #{orig_translated}containing #{orig_translated}"
		end

		test "translates all matching words in sentence", %{user: id, original: orig, updated: updated} do
			TestHelpers.create_word("second", "tuarua")

			obs = TextModifier.get_update_function(id).("Some sentence with #{orig} and second")
			|> Floki.raw_html

			assert obs == "Some sentence with " <> expected_html(orig, updated) <> "and " <>
				expected_html("second", "tuarua")
		end
	end

	describe "Translates phrase" do
		setup [:create_phrase]

		test "translates phrase", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).(orig)
			|> Floki.raw_html
			assert obs == expected_html(orig, updated)
		end

		test "translates phrase in sentence",  %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).("Some phrase containing #{orig}")
			|> Floki.raw_html
			assert obs == "Some phrase containing " <> expected_html(orig, updated)
		end

		test "translates phrase multiple times in sentence", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).("#{orig} phrase #{orig} containing #{orig}")
			|> Floki.raw_html

			orig_translated = expected_html(orig, updated)

			assert obs == "#{orig_translated}phrase #{orig_translated}containing #{orig_translated}"
		end

		test "ignores case", %{user: id, original: orig, updated: updated} do
			obs = TextModifier.get_update_function(id).(String.upcase(orig))
			|> Floki.raw_html
			assert String.downcase(obs) == String.downcase(expected_html(String.upcase(orig), String.upcase(updated)))
		end

		test "doesn't translate split phrase", %{user: id, original: orig} do
			words = String.split(orig)
			expected = hd(words) <> " split " <> Enum.join(tl(words), " ")
			obs = TextModifier.get_update_function(id).(expected)
				  |> Floki.raw_html

			assert obs == [expected]
		end
	end

	describe "Word translation with audio link" do
		
	end

	describe "Word translation with notes" do
		
	end

	defp expected_html(original_word, new_word) do
		"<span title=\"" <> original_word <> "\" id=\"phoenix_translated_value\"> " <> 
		new_word <> " </span>"
	end

	defp create_word(_context) do
		add_vocab("first", "tuatahi")
  	end

  	defp create_phrase(_context) do
  		add_vocab("first word", "kupu tuatahi")
  	end

  	defp add_vocab(original, updated) do
    	TestHelpers.create_word(original, updated)
    	{:ok, [original: original, updated: updated]}
    end
end