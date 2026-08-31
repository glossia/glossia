defmodule Glossia.TemporaryAccess do
  @moduledoc false

  import Ecto.Query

  alias Glossia.Accounts.{Account, Organization, User}
  alias Glossia.Repo
  alias Glossia.TemporaryAccess.Grant

  @durations [15, 30, 60, 240]

  def grant(
        %Organization{account_id: account_id},
        %User{id: recipient_user_id, email: recipient_email},
        attrs
      )
      when is_binary(recipient_email) do
    duration_minutes = attrs["duration_minutes"] || attrs[:duration_minutes]

    with {:ok, duration_minutes} <- duration_minutes(duration_minutes),
         expires_at <- DateTime.add(DateTime.utc_now(), duration_minutes * 60, :second),
         {:ok, grant} <-
           %Grant{account_id: account_id, recipient_user_id: recipient_user_id}
           |> Grant.changeset(
             attrs
             |> Map.put("recipient_email", recipient_email)
             |> Map.put("expires_at", expires_at)
           )
           |> Repo.insert() do
      {:ok, grant}
    end
  end

  def grant(_organization, _recipient, _attrs), do: {:error, :invalid_grant}

  def active?(%User{id: user_id, temporary_access_grant_id: grant_id}, %Account{id: account_id})
      when is_binary(grant_id) and grant_id != "" do
    active_grant_query(user_id, account_id)
    |> where([grant], grant.id == ^grant_id)
    |> Repo.exists?()
  end

  def active?(_user, _account), do: false

  def active_account_ids_query(%User{id: user_id, temporary_access_grant_id: grant_id})
      when is_binary(grant_id) and grant_id != "" do
    active_grant_query(user_id)
    |> where([grant], grant.id == ^grant_id)
    |> select([grant], grant.account_id)
  end

  def active_account_ids_query(_user), do: nil

  def authorize_pomerium_access(
        %User{id: user_id, email: user_email},
        %Account{id: account_id},
        %{email: email, subject: subject}
      )
      when is_binary(user_email) and is_binary(email) and is_binary(subject) and subject != "" do
    if String.downcase(user_email) == String.downcase(email) do
      case bound_grant(user_id, account_id, subject) do
        %Grant{} = grant -> {:ok, grant}
        nil -> bind_unclaimed_grant(user_id, account_id, subject)
      end
    else
      {:error, :identity_mismatch}
    end
  end

  def authorize_pomerium_access(_user, _account, _identity), do: {:error, :invalid_identity}

  def attach_pomerium_access(
        %User{id: user_id} = user,
        %{"user_id" => session_user_id, "grant_id" => grant_id}
      )
      when is_binary(grant_id) and grant_id != "" do
    if user_id == session_user_id do
      %{user | temporary_access_grant_id: grant_id}
    else
      user
    end
  end

  def attach_pomerium_access(user, _access), do: user

  defp duration_minutes(duration) when is_integer(duration) and duration in @durations,
    do: {:ok, duration}

  defp duration_minutes(duration) when is_binary(duration) do
    case Integer.parse(duration) do
      {duration, ""} when duration in @durations -> {:ok, duration}
      _ -> {:error, :invalid_duration}
    end
  end

  defp duration_minutes(_duration), do: {:error, :invalid_duration}

  defp bound_grant(user_id, account_id, subject) do
    active_grant_query(user_id, account_id)
    |> where([grant], grant.pomerium_subject == ^subject)
    |> order_by([grant], desc: grant.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp bind_unclaimed_grant(user_id, account_id, subject) do
    unclaimed_grant_id =
      active_grant_query(user_id, account_id)
      |> where([grant], is_nil(grant.pomerium_subject))
      |> order_by([grant], desc: grant.inserted_at)
      |> limit(1)
      |> select([grant], grant.id)
      |> Repo.one()

    count =
      case unclaimed_grant_id do
        nil ->
          0

        grant_id ->
          {count, _} =
            Grant
            |> where([grant], grant.id == ^grant_id and is_nil(grant.pomerium_subject))
            |> Repo.update_all(set: [pomerium_subject: subject, updated_at: DateTime.utc_now()])

          count
      end

    if count == 1 do
      case bound_grant(user_id, account_id, subject) do
        %Grant{} = grant -> {:ok, grant}
        nil -> {:error, :grant_not_found}
      end
    else
      {:error, :grant_not_found}
    end
  end

  defp active_grant_query(user_id, account_id \\ nil) do
    now = DateTime.utc_now()

    Grant
    |> where([grant], grant.recipient_user_id == ^user_id and grant.expires_at > ^now)
    |> where([grant], is_nil(grant.revoked_at))
    |> maybe_for_account(account_id)
  end

  defp maybe_for_account(query, account_id) when is_binary(account_id),
    do: where(query, [grant], grant.account_id == ^account_id)

  defp maybe_for_account(query, _account_id), do: query
end
