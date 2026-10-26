defmodule Glossia.GettextCatalogsTest do
  use ExUnit.Case, async: true

  alias Expo.Message.Singular
  alias Expo.Messages
  alias Expo.PO
  alias Gettext.Extractor
  alias Gettext.Merger

  @baseline [
    "Bravo baseline",
    "Charlie baseline",
    "Delta baseline",
    "Echo baseline",
    "Foxtrot baseline",
    "Golf baseline",
    "Hotel baseline",
    "Zulu baseline"
  ]
  @license "Apache-2.0 core + Enterprise License"
  @preview "Translated output preview"

  test "checked-in templates and locale catalogs use canonical message ordering" do
    assert gettext_config()[:sort_by_msgid] == :case_sensitive

    for path <- Path.wildcard(Application.app_dir(:glossia, "priv/gettext/**/*.{pot,po}")) do
      ids = path |> PO.parse_file!() |> message_ids()
      assert ids == Enum.sort(ids), "Unsorted Gettext catalog: #{path}"

      if Path.basename(path) in ["default.pot", "default.po"] do
        assert @license in ids
        assert @preview in ids
      end
    end
  end

  @tag :tmp_dir
  test "independent additions merge without losing messages or translations", %{tmp_dir: root} do
    assert {output, 0} = merge_independent_additions(root, gettext_config())
    refute output =~ "CONFLICT"

    for path <- ["default.pot", "es.po"] do
      catalog = root |> Path.join(path) |> PO.parse_file!()
      assert message_ids(catalog) == Enum.sort(@baseline ++ [@license, @preview])
    end

    translations = root |> Path.join("es.po") |> PO.parse_file!() |> translations()

    for id <- @baseline ++ [@license, @preview] do
      assert translations[id] == "Traducción: #{id}"
    end

    assert {"", 0} = git(root, ["diff", "--check"])
    assert {"", 0} = git(root, ["ls-files", "--unmerged"])
  end

  @tag :tmp_dir
  test "the previous append-only ordering reproduces the conflict", %{tmp_dir: root} do
    config = Keyword.put(gettext_config(), :sort_by_msgid, false)
    assert {output, 1} = merge_independent_additions(root, config)
    assert output =~ "CONFLICT"
    assert {unmerged, 0} = git(root, ["diff", "--name-only", "--diff-filter=U"])
    assert String.split(unmerged) == ["default.pot", "es.po"]
  end

  defp merge_independent_additions(root, config) do
    assert {_, 0} = git(root, ["init", "--initial-branch=base"])
    assert {_, 0} = git(root, ["config", "user.name", "Gettext merge test"])
    assert {_, 0} = git(root, ["config", "user.email", "gettext@example.com"])

    baseline = %Messages{headers: [""], messages: Enum.map(@baseline, &message/1)}
    write_catalog(root, "default.pot", baseline)
    write_catalog(root, "es.po", translate(baseline, @baseline))
    commit(root, "test: add baseline catalogs")

    assert {_, 0} = git(root, ["checkout", "-b", "license"])
    regenerate(root, @license, config)
    commit(root, "feat: add license label")

    assert {_, 0} = git(root, ["checkout", "-b", "preview", "base"])
    regenerate(root, @preview, config)
    commit(root, "feat: clarify output preview")

    git(root, ["merge", "--no-edit", "license"])
  end

  defp regenerate(root, addition, config) do
    old_template = PO.parse_file!(Path.join(root, "default.pot"))
    extracted = %Messages{messages: Enum.map(@baseline ++ [addition], &message/1)}
    template = Extractor.merge_template(old_template, extracted, config)
    write_catalog(root, "default.pot", template)

    old_locale = PO.parse_file!(Path.join(root, "es.po"))
    opts = [fuzzy: false, fuzzy_threshold: 0.8, on_obsolete: :delete]
    {locale, _stats} = Merger.merge(old_locale, template, "es", opts, config)
    write_catalog(root, "es.po", translate(locale, [addition]))
  end

  defp message(id) do
    %Singular{msgid: [id], msgstr: [""], flags: [["elixir-autogen", "elixir-format"]]}
  end

  defp translate(catalog, ids) do
    messages =
      Enum.map(catalog.messages, fn message ->
        id = IO.iodata_to_binary(message.msgid)
        if id in ids, do: %{message | msgstr: ["Traducción: #{id}"]}, else: message
      end)

    %{catalog | messages: messages}
  end

  defp message_ids(catalog), do: Enum.map(catalog.messages, &IO.iodata_to_binary(&1.msgid))

  defp translations(catalog) do
    Map.new(catalog.messages, fn message ->
      {IO.iodata_to_binary(message.msgid), IO.iodata_to_binary(message.msgstr)}
    end)
  end

  defp gettext_config, do: Keyword.fetch!(Mix.Project.config(), :gettext)

  defp write_catalog(root, path, catalog) do
    File.write!(Path.join(root, path), PO.compose(catalog))
  end

  defp commit(root, message) do
    assert {_, 0} = git(root, ["add", "default.pot", "es.po"])
    assert {_, 0} = git(root, ["commit", "-m", message])
  end

  defp git(root, args) do
    MuonTrap.cmd(
      "git",
      ["-C", root, "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null" | args],
      into: "",
      stderr_to_stdout: true,
      timeout: 10_000
    )
  end
end
