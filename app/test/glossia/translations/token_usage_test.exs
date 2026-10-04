defmodule Glossia.Translations.TokenUsageTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts.Project
  alias Glossia.TestHelpers
  alias Glossia.Translations.TokenUsage

  setup do
    user = TestHelpers.create_user("token-ledger@test.com", "token-ledger")
    project = Repo.insert!(%Project{account_id: user.account.id, handle: "docs", name: "Docs"})
    %{account: user.account, project: project}
  end

  test "normalizes native and ReqLLM usage without double-counting cache" do
    assert TokenUsage.normalize(%{
             "prompt_tokens" => 100,
             "completion_tokens" => 20,
             "prompt_tokens_details" => %{"cached_tokens" => 30}
           }) == %{input_tokens: 100, output_tokens: 20, cached_tokens: 30}

    assert TokenUsage.normalize(%{
             input_tokens: 10,
             output_tokens: 20,
             cached_tokens: 30,
             cache_read_input_tokens: 30,
             cache_creation_input_tokens: 40
           }) == %{input_tokens: 80, output_tokens: 20, cached_tokens: 30}

    assert TokenUsage.normalize(%{
             "input_tokens" => 100,
             "output_tokens" => 20,
             "cached_input_tokens" => 30
           }) == %{input_tokens: 100, output_tokens: 20, cached_tokens: 30}

    assert TokenUsage.normalize(%{
             "prompt_tokens" => 100,
             "completion_tokens" => 10,
             "prompt_tokens_details" => %{"cached_tokens" => 60},
             "cache_read_input_tokens" => 60
           }) == %{input_tokens: 100, output_tokens: 10, cached_tokens: 60}

    assert TokenUsage.normalize(%{
             "input_tokens" => 100,
             "output_tokens" => 10,
             "input_tokens_details" => %{"cached_tokens" => 60},
             "cache_read_input_tokens" => 60
           }) == %{input_tokens: 100, output_tokens: 10, cached_tokens: 60}

    assert TokenUsage.normalize(%{
             "prompt_tokens" => 100,
             "completion_tokens" => 10,
             "prompt_tokens_details" => %{"cached_tokens" => 60},
             "cache_read_input_tokens" => 0
           }) == %{input_tokens: 100, output_tokens: 10, cached_tokens: 60}

    assert TokenUsage.normalize(%{input_tokens: 0, output_tokens: 0}) == nil
    assert TokenUsage.normalize(nil) == nil
    assert TokenUsage.normalize(%{}) == nil
    assert TokenUsage.normalize(%{input_tokens: -1, output_tokens: 20}) == nil
    assert TokenUsage.normalize(%{input_tokens: "100", output_tokens: 20}) == nil
  end

  test "invalid attribution becomes unassigned without losing counts", %{account: account} do
    for path <- [123, %{"bad" => "path"}, String.duplicate("a", 5000)] do
      :ok =
        TokenUsage.record(
          %{
            account_id: account.id,
            model: "openai/gpt-4o",
            source_path: path,
            locale: String.duplicate("a", 101)
          },
          %{input_tokens: 10, output_tokens: 5}
        )
    end

    for dimension <- ~w(projects languages files) do
      overview = TokenUsage.overview(account, %{"dimension" => dimension})
      assert overview.totals.calls == 3
      assert [%{label: "Unassigned", total_tokens: 45}] = overview.rows
    end
  end

  test "literal wildcard characters search file names rather than acting as SQL patterns", %{
    account: account,
    project: project
  } do
    for path <- ["c_d.md", "cad.md", "100%.md", "1000.md", "a\\\\b.md"] do
      add(account, project, path, "es", 10, 5)
    end

    assert [%{label: "c_d.md"}] =
             TokenUsage.overview(account, %{"dimension" => "files", "q" => "_"}).rows

    assert [%{label: "100%.md"}] =
             TokenUsage.overview(account, %{"dimension" => "files", "q" => "%"}).rows

    assert [%{label: "a\\\\b.md"}] =
             TokenUsage.overview(account, %{"dimension" => "files", "q" => "\\\\"}).rows
  end

  test "literal Unassigned paths do not merge into missing metadata", %{
    account: account,
    project: project
  } do
    add(account, project, "Unassigned", "Unassigned", 10, 5)
    add(account, project, nil, nil, 10, 5)
    assert length(TokenUsage.overview(account, %{"dimension" => "files"}).rows) == 2
    assert length(TokenUsage.overview(account, %{"dimension" => "languages"}).rows) == 2
  end

  test "every response, even identical retries, is a separate charge", %{
    account: account,
    project: project
  } do
    credential =
      TokenUsage.attach(%{model: "openai/gpt-4o", handle: "writer"}, account, %{
        "project_id" => project.id,
        "source_path" => "README.md",
        "locale" => "es"
      })

    credential.on_usage.(%{input_tokens: 100, output_tokens: 20})
    credential.on_usage.(%{input_tokens: 100, output_tokens: 20})
    credential.on_usage.(nil)
    overview = TokenUsage.overview(account)
    assert overview.totals == %{input_tokens: 200, output_tokens: 40, cached_tokens: 0, calls: 2}
    assert [%{label: "docs", calls: 2, total_tokens: 240}] = overview.rows
  end

  test "dimensions reconcile and files stay separate across projects", %{
    account: account,
    project: project
  } do
    other = Repo.insert!(%Project{account_id: account.id, handle: "website", name: "Website"})
    add(account, project, "README.md", "es", 100, 20)
    add(account, project, "README.md", "ja", 80, 40)
    add(account, other, "README.md", "es", 50, 10)
    add(account, nil, nil, "de", 10, 5)

    for dimension <- ~w(projects languages files) do
      overview = TokenUsage.overview(account, %{"dimension" => dimension})
      assert overview.totals.input_tokens == 240
      assert overview.totals.output_tokens == 75
      assert Enum.sum(Enum.map(overview.rows, & &1.total_tokens)) == 315
      assert Enum.sum(Enum.map(overview.daily, &(&1.input_tokens + &1.output_tokens))) == 315
    end

    assert [
             %{label: "README.md", project: "docs", total_tokens: 240},
             %{label: "README.md", project: "website", total_tokens: 60},
             %{label: "Unassigned", total_tokens: 15}
           ] = TokenUsage.overview(account, %{"dimension" => "files"}).rows
  end

  test "filters scope totals, daily chart, and breakdown together", %{
    account: account,
    project: project
  } do
    add(account, project, "a.md", "es", 100, 20)
    add(account, project, "b.md", "ja", 80, 40)

    filters = [
      %{field: :locale, operator: :==, value: "es"},
      %{field: :project_id, operator: :==, value: project.id}
    ]

    overview = TokenUsage.overview(account, %{"dimension" => "files"}, filters)
    assert overview.totals.input_tokens == 100
    assert [%{label: "a.md"}] = overview.rows
    assert Enum.sum(Enum.map(overview.daily, & &1.input_tokens)) == 100

    assert TokenUsage.overview(account, %{}, [
             %{field: :project_id, operator: :==, value: "invalid"}
           ]).totals.calls == 0
  end

  test "never attributes another account's project or exposes another account's usage", %{
    account: account,
    project: project
  } do
    other = TestHelpers.create_user("other-ledger@test.com", "other-ledger")
    add(other.account, project, "secret.md", "es", 999, 999)
    assert TokenUsage.overview(account).totals.calls == 0
    assert [%{label: "Unassigned"}] = TokenUsage.overview(other.account).rows
    assert TokenUsage.filter_values(account).models == []
  end

  test "time range, sorting, search, and hostile URL defaults", %{
    account: account,
    project: project
  } do
    add(account, project, "z.md", "es", 100, 20)
    add(account, project, "a.md", "ja", 80, 40)

    yesterday =
      DateTime.utc_now() |> DateTime.add(-10 * 86400, :second) |> DateTime.truncate(:microsecond)

    :ok =
      TokenUsage.record(
        %{
          account_id: account.id,
          project_id: project.id,
          model: "openai/gpt-4o",
          inserted_at: yesterday
        },
        %{input_tokens: 50, output_tokens: 20}
      )

    assert TokenUsage.overview(account, %{"days" => "7"}).totals.calls == 2
    assert TokenUsage.overview(account).totals.calls == 3

    overview =
      TokenUsage.overview(account, %{
        "dimension" => "files",
        "sort" => "label",
        "dir" => "asc",
        "q" => "a.md"
      })

    assert [%{label: "a.md"}] = overview.rows
    # Search is deliberately breakdown-only.
    assert overview.totals.calls == 3

    defaults =
      TokenUsage.overview(account, %{
        "dimension" => "malicious",
        "sort" => "new_atom",
        "page" => "-10",
        "days" => "forever"
      })

    assert defaults.dimension == "projects"
    assert defaults.sort == "total_tokens"
    assert defaults.page == 1
    assert defaults.days == 30
  end

  test "breakdown is paginated in the database", %{account: account, project: project} do
    for index <- 1..51, do: add(account, project, "#{index}.md", "es", 1, 1)
    overview = TokenUsage.overview(account, %{"dimension" => "files"})
    assert length(overview.rows) == 50
    assert overview.total_rows == 51
    assert overview.totals.calls == 51
    second = TokenUsage.overview(account, %{"dimension" => "files", "page" => "2"})
    assert length(second.rows) == 1
    assert second.page == 2
  end

  defp add(account, project, path, locale, input, output) do
    :ok =
      TokenUsage.record(
        %{
          account_id: account.id,
          project_id: project && project.id,
          model: "openai/gpt-4o",
          source_path: path,
          locale: locale
        },
        %{input_tokens: input, output_tokens: output}
      )
  end
end
