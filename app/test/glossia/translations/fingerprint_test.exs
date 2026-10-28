defmodule Glossia.Translations.FingerprintTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Fingerprint

  test "canonicalizes object keys recursively without reordering arrays" do
    assert Fingerprint.hash(%{validation: [%{b: 2, a: 1}], checks: %{fr: "oui", es: "sí"}}) ==
             Fingerprint.hash(%{
               "checks" => %{"es" => "sí", "fr" => "oui"},
               "validation" => [%{"a" => 1, "b" => 2}]
             })

    refute Fingerprint.hash(["first", "second"]) == Fingerprint.hash(["second", "first"])
    assert Fingerprint.hash(%{b: 2, a: 1}) == digest(~s({"a":1,"b":2}))
  end

  test "recognizes both validation fingerprints observed in production" do
    hashes =
      Fingerprint.legacy_hashes(
        %{check_cmd: nil, check_cmds: %{}, validation: nil, validation_relative_path: nil},
        [:check_cmd, :check_cmds, :validation, :validation_relative_path]
      )

    assert MapSet.size(hashes) == 24
    assert "ae3606ed9b1629c1a55145739b0db6174aa75ed71272a6af6089832cad7abbfc" in hashes
    assert "064760dc472b525acbc80c5ce08973a94fc7a5b06ba42cfab835324c7c048924" in hashes
  end

  test "legacy glossary aliases keep array order, values and record membership" do
    entries = [
      %{
        term: "lockfile",
        translation: "archivo de bloqueo",
        definition: nil,
        case_sensitive: false
      },
      %{term: "voice", translation: "voz", definition: "Tone", case_sensitive: true}
    ]

    hashes =
      Fingerprint.legacy_hashes(entries, [:term, :definition, :case_sensitive, :translation])

    assert digest(JSON.encode!(entries)) in hashes
    refute digest(JSON.encode!(Enum.reverse(entries))) in hashes

    refute digest(JSON.encode!([%{hd(entries) | translation: "wrong"}, List.last(entries)])) in hashes
  end

  defp digest(json), do: :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)
end
