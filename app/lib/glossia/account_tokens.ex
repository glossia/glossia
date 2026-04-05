defmodule Glossia.AccountTokens do
  @moduledoc """
  Context for managing account tokens and OAuth applications.
  """

  require OpenTelemetry.Tracer, as: Tracer

  import Ecto.Query

  alias Glossia.Events
  alias Glossia.Repo
  alias Glossia.Accounts.{Account, AccountToken, OAuthApplication, User}

  @token_prefix "glsa_"
  @token_random_bytes 20

  # --- Account Tokens ---

  def list_account_tokens(%Account{} = account, params \\ %{}) do
    query =
      from t in AccountToken,
        where: t.account_id == ^account.id and is_nil(t.revoked_at),
        preload: [:user]

    Flop.validate_and_run(query, params, for: AccountToken)
  end

  def get_account_token!(id, account_id) do
    Repo.one!(
      from t in AccountToken,
        where: t.id == ^id and t.account_id == ^account_id,
        preload: [:user]
    )
  end

  def create_account_token(%Account{} = account, %User{} = user, attrs, opts \\ []) do
    Tracer.with_span "glossia.developer_tokens.create_account_token" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.user.id", to_string(user.id)}
      ])

      plain_token = generate_token()
      token_hash = hash_token(plain_token)
      token_prefix = String.slice(plain_token, 0, 12)

      changeset =
        %AccountToken{}
        |> AccountToken.changeset(attrs)
        |> Ecto.Changeset.put_change(:token_hash, token_hash)
        |> Ecto.Changeset.put_change(:token_prefix, token_prefix)
        |> Ecto.Changeset.put_change(:account_id, account.id)
        |> Ecto.Changeset.put_change(:user_id, user.id)

      case Repo.insert(changeset) do
        {:ok, token} ->
          Tracer.set_attributes([{"glossia.account_token.id", to_string(token.id)}])

          Events.emit("token.created", account, user,
            resource_type: "account_token",
            resource_id: to_string(token.id),
            resource_path: "/#{account.handle}/-/settings/tokens",
            summary: "Created account token \"#{token.name}\"",
            via: Keyword.get(opts, :via)
          )

          {:ok, %{token: token, plain_token: plain_token}}

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  def update_account_token(%AccountToken{} = token, attrs, opts \\ []) do
    Tracer.with_span "glossia.developer_tokens.update_account_token" do
      Tracer.set_attributes([{"glossia.account_token.id", to_string(token.id)}])

      token
      |> AccountToken.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, updated_token} = ok ->
          if actor = Keyword.get(opts, :actor) do
            account = Repo.preload(updated_token, :account).account

            Events.emit("token.updated", account, actor,
              resource_type: "account_token",
              resource_id: to_string(updated_token.id),
              resource_path: "/#{account.handle}/-/settings/tokens/#{updated_token.id}",
              summary: "Updated account token \"#{updated_token.name}\"",
              via: Keyword.get(opts, :via)
            )
          end

          ok

        other ->
          other
      end
    end
  end

  def revoke_account_token(token_id, account_id, opts \\ []) do
    Tracer.with_span "glossia.developer_tokens.revoke_account_token" do
      Tracer.set_attributes([
        {"glossia.account_token.id", to_string(token_id)},
        {"glossia.account.id", to_string(account_id)}
      ])

      case Repo.one(
             from t in AccountToken,
               where: t.id == ^token_id and t.account_id == ^account_id and is_nil(t.revoked_at)
           ) do
        nil ->
          {:error, :not_found}

        token ->
          token
          |> Ecto.Changeset.change(%{revoked_at: DateTime.utc_now()})
          |> Repo.update()
          |> case do
            {:ok, revoked} = ok ->
              if actor = Keyword.get(opts, :actor) do
                account = Repo.preload(revoked, :account).account

                Events.emit("token.revoked", account, actor,
                  resource_type: "account_token",
                  resource_id: to_string(revoked.id),
                  resource_path: "/#{account.handle}/-/settings/tokens",
                  summary: "Revoked account token \"#{revoked.name}\"",
                  via: Keyword.get(opts, :via)
                )
              end

              ok

            other ->
              other
          end
      end
    end
  end

  def get_account_token_by_value(value) do
    Tracer.with_span "glossia.developer_tokens.get_account_token_by_value" do
      token_hash = hash_token(value)

      case Repo.one(
             from t in AccountToken,
               where: t.token_hash == ^token_hash and is_nil(t.revoked_at),
               preload: [user: :account]
           ) do
        nil ->
          {:error, :invalid}

        token ->
          Tracer.set_attributes([
            {"glossia.account_token.id", to_string(token.id)},
            {"glossia.account.id", to_string(token.account_id)}
          ])

          if expired_account_token?(token) do
            {:error, :expired}
          else
            update_last_used(token)
            {:ok, token}
          end
      end
    end
  end

  defp expired_account_token?(%AccountToken{expires_at: nil}), do: false

  defp expired_account_token?(%AccountToken{expires_at: expires_at}) do
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

  def create_oauth_application(%Account{} = account, %User{} = user, attrs, opts \\ []) do
    Tracer.with_span "glossia.developer_tokens.create_oauth_application" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.user.id", to_string(user.id)}
      ])

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
          Tracer.set_attributes([{"glossia.oauth_application.id", to_string(app.id)}])

          Events.emit("oauth_app.created", account, user,
            resource_type: "oauth_application",
            resource_id: to_string(app.id),
            resource_path: "/#{account.handle}/-/settings/apps/#{app.id}",
            summary: "Created OAuth application \"#{app.name}\"",
            via: Keyword.get(opts, :via)
          )

          {:ok, %{app: app, client_id: client.id, client_secret: client.secret}}

        {:error, _step, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

  def update_oauth_application(%OAuthApplication{} = app, attrs, opts \\ []) do
    Tracer.with_span "glossia.developer_tokens.update_oauth_application" do
      Tracer.set_attributes([{"glossia.oauth_application.id", to_string(app.id)}])

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
        {:ok, %{oauth_application: app}} ->
          if actor = Keyword.get(opts, :actor) do
            account = Repo.preload(app, :account).account

            Events.emit("oauth_app.updated", account, actor,
              resource_type: "oauth_application",
              resource_id: to_string(app.id),
              resource_path: "/#{account.handle}/-/settings/apps/#{app.id}",
              summary: "Updated OAuth application \"#{app.name}\"",
              via: Keyword.get(opts, :via)
            )
          end

          {:ok, app}

        {:error, _step, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

  def regenerate_oauth_application_secret(%OAuthApplication{} = app, opts \\ []) do
    Tracer.with_span "glossia.developer_tokens.regenerate_oauth_application_secret" do
      Tracer.set_attributes([{"glossia.oauth_application.id", to_string(app.id)}])

      client = Boruta.Ecto.Admin.get_client!(app.boruta_client_id)

      case Boruta.Ecto.Admin.regenerate_client_secret(client) do
        {:ok, client} ->
          if actor = Keyword.get(opts, :actor) do
            account = Repo.preload(app, :account).account

            Events.emit("oauth_app.secret_regenerated", account, actor,
              resource_type: "oauth_application",
              resource_id: to_string(app.id),
              resource_path: "/#{account.handle}/-/settings/apps/#{app.id}",
              summary: "Regenerated client secret for \"#{app.name}\"",
              via: Keyword.get(opts, :via)
            )
          end

          {:ok, %{app: app, client_secret: client.secret}}

        {:error, _} = error ->
          error
      end
    end
  end

  def delete_oauth_application(%OAuthApplication{} = app, opts \\ []) do
    Tracer.with_span "glossia.developer_tokens.delete_oauth_application" do
      Tracer.set_attributes([{"glossia.oauth_application.id", to_string(app.id)}])

      Ecto.Multi.new()
      |> Ecto.Multi.run(:boruta_client, fn _repo, _changes ->
        client = Boruta.Ecto.Admin.get_client!(app.boruta_client_id)
        Boruta.Ecto.Admin.delete_client(client)
      end)
      |> Ecto.Multi.delete(:oauth_application, app)
      |> Repo.transaction()
      |> case do
        {:ok, _} ->
          if actor = Keyword.get(opts, :actor) do
            account = Repo.preload(app, :account).account

            Events.emit("oauth_app.deleted", account, actor,
              resource_type: "oauth_application",
              resource_id: to_string(app.id),
              resource_path: "/#{account.handle}/-/settings/apps",
              summary: "Deleted OAuth application \"#{app.name}\"",
              via: Keyword.get(opts, :via)
            )
          end

          :ok

        {:error, _step, changeset, _changes} ->
          {:error, changeset}
      end
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
