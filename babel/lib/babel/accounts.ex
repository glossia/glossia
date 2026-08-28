defmodule Babel.Accounts do
  @moduledoc """
  Accounts provisioned from Pomerium-authenticated Google Workspace identities.
  """

  alias Babel.Accounts.Account
  alias Babel.Repo

  def provision_pomerium_account(identity, email_domain) do
    with {:ok, identity} <- normalize_identity(identity, email_domain) do
      case find_account(identity) do
        {:ok, account} -> update_identity(account, identity)
        :not_found -> create_account(identity)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp normalize_identity(%{email: email, pomerium_id: pomerium_id} = identity, email_domain)
       when is_binary(email) and is_binary(pomerium_id) and is_binary(email_domain) do
    email = email |> String.trim() |> String.downcase()
    pomerium_id = String.trim(pomerium_id)

    if valid_email_domain?(email, email_domain) and pomerium_id != "" do
      {:ok,
       %{
         email: email,
         last_seen_at: DateTime.utc_now(:second),
         name: normalized_name(Map.get(identity, :name)),
         pomerium_id: pomerium_id
       }}
    else
      {:error, :invalid_identity}
    end
  end

  defp normalize_identity(_identity, _email_domain), do: {:error, :invalid_identity}

  defp valid_email_domain?(email, email_domain) do
    case String.split(email, "@", parts: 2) do
      [local_part, ^email_domain] when local_part != "" -> true
      _other -> false
    end
  end

  defp normalized_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> nil
      name -> name
    end
  end

  defp normalized_name(_name), do: nil

  defp find_account(%{email: email, pomerium_id: pomerium_id}) do
    case Repo.get_by(Account, pomerium_id: pomerium_id) do
      %Account{email: ^email} = account -> {:ok, account}
      %Account{} -> {:error, :identity_conflict}
      nil -> find_account_by_email(email, pomerium_id)
    end
  end

  defp find_account_by_email(email, pomerium_id) do
    case Repo.get_by(Account, email: email) do
      %Account{pomerium_id: ^pomerium_id} = account -> {:ok, account}
      %Account{} -> {:error, :identity_conflict}
      nil -> :not_found
    end
  end

  defp update_identity(account, identity) do
    account
    |> Account.identity_changeset(%{last_seen_at: identity.last_seen_at, name: identity.name})
    |> Repo.update()
  end

  defp create_account(identity) do
    case %Account{} |> Account.registration_changeset(identity) |> Repo.insert() do
      {:ok, account} -> {:ok, account}
      {:error, _changeset} -> resolve_concurrent_provisioning(identity)
    end
  end

  defp resolve_concurrent_provisioning(identity) do
    case find_account(identity) do
      {:ok, account} -> update_identity(account, identity)
      :not_found -> {:error, :provisioning_failed}
      {:error, reason} -> {:error, reason}
    end
  end
end
