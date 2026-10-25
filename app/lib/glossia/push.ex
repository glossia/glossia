defmodule Glossia.Push do
  @moduledoc """
  Opt-in native push. Product code calls `notify_user(user_id, kind, source)`
  after committing its source. Jobs contain IDs, never tokens or message text.
  Registration IDs are client-generated installation UUIDs and are never reused.
  """
  import Ecto.Query
  alias Glossia.Accounts.User
  alias Glossia.Push.{Config, Deliver, Grants, Installation, Source}
  alias Glossia.Repo

  @kinds %{"toki_completed" => 3600, "linguistic_input_needed" => 3600}
  @ios_token ~r/\A(?:[0-9a-fA-F]{2}){16,256}\z/
  @android_token ~r/\A[\x21-\x7E]{16,4096}\z/

  def capabilities, do: Config.capabilities()

  def register(%User{} = user, client_id, id, params) do
    with {:ok, id} <- Ecto.UUID.cast(id),
         {:ok, client_id} <- Ecto.UUID.cast(client_id),
         {:ok, attrs} <- device(params),
         true <- Grants.native_client?(Repo.get(Boruta.Ecto.Client, client_id, log: false)),
         true <- Grants.active?(user.id, client_id),
         true <- Config.available?(attrs.platform, attrs.environment) do
      locked(fn -> upsert(Repo.get(Installation, id), user, client_id, id, attrs) end)
    else
      false -> {:error, :unavailable}
      _ -> {:error, :invalid}
    end
  end

  def unregister(%User{} = user, client_id, id) do
    with {:ok, id} <- Ecto.UUID.cast(id),
         {:ok, client_id} <- Ecto.UUID.cast(client_id),
         true <- Grants.native_client?(Repo.get(Boruta.Ecto.Client, client_id, log: false)),
         true <- Grants.active?(user.id, client_id) do
      locked(fn ->
        case Repo.get(Installation, id) do
          nil ->
            Repo.insert!(%Installation{
              id: id,
              oauth_client_id: client_id,
              retired_at: DateTime.utc_now()
            })

          installation ->
            if installation.user_id == user.id or installation.oauth_client_id == client_id,
              do: retire(installation)
        end

        :ok
      end)
    else
      _ -> {:error, :invalid}
    end
  end

  def notify_user(user_id, kind, source) when kind in [:toki_completed, :linguistic_input_needed],
    do: notify_user(user_id, Atom.to_string(kind), source)

  def notify_user(user_id, kind, source) do
    with {:ok, user_id} <- Ecto.UUID.cast(user_id),
         {:ok, ttl} <- Map.fetch(@kinds, kind),
         {:ok, source} <- Source.normalize(kind, source),
         %User{} = user <- Repo.get(User, user_id),
         {:ok, _} <- Source.destination(user, kind, source) do
      notification_id = Ecto.UUID.generate()
      expires_at = DateTime.add(DateTime.utc_now(), ttl) |> DateTime.to_iso8601()

      jobs =
        Installation
        |> where([i], i.user_id == ^user_id and is_nil(i.retired_at))
        |> order_by(desc: :last_registered_at)
        |> limit(10)
        |> Repo.all()
        |> Enum.filter(fn i ->
          Config.available?(i.platform, i.environment) and
            Grants.active?(user_id, i.oauth_client_id)
        end)
        |> Enum.map(fn i ->
          Deliver.new(%{
            registration_id: i.id,
            user_id: user_id,
            notification_id: notification_id,
            kind: kind,
            source: source,
            expires_at: expires_at
          })
        end)

      {:ok, length(Oban.insert_all(jobs))}
    else
      _ -> {:error, :invalid_notification}
    end
  end

  @doc false
  def delivery_context(args) do
    with {:ok, id} <- Ecto.UUID.cast(args["registration_id"]),
         {:ok, user_id} <- Ecto.UUID.cast(args["user_id"]),
         {:ok, _} <- Ecto.UUID.cast(args["notification_id"]),
         {:ok, ttl} <- Map.fetch(@kinds, args["kind"]),
         value when is_binary(value) <- args["expires_at"],
         {:ok, expires_at, 0} <- DateTime.from_iso8601(value),
         remaining when remaining > 0 and remaining <= ttl <-
           DateTime.diff(expires_at, DateTime.utc_now()),
         %Installation{user_id: ^user_id, retired_at: nil} = installation <-
           Repo.get(Installation, id),
         true <- fresh?(installation),
         true <- Config.available?(installation.platform, installation.environment),
         %User{} = user <- Repo.get(User, user_id),
         {:ok, source} <- Source.normalize(args["kind"], args["source"]),
         {:ok, destination} <- authorized_destination(user, installation, args["kind"], source) do
      {:ok, installation, destination, expires_at}
    else
      _ -> {:error, :notification_unavailable}
    end
  end

  defp authorized_destination(user, installation, kind, source) do
    installation.user_id
    |> Grants.scopes(installation.oauth_client_id)
    |> Enum.find_value({:error, :unauthorized}, fn scopes ->
      case Source.destination(user, kind, source, scopes: scopes) do
        {:ok, destination} -> {:ok, destination}
        _ -> nil
      end
    end)
  end

  @doc "Compare-and-retire: a rejection of an old token never retires its replacement."
  def retire_invalidated(installation, opts \\ []) do
    query =
      from i in Installation,
        where:
          i.id == ^installation.id and i.token_digest == ^installation.token_digest and
            i.last_registered_at == ^installation.last_registered_at and
            i.environment == ^installation.environment and is_nil(i.retired_at)

    query =
      case Keyword.get(opts, :unregistered_at) do
        %DateTime{} = at -> where(query, [i], i.last_registered_at < ^at)
        _ -> query
      end

    {count, _} = Repo.update_all(query, set: retired_fields())
    if count == 1, do: :retired, else: :kept
  end

  @doc "Retire stale or ended sessions. Tombstones are deliberately never pruned."
  def prune do
    Installation
    |> where([i], is_nil(i.retired_at))
    |> order_by(asc: :updated_at, asc: :id)
    |> limit(1000)
    |> Repo.all()
    |> Enum.each(fn i ->
      # Cycle through all live rows, not the same first batch forever. Fence a
      # concurrent foreground refresh even when its token did not change.
      query =
        where(Installation, [r], r.id == ^i.id and r.last_registered_at == ^i.last_registered_at)

      fields =
        if not fresh?(i) or is_nil(i.user_id) or not Grants.active?(i.user_id, i.oauth_client_id),
          do: retired_fields(),
          else: [updated_at: DateTime.utc_now()]

      Repo.update_all(query, set: fields)
    end)

    :ok
  end

  defp fresh?(i),
    do: DateTime.compare(i.last_registered_at, DateTime.add(DateTime.utc_now(), -60, :day)) == :gt

  # Registration-only writes are short and serialized, including first PUT vs
  # DELETE and token transfers. No network I/O runs inside this transaction.
  defp locked(fun) do
    case Repo.transaction(fn ->
           Repo.query!("SELECT pg_advisory_xact_lock(716294118)")
           fun.()
         end) do
      {:ok, result} -> result
      {:error, _} -> {:error, :conflict}
    end
  end

  defp upsert(%Installation{retired_at: at}, _, _, _, _) when not is_nil(at),
    do: {:error, :retired}

  defp upsert(%Installation{} = i, user, client_id, _id, attrs)
       when i.user_id != user.id or i.oauth_client_id != client_id do
    if i.oauth_client_id == client_id or
         i.token_digest == Installation.digest(attrs.platform, attrs.environment, attrs.token) do
      retire(i)
      {:error, :retired}
    else
      {:error, :conflict}
    end
  end

  defp upsert(%Installation{platform: platform}, _, _, _, %{platform: other})
       when platform != other,
       do: {:error, :conflict}

  defp upsert(existing, user, client_id, id, attrs) do
    digest = Installation.digest(attrs.platform, attrs.environment, attrs.token)

    Installation
    |> where([i], i.id != ^id and i.token_digest == ^digest and is_nil(i.retired_at))
    |> Repo.update_all(set: retired_fields())

    saved =
      (existing || %Installation{id: id})
      |> Ecto.Changeset.change(
        Map.merge(attrs, %{
          user_id: user.id,
          oauth_client_id: client_id,
          token_digest: digest,
          last_registered_at: DateTime.utc_now()
        })
      )
      |> Repo.insert_or_update!()

    keep =
      from i in Installation,
        where: i.user_id == ^user.id and is_nil(i.retired_at),
        order_by: [desc: i.last_registered_at, desc: i.id],
        limit: 10,
        select: i.id

    Installation
    |> where([i], i.user_id == ^user.id and is_nil(i.retired_at) and i.id not in subquery(keep))
    |> Repo.update_all(set: retired_fields())

    {:ok, saved}
  end

  defp retire(i) do
    Installation |> where(id: ^i.id) |> Repo.update_all(set: retired_fields())
  end

  defp retired_fields,
    do: [retired_at: DateTime.utc_now(), user_id: nil, token: nil, token_digest: nil]

  defp device(params) when is_map(params) do
    with ["environment", "platform", "token"] <- Enum.sort(Map.keys(params)),
         %{"platform" => platform, "token" => token, "environment" => environment} <- params,
         true <- is_binary(token),
         true <- valid_token?(platform, token),
         true <-
           {platform, environment} in [
             {"ios", "sandbox"},
             {"ios", "production"},
             {"android", "production"}
           ] do
      token = if platform == "ios", do: String.downcase(token), else: token
      {:ok, %{platform: platform, environment: environment, token: token}}
    else
      _ -> {:error, :invalid}
    end
  end

  defp device(_), do: {:error, :invalid}
  defp valid_token?("ios", token), do: Regex.match?(@ios_token, token)
  defp valid_token?("android", token), do: Regex.match?(@android_token, token)
  defp valid_token?(_, _), do: false
end
