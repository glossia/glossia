defmodule Glossia.Translations.TokenUsage do
  @moduledoc """
  An immutable ledger of provider-reported generative translation usage.

  Each response is recorded, including responses rejected by validation or the
  output limit. Missing usage is not estimated. Input includes cache reads and
  cache writes; cached tokens are a subset, never added to the total again.
  Source paths refer to source files, so all target locales reconcile to the
  same file. Project-less API requests remain visible as unassigned usage.
  """
  use Glossia.Schema

  import Ecto.Query
  import Ecto.Changeset

  require Logger

  alias Glossia.Accounts.Project
  alias Glossia.Repo
  alias Glossia.Translations.TokenUsage

  schema "translation_token_usage" do
    field :account_id, Uniq.UUID
    field :project_id, Uniq.UUID
    field :model, :string
    field :model_handle, :string
    field :locale, :string
    field :source_path, :string
    field :input_tokens, :integer
    field :output_tokens, :integer
    field :cached_tokens, :integer, default: 0
    timestamps(updated_at: false)
  end

  def normalize(usage) when is_map(usage) do
    input = value(usage, :input_tokens) || value(usage, :prompt_tokens)
    output = value(usage, :output_tokens) || value(usage, :completion_tokens)

    if valid_count?(input) and valid_count?(output) do
      # Anthropic excludes cache reads/writes from input. OpenAI-compatible
      # gateways can include both shapes, so OpenAI token details take priority.
      read = value(usage, :cache_read_input_tokens)
      write = value(usage, :cache_creation_input_tokens)
      details = details_cached(usage)
      includes_cache = not is_nil(value(usage, :prompt_tokens)) or not is_nil(details)
      input = if includes_cache, do: input, else: input + count(read) + count(write)

      cached =
        count(
          details || read || value(usage, :cached_tokens) || value(usage, :cached_input_tokens)
        )

      # ReqLLM's missing-usage fallbacks are zeroed maps. They must not inflate
      # the response count or masquerade as provider-reported usage.
      if input + output > 0 do
        %{input_tokens: input, output_tokens: output, cached_tokens: min(cached, input)}
      end
    end
  end

  def normalize(_usage), do: nil

  defp value(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))
  defp valid_count?(count), do: is_integer(count) and count >= 0
  defp count(count), do: if(valid_count?(count), do: count, else: 0)

  defp details_cached(usage) do
    Enum.find_value([:prompt_tokens_details, :input_tokens_details], fn key ->
      details = value(usage, key)
      if is_map(details), do: value(details, :cached_tokens)
    end)
  end

  @doc "Attaches a recorder without changing the LLM's text return contract."
  def attach(credential, account, payload, opts \\ []) do
    attrs = %{
      account_id: account.id,
      project_id: payload["project_id"],
      model: credential.model,
      model_handle: Map.get(credential, :handle),
      locale: payload["locale"],
      source_path: payload["source_path"]
    }

    target = Keyword.get(opts, :credential_node, node())

    Map.put(credential, :on_usage, fn usage ->
      if target == node() do
        record(attrs, usage)
      else
        try do
          :erpc.call(target, __MODULE__, :record, [attrs, usage], 5_000)
        catch
          kind, _reason -> Logger.warning("Token usage relay failed (#{kind})")
        end
      end
    end)
  end

  @doc "Persists normalized usage; accounting failures never fail a translation."
  def record(attrs, usage) do
    case normalize(usage) do
      nil ->
        :ok

      counts ->
        attrs =
          attrs
          |> Map.merge(counts)
          |> Map.update(:source_path, nil, &metadata(&1, 4_096))
          |> Map.update(:locale, nil, &metadata(&1, 100))

        project_id = Map.get(attrs, :project_id)

        # API clients may supply a project ID. Never trust it to belong to the
        # account, even when the FK happens to exist.
        project_id =
          with {:ok, id} <- Ecto.UUID.cast(project_id),
               true <-
                 Repo.exists?(
                   from p in Project, where: p.id == ^id and p.account_id == ^attrs.account_id
                 ) do
            id
          else
            _ -> nil
          end

        %TokenUsage{}
        |> cast(Map.put(attrs, :project_id, project_id), [
          :account_id,
          :project_id,
          :model,
          :model_handle,
          :locale,
          :source_path,
          :input_tokens,
          :output_tokens,
          :cached_tokens,
          :inserted_at
        ])
        |> validate_required([:account_id, :model, :input_tokens, :output_tokens])
        |> validate_length(:source_path, max: 4_096)
        |> validate_length(:locale, max: 100)
        |> foreign_key_constraint(:project_id)
        |> Repo.insert()
        |> case do
          {:ok, _entry} -> :ok
          {:error, _changeset} -> Logger.warning("Token usage could not be recorded")
        end
    end
  rescue
    _error -> Logger.warning("Token usage storage failed")
  end

  defp metadata(value, limit) when is_binary(value) do
    if String.valid?(value) and String.length(value) in 1..limit, do: value
  end

  defp metadata(_value, _limit), do: nil

  @doc """
  Usage recorded for `project_id` since `since`, totalled per model.

  Returns a list of `%{model, responses, input_tokens, output_tokens,
  cached_tokens}` ordered by output tokens, largest first.
  """
  def project_totals(project_id, %DateTime{} = since) do
    Repo.all(
      from u in TokenUsage,
        where: u.project_id == ^project_id and u.inserted_at >= ^since,
        group_by: u.model,
        order_by: [desc: sum(u.output_tokens)],
        select: %{
          model: u.model,
          responses: count(u.id),
          input_tokens: coalesce(sum(u.input_tokens), 0),
          output_tokens: coalesce(sum(u.output_tokens), 0),
          cached_tokens: coalesce(sum(u.cached_tokens), 0)
        }
    )
  end

  @doc "Aggregates one account's ledger with a common scope for totals and daily usage."
  def overview(account, params \\ %{}, filters \\ []) do
    dimension =
      if params["dimension"] in ~w(projects languages files),
        do: params["dimension"],
        else: "projects"

    days =
      case params["days"] do
        "7" -> 7
        "90" -> 90
        _ -> 30
      end

    first = Date.add(Date.utc_today(), 1 - days)
    since = DateTime.new!(first, ~T[00:00:00], "Etc/UTC")
    until = DateTime.new!(Date.add(Date.utc_today(), 1), ~T[00:00:00], "Etc/UTC")

    query =
      from u in TokenUsage,
        left_join: p in Project,
        on: p.id == u.project_id and p.account_id == u.account_id,
        where: u.account_id == ^account.id and u.inserted_at >= ^since and u.inserted_at < ^until

    query = Enum.reduce(filters, query, &apply_filter/2)

    totals =
      Repo.one(
        from [u, _p] in query,
          select: %{
            input_tokens: coalesce(sum(u.input_tokens), 0),
            output_tokens: coalesce(sum(u.output_tokens), 0),
            cached_tokens: coalesce(sum(u.cached_tokens), 0),
            calls: count(u.id)
          }
      )

    totals = integer_counts(totals)

    daily =
      Repo.all(
        from [u, _p] in query,
          group_by: fragment("?::date", u.inserted_at),
          select: %{
            date: fragment("?::date", u.inserted_at),
            input_tokens: sum(u.input_tokens),
            output_tokens: sum(u.output_tokens)
          }
      )
      |> Map.new(&{&1.date, integer_counts(&1)})

    group_label =
      case dimension do
        "languages" -> dynamic([u, _p], u.locale)
        "files" -> dynamic([u, _p], u.source_path)
        _ -> dynamic([_u, p], p.handle)
      end

    label = dynamic(coalesce(^group_label, "Unassigned"))

    # Files are keyed by project as well as path: README.md in two repositories
    # is two files, not one. Languages intentionally aggregate across projects.
    project =
      if dimension == "files",
        do: dynamic([_u, p], coalesce(p.handle, "Unassigned")),
        else: dynamic(" ")

    selection = %{
      label: label,
      project: project,
      input_tokens: dynamic([u], sum(u.input_tokens)),
      output_tokens: dynamic([u], sum(u.output_tokens)),
      cached_tokens: dynamic([u], sum(u.cached_tokens)),
      total_tokens: dynamic([u], sum(u.input_tokens + u.output_tokens)),
      calls: dynamic([u], count(u.id))
    }

    groups =
      if dimension == "files", do: [group_label, dynamic([_u, p], p.handle)], else: [group_label]

    grouped = from query, group_by: ^groups, select: ^selection

    search = String.slice(params["q"] || "", 0, 200)
    grouped = from(g in subquery(grouped))

    grouped =
      if search == "",
        do: grouped,
        else:
          from(g in grouped,
            where:
              ilike(g.label, ^search_pattern(search)) or ilike(g.project, ^search_pattern(search))
          )

    sort =
      if params["sort"] in ~w(label input_tokens output_tokens cached_tokens total_tokens calls),
        do: params["sort"],
        else: "total_tokens"

    direction = if params["dir"] == "asc", do: :asc, else: :desc
    sort_field = String.to_existing_atom(sort)
    total_rows = Repo.aggregate(grouped, :count)

    page =
      case Integer.parse(params["page"] || "1") do
        {n, ""} when n > 0 -> min(n, max(ceil(total_rows / 50), 1))
        _ -> 1
      end

    rows =
      Repo.all(
        from g in grouped,
          order_by: [{^direction, field(g, ^sort_field)}, asc: g.label, asc: g.project],
          limit: 50,
          offset: ^((page - 1) * 50)
      )

    %{
      totals: totals,
      rows: Enum.map(rows, &integer_counts/1),
      dimension: dimension,
      days: days,
      search: search,
      sort: sort,
      direction: Atom.to_string(direction),
      page: page,
      total_rows: total_rows,
      daily:
        Enum.map(Date.range(first, Date.utc_today()), fn date ->
          Map.get(daily, date, %{date: date, input_tokens: 0, output_tokens: 0})
        end)
    }
  end

  defp search_pattern(search) do
    escaped = String.replace(search, ["\\", "%", "_"], fn char -> "\\" <> char end)
    "%#{escaped}%"
  end

  defp integer_counts(map) do
    Map.new(map, fn
      {key, %Decimal{} = count} -> {key, Decimal.to_integer(count)}
      pair -> pair
    end)
  end

  defp apply_filter(%{field: field, operator: op, value: value}, query)
       when field in [:model, :locale, :project_id] and op in [:==, :!=] and is_binary(value) and
              value != "" do
    value = if field == :project_id, do: valid_uuid(value), else: value

    if is_nil(value) do
      where(query, false)
    else
      if op == :==,
        do: where(query, [u], field(u, ^field) == ^value),
        else: where(query, [u], field(u, ^field) != ^value or is_nil(field(u, ^field)))
    end
  end

  defp apply_filter(_filter, query), do: query

  defp valid_uuid(value) do
    case Ecto.UUID.cast(value) do
      {:ok, id} -> id
      _ -> nil
    end
  end

  @doc "Distinct, account-scoped values for the filter dropdown."
  def filter_values(account) do
    models =
      Repo.all(
        from u in TokenUsage,
          where: u.account_id == ^account.id,
          distinct: true,
          select: u.model,
          order_by: u.model
      )

    locales =
      Repo.all(
        from u in TokenUsage,
          where: u.account_id == ^account.id and not is_nil(u.locale),
          distinct: true,
          select: u.locale,
          order_by: u.locale
      )

    projects =
      Repo.all(
        from p in Project,
          where: p.account_id == ^account.id,
          select: {p.id, p.handle},
          order_by: p.handle
      )

    %{models: models, locales: locales, projects: projects}
  end
end
