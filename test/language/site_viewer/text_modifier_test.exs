defmodule Language.TextModifierTest do
  use Language.DataCase

  alias Language.{TestHelpers, TextModifier}

  setup do
    user = TestHelpers.ensure_user()

    {:ok, [user: user.id]}
  end

  describe "simple word translation" do
    setup [:create_word]

    test "translates single word", %{user: id, original: orig, updated: updated} do
      obs =
        TextModifier.get_update_function(id).(orig)
        |> Floki.raw_html()

      assert_result(obs, orig, updated)
    end

    test "ignores case", %{user: id, original: orig, updated: updated} do
      obs =
        TextModifier.get_update_function(id).(String.upcase(orig))
        |> Floki.raw_html()

      assert_result(String.downcase(obs), String.downcase(orig), String.downcase(updated))
    end

    test "retains capitalization", %{user: id, original: orig, updated: updated} do
      obs =
        TextModifier.get_update_function(id).(String.capitalize(orig))
        |> Floki.raw_html()

      assert_result(obs, String.capitalize(orig), String.capitalize(updated))
    end

    test "keeps punctuation", %{user: id, original: orig, updated: updated} do
      text = "%_" <> orig <> "!"

      obs =
        TextModifier.get_update_function(id).(text)
        |> Floki.raw_html()

      assert_result(obs, text, "%_" <> updated <> "!")
    end

    test "ignores punctuation inside word", %{user: id, original: orig, updated: updated} do
      text = String.first(orig) <> "&" <> String.slice(orig, 1..-1)

      obs =
        TextModifier.get_update_function(id).(text)
        |> Floki.raw_html()

      assert_result(obs, text, updated)
    end

    test "doesn't translate unknown word", %{user: id} do
      obs = TextModifier.get_update_function(id).("unknownword")
      assert obs == ["unknownword "]
    end

    test "translates word in sentence", %{user: id, original: orig, updated: updated} do
      obs =
        TextModifier.get_update_function(id).("Some sentence containing #{orig}")
        |> Floki.raw_html()

      assert_result(obs, "Some sentence containing " <> expected_html(orig, updated))
    end

    test "translates every matching word in the sentence", %{
      user: id,
      original: orig,
      updated: updated
    } do
      obs =
        TextModifier.get_update_function(id).("Some #{orig} sentence #{orig} containing #{orig}")
        |> Floki.raw_html()

      orig_translated = expected_html(orig, updated)

      assert_result(
        obs,
        "Some #{orig_translated}sentence #{orig_translated}containing #{orig_translated}"
      )
    end

    test "translates all matching words in sentence", %{
      user: id,
      original: orig,
      updated: updated
    } do
      TestHelpers.create_word("second", "tuarua")

      obs =
        TextModifier.get_update_function(id).("Some sentence with #{orig} and second")
        |> Floki.raw_html()

      assert_result(
        obs,
        "Some sentence with #{expected_html(orig, updated)}and #{
          expected_html("second", "tuarua")
        }"
      )
    end
  end

  describe "translates phrase" do
    setup [:create_phrase]

    test "translates phrase", %{user: id, original: orig, updated: updated} do
      obs =
        TextModifier.get_update_function(id).(orig)
        |> Floki.raw_html()

      assert_result(obs, orig, updated)
    end

    test "translates phrase in sentence", %{user: id, original: orig, updated: updated} do
      obs =
        TextModifier.get_update_function(id).("Some phrase containing #{orig}")
        |> Floki.raw_html()

      assert_result(obs, "Some phrase containing #{expected_html(orig, updated)}")
    end

    test "translates phrase multiple times in sentence", %{
      user: id,
      original: orig,
      updated: updated
    } do
      obs =
        TextModifier.get_update_function(id).("#{orig} phrase #{orig} containing #{orig}")
        |> Floki.raw_html()

      orig_translated = expected_html(orig, updated)

      assert_result(
        obs,
        "#{orig_translated}phrase #{orig_translated}containing #{orig_translated}"
      )
    end

    test "ignores case", %{user: id, original: orig, updated: updated} do
      obs =
        TextModifier.get_update_function(id).(String.upcase(orig))
        |> Floki.raw_html()

      assert_result(String.downcase(obs), String.downcase(orig), String.downcase(updated))
    end

    test "does nothing for split phrase", %{user: id, original: orig} do
      words = String.split(orig)
      expected = hd(words) <> " split " <> Enum.join(tl(words), " ")

      obs =
        TextModifier.get_update_function(id).(expected)
        |> Floki.raw_html()

      assert_result(obs, "\s?#{expected}\s?")
    end

    test "split only by non-letters", %{user: id, original: orig, updated: updated} do
      words = String.split(orig)
      text = hd(words) <> "1~_" <> Enum.join(tl(words), "")

      obs =
        TextModifier.get_update_function(id).(text)
        |> Floki.raw_html()

      assert_result(obs, text, updated)
    end
  end

  test "Word translation includes audio link", %{user: id} do
    TestHelpers.create_word("original", "updated", "some:audio:link")

    obs =
      TextModifier.get_update_function(id).("original")
      |> Floki.raw_html()

    assert_result(obs, ".+<audio src=\"some:audio:link\" .+")
  end

  test "Word translation doesn't include empty audio link", %{user: id} do
    TestHelpers.create_word("original", "updated")

    obs =
      TextModifier.get_update_function(id).("original")
      |> Floki.raw_html()

    refute obs =~ "audio"
  end

  test "Word translation includes notes", %{user: id} do
    TestHelpers.create_word("original", "updated", nil, "some notes")

    obs =
      TextModifier.get_update_function(id).("original")
      |> Floki.raw_html()

    assert_result(obs, ".+<p class=\"phoenix_translated_notes\">some notes</p>.+")
  end

  test "Word translation doesn't include empty notes link", %{user: id} do
    TestHelpers.create_word("original", "updated", nil, nil)

    obs =
      TextModifier.get_update_function(id).("original")
      |> Floki.raw_html()

    refute obs =~ "notes"
  end

  test "Handles no vocab", %{user: id} do
    text = "Just check it doesn't blow up from assuming the user has vocab"
    obs = TextModifier.get_update_function(id).(text)

    assert obs == [text]
  end

  defp expected_html(original_word, new_word) do
    "<span title=\"#{original_word}\" class=\"phoenix_translated_value\"> #{new_word} .*?<\/span>"
  end

  defp assert_result(observed, original_word, new_word) do
    assert_result(observed, expected_html(original_word, new_word))
  end

  defp assert_result(observed, expected) do
    assert Regex.match?(~r/^#{expected}$/, observed)
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
