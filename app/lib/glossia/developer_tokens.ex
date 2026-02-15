defmodule Glossia.DeveloperTokens do
  @moduledoc """
  Context for managing personal access tokens (PATs) and OAuth applications.
  """

  import Ecto.Query

  alias Glossia.Repo
  alias Glossia.Accounts.{Account, PersonalAccessToken, OAuthApplication, User}

  @token_prefix "glsa_"
  @token_random_bytes 20

  # --- Personal Access Tokens ---

  def list_personal_access_tokens(%Account{} = account, params \\ %{}) do
    query =
      from t in PersonalAccessToken,
        where: t.account_id == ^account.id and is_nil(t.revoked_at),
        preload: [:user]

    Flop.validate_and_run(query, params, for: PersonalAccessToken)
  end

  def get_personal_access_token!(id, account_id) do
    Repo.one!(
      from t in PersonalAccessToken,
        where: t.id == ^id and t.account_id == ^account_id,
        preload: [:user]
    )
  end

  def create_personal_access_token(%Account{} = account, %User{} = user, attrs) do
    plain_token = generate_token()
    token_hash = hash_token(plain_token)
    token_prefix = String.slice(plain_token, 0, 12)

    changeset =
      %PersonalAccessToken{}
      |> PersonalAccessToken.changeset(attrs)
      |> Ecto.Changeset.put_change(:token_hash, token_hash)
      |> Ecto.Changeset.put_change(:token_prefix, token_prefix)
      |> Ecto.Changeset.put_change(:account_id, account.id)
      |> Ecto.Changeset.put_change(:user_id, user.id)

    case Repo.insert(changeset) do
      {:ok, token} -> {:ok, %{token: token, plain_token: plain_token}}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update_personal_access_token(%PersonalAccessToken{} = token, attrs) do
    token
    |> PersonalAccessToken.changeset(attrs)
    |> Repo.update()
  end

  def revoke_personal_access_token(token_id, account_id) do
    case Repo.one(
           from t in PersonalAccessToken,
             where: t.id == ^token_id and t.account_id == ^account_id and is_nil(t.revoked_at)
         ) do
      nil ->
        {:error, :not_found}

      token ->
        token
        |> Ecto.Changeset.change(%{revoked_at: DateTime.utc_now()})
        |> Repo.update()
    end
  end

  def get_personal_access_token_by_value(value) do
    token_hash = hash_token(value)

    case Repo.one(
           from t in PersonalAccessToken,
             where: t.token_hash == ^token_hash and is_nil(t.revoked_at),
             preload: [:user]
         ) do
      nil ->
        {:error, :invalid}

      token ->
        if expired_pat?(token) do
          {:error, :expired}
        else
          update_last_used(token)
          {:ok, token}
        end
    end
  end

  defp expired_pat?(%PersonalAccessToken{expires_at: nil}), do: false

  defp expired_pat?(%PersonalAccessToken{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end

  defp update_last_used(token) do
    token
    |> Ecto.Changeset.change(%{last_used_at: DateTime.utc_now()})
    |> Repo.update()
  end

  defp generate_token do
    random = :crypto.strong_rand_bytes(@token_random_bytes) |> Base.encode16(case: :lower)
    @token_prefix <> random
  end

  defp hash_token(value) do
    :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  end

  # --- OAuth Applications ---

  def list_oauth_applications(%Account{} = account, params \\ %{}) do
    query =
      from a in OAuthApplication,
        where: a.account_id == ^account.id,
        preload: [:user]

    Flop.validate_and_run(query, params, for: OAuthApplication)
  end

  def get_oauth_application!(id, account_id) do
    Repo.one!(
      from a in OAuthApplication,
        where: a.id == ^id and a.account_id == ^account_id,
        preload: [:user]
    )
  end

  def create_oauth_application(%Account{} = account, %User{} = user, attrs) do
    redirect_uris = normalize_redirect_uris(attrs)

    client_attrs = %{
      name: attrs["name"] || attrs[:name],
      redirect_uris: redirect_uris,
      pkce: true,
      supported_grant_types: ["authorization_code"],
      authorize_scope: true
    }

    Ecto.Multi.new()
    |> Ecto.Multi.run(:boruta_client, fn _repo, _changes ->
      Boruta.Ecto.Admin.create_client(client_attrs)
    end)
    |> Ecto.Multi.run(:oauth_application, fn _repo, %{boruta_client: client} ->
      %OAuthApplication{}
      |> OAuthApplication.changeset(attrs)
      |> Ecto.Changeset.put_change(:boruta_client_id, client.id)
      |> Ecto.Changeset.put_change(:account_id, account.id)
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Repo.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{boruta_client: client, oauth_application: app}} ->
        {:ok, %{app: app, client_id: client.id, client_secret: client.secret}}

      {:error, _step, changeset, _changes} ->
        {:error, changeset}
    end
  end

  def update_oauth_application(%OAuthApplication{} = app, attrs) do
    redirect_uris = normalize_redirect_uris(attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:boruta_client, fn _repo, _changes ->
      client = Boruta.Ecto.Admin.get_client!(app.boruta_client_id)

      if redirect_uris != [] do
        Boruta.Ecto.Admin.update_client(client, %{redirect_uris: redirect_uris})
      else
        {:ok, client}
      end
    end)
    |> Ecto.Multi.run(:oauth_application, fn _repo, _changes ->
      app
      |> OAuthApplication.changeset(attrs)
      |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{oauth_application: app}} -> {:ok, app}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  def regenerate_oauth_application_secret(%OAuthApplication{} = app) do
    client = Boruta.Ecto.Admin.get_client!(app.boruta_client_id)

    case Boruta.Ecto.Admin.regenerate_client_secret(client) do
      {:ok, client} -> {:ok, %{app: app, client_secret: client.secret}}
      {:error, _} = error -> error
    end
  end

  def delete_oauth_application(%OAuthApplication{} = app) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:boruta_client, fn _repo, _changes ->
      client = Boruta.Ecto.Admin.get_client!(app.boruta_client_id)
      Boruta.Ecto.Admin.delete_client(client)
    end)
    |> Ecto.Multi.delete(:oauth_application, app)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> :ok
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  def get_boruta_client_for_app(%OAuthApplication{} = app) do
    Boruta.Ecto.Admin.get_client!(app.boruta_client_id)
  end

  defp normalize_redirect_uris(attrs) do
    uris = attrs["redirect_uris"] || attrs[:redirect_uris] || ""

    case uris do
      list when is_list(list) -> list
      str when is_binary(str) and str != "" -> String.split(str, ~r/[\s,]+/, trim: true)
      _ -> []
    end
  end
end
