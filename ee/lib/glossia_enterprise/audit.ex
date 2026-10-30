defmodule GlossiaEnterprise.Audit do
  @moduledoc """
  Persists domain events in PostgreSQL and exposes them to organization administrators.

  Writes participate in the caller's transaction. Product analytics remains a
  separate subscriber. There is no buffered, best-effort audit ingestion.
  """

  import Ecto.Query

  alias Glossia.Accounts.Account
  alias Glossia.{Organizations, Repo, Roles}
  alias GlossiaEnterprise.Audit.Event

  def children, do: []

  def migrations(Glossia.Repo), do: [{20_261_028_110_000, GlossiaEnterprise.Audit.Migration}]
  def migrations(_repo), do: []

  def handle_event(%{account: %{id: _}} = event) do
    accounts =
      if event.name in ~w(user.mfa_enabled user.mfa_disabled user.mfa_recovery_regenerated) do
        event.user |> Organizations.list_user_organizations() |> Enum.map(& &1.account)
      else
        []
      end

    [event.account | accounts]
    |> Enum.uniq_by(& &1.id)
    |> Enum.each(&insert_event(event, &1.id))

    :ok
  end

  def handle_event(_event), do: :ok

  defp insert_event(event, account_id) do
    Repo.insert!(%Event{
      name: event.name,
      account_id: account_id,
      user_id: event.user && event.user.id,
      actor_handle: event.user && Repo.preload(event.user, :account).account.handle,
      actor_email: event.user && Map.get(event.user, :email),
      resource_type: event.opts[:resource_type],
      resource_id: event.opts[:resource_id] && to_string(event.opts[:resource_id]),
      summary: event.opts[:summary],
      metadata: event.opts |> Keyword.take([:via]) |> Map.new(),
      occurred_at: event.occurred_at
    })
  end

  def authorized?(%{} = user, %Account{} = account) do
    organization = Organizations.get_organization_for_account(account)
    not is_nil(organization) and Roles.has_organization_role?(user, organization, "admin")
  end

  def authorized?(_, _), do: false

  def filter_values(account, actor) do
    authorize!(account, actor)

    Repo.all(
      from e in Event,
        where: e.account_id == ^account.id,
        distinct: true,
        order_by: e.name,
        select: e.name
    )
  end

  def list_events(account, actor, params \\ %{}, filters \\ []) do
    authorize!(account, actor)
    search = params |> Map.get("q", "") |> String.trim() |> String.slice(0, 200)

    sort =
      if params["sort"] in ~w(occurred_at name actor_handle),
        do: params["sort"],
        else: "occurred_at"

    direction = if params["dir"] == "asc", do: :asc, else: :desc

    page =
      case Integer.parse(params["page"] || "1") do
        {page, ""} when page > 0 -> min(page, 100_000)
        _ -> 1
      end

    query = from e in Event, where: e.account_id == ^account.id

    query =
      if search == "" do
        query
      else
        pattern = "%#{search}%"

        from e in query,
          where:
            ilike(e.summary, ^pattern) or ilike(e.name, ^pattern) or
              ilike(e.actor_email, ^pattern) or ilike(e.actor_handle, ^pattern)
      end

    query =
      Enum.reduce(filters, query, fn
        %{id: "event", operator: :==, value: value}, query
        when is_binary(value) and value != "" ->
          from e in query, where: e.name == ^value

        %{id: "event", operator: :!=, value: value}, query
        when is_binary(value) and value != "" ->
          from e in query, where: e.name != ^value

        _, query ->
          query
      end)

    total = Repo.aggregate(query, :count)
    page = min(page, max(ceil(total / 50), 1))

    rows =
      Repo.all(
        from e in query,
          order_by: [{^direction, field(e, ^String.to_existing_atom(sort))}, {^direction, e.id}],
          limit: 50,
          offset: ^((page - 1) * 50)
      )

    %{
      rows: rows,
      total: total,
      page: page,
      search: search,
      sort: sort,
      direction: to_string(direction)
    }
  end

  defp authorize!(account, actor) do
    unless authorized?(actor, account), do: raise(Ecto.NoResultsError, queryable: Event)
  end
end
