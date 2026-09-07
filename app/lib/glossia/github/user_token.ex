defmodule Glossia.Github.UserToken do
  @moduledoc false

  alias Glossia.Accounts.Identity
  alias Glossia.Github.Client
  alias Glossia.Repo

  import Ecto.Query

  def with_valid_token(user_id, operation) when is_function(operation, 1) do
    with %Identity{} = identity <- github_identity(user_id),
         token when is_binary(token) <- identity.provider_token do
      case operation.(token) do
        {:error, {:api_error, 401, _body}} ->
          with {:ok, refreshed_token} <- refresh(identity.id, token) do
            operation.(refreshed_token)
          end

        result ->
          result
      end
    else
      nil -> {:error, :github_identity_not_found}
      _ -> {:error, :github_access_token_not_found}
    end
  end

  defp github_identity(user_id) do
    Repo.one(
      from identity in Identity,
        where: identity.user_id == ^user_id and identity.provider == "github"
    )
  end

  defp refresh(identity_id, rejected_token) do
    Repo.transaction(fn ->
      identity =
        Repo.one!(
          from identity in Identity,
            where: identity.id == ^identity_id,
            lock: "FOR UPDATE"
        )

      if identity.provider_token != rejected_token do
        identity.provider_token
      else
        refresh_locked_identity(identity)
      end
    end)
    |> case do
      {:ok, token} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end

  defp refresh_locked_identity(%Identity{} = identity) do
    with refresh_token when is_binary(refresh_token) <- identity.provider_refresh_token,
         {:ok, {client_id, client_secret}} <- github_client_credentials(),
         {:ok, tokens} <-
           Client.refresh_user_access_token(refresh_token, client_id, client_secret),
         {:ok, identity} <- persist_tokens(identity, tokens) do
      identity.provider_token
    else
      nil -> Repo.rollback(:github_refresh_token_not_found)
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp github_client_credentials do
    config = Glossia.Auth.provider_config!(:github)
    client_id = config[:client_id]
    client_secret = config[:client_secret]

    if present?(client_id) and present?(client_secret) do
      {:ok, {client_id, client_secret}}
    else
      {:error, :github_oauth_not_configured}
    end
  rescue
    ArgumentError -> {:error, :github_oauth_not_configured}
  end

  defp persist_tokens(identity, tokens) do
    refresh_token = tokens.refresh_token || identity.provider_refresh_token

    identity
    |> Identity.changeset(%{
      provider_token: tokens.access_token,
      provider_refresh_token: refresh_token
    })
    |> Repo.update()
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_), do: false
end
