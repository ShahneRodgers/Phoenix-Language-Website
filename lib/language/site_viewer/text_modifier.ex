defmodule Language.TextModifier do
	@moduledoc """
	Helper functions for updating the text on viewed websites
	"""
	alias Language.Vocab

	def get_update_function(user_id) do
		Vocab.list_words_by_user(user_id)
		|> Map.new(fn(word) -> {normalise_string(word.native), word} end)
		|> create_update_function()
	end

	defp create_update_function(word_map) do
		max_word_count = Enum.max_by(word_map, &calculate_original_word_count/1)
						|> calculate_original_word_count
		fn(value) -> 
			translate(word_map, value, max_word_count)
		end
	end

	defp translate(word_map, original, max_word_count) do
		word_parts = String.split(original, ~r{\s}, trim: false)
		search_for_match(word_map, word_parts, max_word_count)
	end

	defp search_for_match(word_map, word_parts, max_word_count) do
		# For each word, iterate through the word + subsequent words until either
		# a match is found, max_word_count is reached or we run out of words. 
		# Eg, given max_word_count of 3 and the sentence "This is an example sentence",
		# we should test: This, This is, This is an, is, is an, is an example ...
		search_for_match(word_map, word_parts, max_word_count, 0, 1)
	end

	defp search_for_match(word_map, word_parts, _max_word_count, i, _num_words) when length(word_parts) - 1 == i do
		# We've reached the end of our list so return the marked up final word if it's a match, 
		# otherwise the final word as a list.
		result = get_match_marked_up(word_map, word_parts, i, 1)
		if result do
			[result]
		else
			[Enum.at(word_parts, i) <> " "]
		end
	end

	defp search_for_match(word_map, word_parts, max_word_count, i, num_words) when length(word_parts) == i + num_words do
		result = get_match_marked_up(word_map, word_parts, i, num_words)

		if result do
			# Result includes the rest of the words, so we don't need to check any more.
			[result]
		else
			# i + num_words already includes the last word in word_parts, so we have to reset num_words
			# to 1 and increment i.
			[Enum.at(word_parts, i) <> " "] ++ search_for_match(word_map, word_parts, max_word_count, i + 1, 1)
		end
	end

	defp search_for_match(word_map, word_parts, max_word_count, i, num_words) when num_words == max_word_count do
		result = get_match_marked_up(word_map, word_parts, i, num_words)

		if result do
			[result] ++ search_for_match(word_map, word_parts, max_word_count, i + num_words, 1)
		else
			# i to num_words is the maximum phrase length we want to check, so the word at i should
			# not change and we should move on to check the next word.
			[Enum.at(word_parts, i) <> " "] ++ search_for_match(word_map, word_parts, max_word_count, i + 1, 1)
		end
	end

	defp search_for_match(word_map, word_parts, max_word_count, i, num_words) do
		result = get_match_marked_up(word_map, word_parts, i, num_words)

		if result do
			[result] ++ search_for_match(word_map, word_parts, max_word_count, i + num_words, 1)
		else
			# Check if the phrase from i to num_words + 1 matches.
			search_for_match(word_map, word_parts, max_word_count, i, num_words + 1)
		end
	end

	defp get_match_marked_up(word_map, word_parts, i, num_words) do
		str = Enum.slice(word_parts, i, num_words)
		|> Enum.reduce(fn(x, acc) -> acc <> " #{x}" end)

		match = Map.get(word_map, normalise_string(str))

		if match do
			mark_up_word(match, str)
		else
			nil
		end
	end

	defp mark_up_word(word, original) do
		replacement = retain_formatting(word.replacement, original)
		{"span", [{"title", original}, {"id", "phoenix_translated_value"}], [" " <> replacement <> " "]}
	end

	defp retain_formatting(replacement, original) do
		# We endeavor to match the original's punctuation and capitalisation as much as possible.
		retain_capitalisation(replacement, original)
		|> retain_non_word_characters(original)	
	end

	defp retain_capitalisation(replacement, original) do
		# For capitalisation, we ignore all non-letter characters and only consider
		# the cases that make obvious sense (ie, given 'first' should be translated to
		# 'tahi', there's no clear way to retain the capitalisation of 'fIrst', 'fiRst', 
		# 'fiRST', etc)
		cond do
			# original is completely upper case
			String.match?(original, ~r{^[\W_\dA-Z]+$}) -> String.upcase(replacement)

			# original is completely lower case
			String.match?(original, ~r{^[\W_\da-z]+$}) -> String.downcase(replacement)

			# original starts with upper case
			String.match?(original, ~r{^[\W_\dA-Z]}) -> String.capitalize(replacement)

			# original starts with lower case
			String.match?(original, ~r{^[\W_\da-z]}) -> 
				(String.first(replacement) |> String.upcase()) <> String.slice(replacement, 1..-1)
		end
	end

	defp retain_non_word_characters(replacement, original) do
		# As with capitalisations, it only really makes sense to retain the pre- and post- non word
		# characters.
		matches = Regex.named_captures(~r{^(?<start>[\W_\d]*).*?(?<end>[\W_\d]*)$}, original)
		matches["start"] <> replacement <> matches["end"]
	end

	defp calculate_original_word_count({_normalised, word}) do
		String.split(word.native)
		|> length()
	end

	defp normalise_string(str) do
		String.downcase(str)
		|> String.replace(~r{\W|_|\d}, "")
	end
end