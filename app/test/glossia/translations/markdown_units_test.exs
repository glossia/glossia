defmodule Glossia.Translations.MarkdownUnitsTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.MarkdownUnits

  # The constructs that broke Tuist's documentation when translated Markdown was
  # re-rendered: Phoenix components with prose attributes, inline components,
  # GitHub alerts, explicit heading anchors, and an HTML disclosure.
  @document """
  # Cache {#cache}

  Build artifacts are not shared across environments. Learn more in the <.localized_link href="/guides/cache">cache guide</.localized_link>.

  <.home_cards>
    <.home_card
      title="Module cache"
      details="Cache modules as binaries."
      link="/guides/features/cache/module-cache"
  />
  </.home_cards>

  > [!TIP]
  > **Fastest on Tuist Runners**
  >
  > Run `tuist cache` on [Tuist Runners](https://tuist.dev/runners "Runners")
  > to get warm hits out of the box.

  <details>
  <summary>Linux support</summary>

  On Linux, Tuist is available via Mise.

  </details>

  | Command | Purpose |
  | --- | --- |
  | `tuist cache` | Warms the cache |

  - First item with *emphasis*
    - Nested item with ![a diagram](diagram.png)
  1. Ordered item\\
     after a hard break

  ```bash
  tuist cache --print-hashes
  ```
  """

  defp plan!(source) do
    assert {:ok, plan} = MarkdownUnits.plan(source)
    plan
  end

  defp templates(plan), do: Enum.map(plan.units, & &1.template)

  defp render_all(plan, fun) do
    Map.new(plan.units, fn unit ->
      assert {:ok, bytes} = MarkdownUnits.render(unit, fun.(unit.template))
      {unit.id, bytes}
    end)
  end

  describe "plan/1" do
    test "finds whole blocks of prose with inline syntax replaced by tags" do
      assert templates(plan!(@document)) == [
               "Cache <g1/>",
               "Build artifacts are not shared across environments. Learn more in the <g1/>cache guide<g2/>.",
               "Module cache",
               "Cache modules as binaries.",
               "<g1>Fastest on Tuist Runners</g1>",
               "Run <g1/> on <g2>Tuist Runners</g2> to get warm hits out of the box.",
               "Linux support",
               "On Linux, Tuist is available via Mise.",
               "Command",
               "Purpose",
               "Warms the cache",
               "First item with <g1>emphasis</g1>",
               "Nested item with <g1>a diagram</g1>",
               "Ordered item<g1/>after a hard break"
             ]
    end

    test "preserves the order of text and code inside nested inline containers" do
      examples = [
        {"**Missing `source`.** Every term needs a non-empty one.\n",
         "<g1>Missing <g2/>.</g1> Every term needs a non-empty one."},
        {"**Duplicate `id`.** Every id must be unique.\n",
         "<g1>Duplicate <g2/>.</g1> Every id must be unique."},
        {"*Read **the `guide` now** please*.\n", "<g1>Read <g2>the <g3/> now</g2> please</g1>."},
        {"[Run `mix test` now](https://example.com \"Tests\").\n", "<g1>Run <g2/> now</g1>."}
      ]

      for {source, template} <- examples do
        plan = plan!(source)
        assert templates(plan) == [template]
        assert MarkdownUnits.splice(plan, render_all(plan, & &1)) == source

        # Exercise rendering rather than the unchanged-template fast path.
        rendered = render_all(plan, &String.replace(&1, ~w(Missing Duplicate Read Run), "ES"))
        assert MarkdownUnits.check(plan, rendered) == :ok

        assert MarkdownUnits.splice(plan, rendered) ==
                 String.replace(source, ~w(Missing Duplicate Read Run), "ES")
      end
    end

    test "skips blocks without prose" do
      assert templates(plan!("<g1/>\n\n`code`\n\n---\n\n12.5%\n")) == []
    end

    test "uses byte offsets for multibyte text" do
      plan = plan!("# Café {#cafe}\n\nNaïve résumé ☕ text.\n")

      rendered =
        render_all(plan, &String.replace(&1, ["Café", "Naïve", "résumé", "☕", "text"], "x"))

      assert MarkdownUnits.splice(plan, rendered) == "# x {#cafe}\n\nx x x x.\n"
    end
  end

  describe "splice/2" do
    test "reproduces the source byte for byte when nothing is translated" do
      plan = plan!(@document)
      assert MarkdownUnits.splice(plan, render_all(plan, & &1)) == @document
      assert MarkdownUnits.check(plan, render_all(plan, & &1)) == :ok
    end

    test "changes only prose and never escapes the surrounding syntax" do
      plan = plan!(@document)

      rendered =
        render_all(plan, fn
          "Module cache" ->
            "Caché de \"módulos\""

          "Run <g1/> on <g2>Tuist Runners</g2> to get warm hits out of the box." ->
            "En <g2>Tuist Runners</g2>, ejecuta <g1/> para obtener aciertos desde el inicio."

          template ->
            "ES " <> template
        end)

      output = MarkdownUnits.splice(plan, rendered)

      assert MarkdownUnits.check(plan, rendered) == :ok
      refute output =~ "\\<"
      refute output =~ "\\_"
      refute output =~ "\\["
      assert output =~ "# ES Cache {#cache}\n"
      assert output =~ ~s(<.localized_link href="/guides/cache">cache guide</.localized_link>.)
      assert output =~ ~s(title="Caché de &quot;módulos&quot;")
      assert output =~ ~s(link="/guides/features/cache/module-cache")
      assert output =~ "> [!TIP]\n> ES **Fastest on Tuist Runners**\n"

      # The model moved the link before the code span; the link keeps its
      # destination and title, the code keeps its bytes, and the soft break
      # inside the alert collapses into one line.
      assert output =~
               ~s(> En [Tuist Runners](https://tuist.dev/runners "Runners"\), ejecuta `tuist cache` para obtener aciertos desde el inicio.\n)

      assert output =~ "<summary>ES Linux support</summary>"
      assert output =~ "| `tuist cache` | ES Warms the cache |"
      assert output =~ "  - ES Nested item with ![a diagram](diagram.png)"
      assert output =~ "1. ES Ordered item\\\n   after a hard break"
      assert output =~ "```bash\ntuist cache --print-hashes\n```"
    end
  end

  describe "render/3" do
    setup do
      plan = plan!("Read the [guide](https://example.com) and run `mix test`.\n")
      %{plan: plan, unit: hd(plan.units)}
    end

    test "rejects a dropped, duplicated, unknown, or misnested tag", %{unit: unit} do
      assert {:error, message} = MarkdownUnits.render(unit, "Lee la guía y ejecuta.")
      assert message =~ "every tag must appear exactly once: <g1> </g1> <g2/>"

      assert {:error, _message} =
               MarkdownUnits.render(unit, "Lee la <g1>guía</g1> y <g2/> <g2/>.")

      assert {:error, "unknown tag; use only the tags present in the source text"} =
               MarkdownUnits.render(unit, "Lee la <g1>guía</g1> y <g2/> <g7/>.")

      assert {:error, "paired tags must open before they close and must not overlap"} =
               MarkdownUnits.render(unit, "Lee la </g1>guía<g1> y ejecuta <g2/>.")
    end

    test "keeps a translated block on one line", %{unit: unit} do
      assert {:ok, "Lee la [guía](https://example.com) y ejecuta `mix test`."} =
               MarkdownUnits.render(unit, "Lee la <g1>guía</g1>\ny ejecuta <g2/>.\n")
    end
  end

  describe "check/2" do
    test "catches a translation that introduces Markdown structure, which escaping fixes" do
      plan = plan!("Intro paragraph.\n\nThe end.\n")
      unit = hd(plan.units)

      for injected <- ["# Hola", "* Hola", "- Hola", "1. Hola", "Hola *mundo*", "> Hola"] do
        assert {:ok, rendered} = MarkdownUnits.render(unit, injected)
        assert {:error, _message} = MarkdownUnits.check(plan, %{unit.id => rendered})

        assert {:ok, escaped} = MarkdownUnits.render(unit, injected, escape: true)
        assert :ok = MarkdownUnits.check(plan, %{unit.id => escaped})
      end
    end

    test "names the units that change the structure on their own" do
      plan = plan!("One.\n\nTwo.\n")
      [first, second] = plan.units
      {:ok, safe} = MarkdownUnits.render(first, "Uno.")
      {:ok, unsafe} = MarkdownUnits.render(second, "# Dos")

      assert MarkdownUnits.structural_offenders(plan, %{first.id => safe, second.id => unsafe}) ==
               [second.id]
    end
  end

  describe "context/3" do
    test "returns short documents whole and clips long ones around the units" do
      plan = plan!(@document)
      assert MarkdownUnits.context(plan, plan.units) == @document

      long = String.duplicate("Filler paragraph.\n\n", 2_000) <> "Target paragraph.\n"
      plan = plan!(long)
      target = List.last(plan.units)
      context = MarkdownUnits.context(plan, [target], max_bytes: 1_000, margin_bytes: 100)

      assert context =~ "Target paragraph."
      assert byte_size(context) < 200
      assert String.starts_with?(context, "Filler") or String.starts_with?(context, "\n")
    end
  end
end
