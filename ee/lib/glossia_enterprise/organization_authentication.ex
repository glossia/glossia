defmodule GlossiaEnterprise.OrganizationAuthentication do
  @moduledoc "Organization identity providers and domain ownership verification."
  use GlossiaWeb, :verified_routes
  import Ecto.Query
  import Ecto.Changeset, except: [change: 2]
  alias Glossia.Accounts
  alias Glossia.Accounts.{Identity, Organization, User}
  alias Glossia.{Organizations, Repo}

  defdelegate login_form(assigns), to: GlossiaEnterpriseWeb.LoginComponents

  def change(organization, attrs) do
    organization
    |> cast(attrs, [
      :auth_provider,
      :auth_domain,
      :auth_issuer,
      :auth_client_id,
      :auth_client_secret
    ])
    |> update_change(:auth_domain, fn
      nil -> nil
      domain -> String.downcase(String.trim(domain))
    end)
    |> validate_inclusion(:auth_provider, ["google", "okta"])
    |> validate_format(
      :auth_domain,
      ~r/\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/
    )
    |> validate_length(:auth_domain, max: 253)
    |> validate_provider()
    |> unique_constraint(:auth_domain)
  end

  defp validate_provider(changeset) do
    case get_field(changeset, :auth_provider) do
      nil ->
        changeset

      "google" ->
        validate_required(changeset, [:auth_domain])

      "okta" ->
        changeset
        |> validate_required([:auth_domain, :auth_issuer, :auth_client_id, :auth_client_secret])
        |> validate_change(:auth_issuer, fn field, value ->
          case URI.parse(value) do
            %URI{
              scheme: "https",
              host: host,
              port: 443,
              userinfo: nil,
              query: nil,
              fragment: nil,
              path: path
            }
            when is_binary(host) ->
              if Regex.match?(~r/\A[a-z0-9-]+\.okta(?:preview|eu)?\.com\z/, host) and
                   path in [nil, "", "/", "/oauth2/default"],
                 do: [],
                 else: [{field, "must be an Okta organization issuer"}]

            _ ->
              [{field, "must be an Okta organization issuer using https"}]
          end
        end)

      _ ->
        changeset
    end
  end

  def save(organization, actor, attrs) do
    if Glossia.Roles.has_organization_role?(actor, organization, "admin") do
      Repo.transaction(fn ->
        current =
          Repo.one!(from o in Organization, where: o.id == ^organization.id, lock: "FOR UPDATE")

        attrs =
          if attrs["auth_client_secret"] == "",
            do: Map.delete(attrs, "auth_client_secret"),
            else: attrs

        changeset = change(current, attrs)

        changeset =
          if get_field(changeset, :auth_domain) != current.auth_domain or
               get_field(changeset, :auth_provider) != current.auth_provider do
            changeset
            |> put_change(:auth_domain_verified_at, nil)
            |> put_change(:auth_domain_token, token())
          else
            changeset
          end

        changeset =
          if get_field(changeset, :auth_provider) != "okta" do
            changeset
            |> put_change(:auth_issuer, nil)
            |> put_change(:auth_client_id, nil)
            |> put_change(:auth_client_secret, nil)
          else
            changeset
          end

        case Repo.update(changeset) do
          {:ok, updated} ->
            audit(
              updated,
              actor,
              "organization.authentication_updated",
              "Updated organization authentication"
            )

            updated

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    else
      {:error, :unauthorized}
    end
  end

  def record_name(organization), do: "_glossia-verification.#{organization.auth_domain}"

  def record_value(organization),
    do: "glossia-domain-verification=#{organization.auth_domain_token}"

  def verify(organization, actor, resolver \\ &lookup/1, opts \\ []) do
    with true <- Glossia.Roles.has_organization_role?(actor, organization, "admin"),
         true <- is_binary(organization.auth_domain_token),
         {:ok, records} <- resolver.(record_name(organization)),
         true <- record_value(organization) in records do
      now = DateTime.utc_now()

      Repo.transaction(fn ->
        current =
          Repo.one!(from o in Organization, where: o.id == ^organization.id, lock: "FOR UPDATE")

        if current.auth_domain_token != organization.auth_domain_token or
             is_nil(current.auth_provider),
           do: Repo.rollback(:domain_changed)

        Repo.update_all(
          from(o in Organization,
            where:
              o.auth_domain == ^current.auth_domain and
                o.auth_domain_verified_at <= ^verification_cutoff()
          ),
          set: [auth_domain_verified_at: nil]
        )

        case current
             |> Ecto.Changeset.change(auth_domain_verified_at: now)
             |> unique_constraint(:auth_domain)
             |> Repo.update() do
          {:ok, updated} ->
            audit(
              updated,
              actor,
              "organization.domain_verified",
              "Verified organization authentication domain",
              opts
            )

            Repo.preload(updated, :account)

          {:error, _} ->
            Repo.rollback(:domain_already_verified)
        end
      end)
    else
      _ -> {:error, :verification_failed}
    end
  end

  def lookup(name) do
    records = :inet_res.lookup(String.to_charlist(name), :in, :txt, [], 5_000)
    {:ok, Enum.map(records, &IO.iodata_to_binary/1)}
  rescue
    _ -> {:error, :lookup_failed}
  end

  def for_email(email) when is_binary(email) do
    case String.split(String.downcase(String.trim(email)), "@") do
      [_local, domain] ->
        Repo.one(
          from o in Organization,
            where:
              o.auth_domain == ^domain and not is_nil(o.auth_provider) and
                o.auth_domain_verified_at > ^verification_cutoff()
        )

      _ ->
        nil
    end
  end

  def for_email(_), do: nil

  def config(organization) do
    case organization.auth_provider do
      "google" ->
        if Keyword.has_key?(Application.get_env(:glossia, :oauth_providers, []), :google) do
          {:ok,
           Glossia.Auth.provider_config!(:google)
           |> Keyword.put(:redirect_uri, callback_url())
           |> Keyword.put(:nonce, true)
           |> Keyword.put(:authorization_params,
             scope: "email profile",
             hd: organization.auth_domain
           )}
        else
          {:error, :provider_unavailable}
        end

      "okta" ->
        {:ok,
         [
           strategy: Assent.Strategy.OIDC,
           base_url: organization.auth_issuer,
           openid_configuration_uri: discovery_url(organization.auth_issuer),
           client_id: organization.auth_client_id,
           client_secret: organization.auth_client_secret,
           redirect_uri: callback_url(),
           nonce: true,
           authorization_params: [scope: "openid email profile"]
         ]}

      _ ->
        {:error, :provider_unavailable}
    end
  end

  defp discovery_url(issuer) do
    uri = URI.parse(issuer)

    %{uri | path: Path.join(uri.path || "/", ".well-known/openid-configuration")}
    |> URI.to_string()
  end

  def callback_url do
    URI.merge(GlossiaWeb.Endpoint.url(), ~p"/auth/organization/callback") |> URI.to_string()
  end

  def sign_in(organization, %{user: info} = response, opts \\ []) do
    Repo.transaction(fn ->
      current =
        Repo.one!(from o in Organization, where: o.id == ^organization.id, lock: "FOR UPDATE")

      unless current.auth_provider == organization.auth_provider and
               current.auth_issuer == organization.auth_issuer and
               current.auth_domain == organization.auth_domain and
               current.auth_client_id == organization.auth_client_id and
               current.auth_client_secret == organization.auth_client_secret and
               verified?(current) and
               valid_identity?(current, info),
             do: Repo.rollback(:invalid_identity)

      provider = "organization:#{current.id}:#{current.auth_provider}:#{current.auth_issuer}"

      user =
        case Accounts.get_identity(provider, info["sub"]) do
          %Identity{user: user} ->
            user

          nil ->
            case Accounts.get_user_by_email(info["email"]) do
              %User{} = user ->
                # A tenant administrator can control Okta claims. Linking an existing
                # Glossia identity therefore requires its authenticated session.
                unless opts[:link_user_id] == user.id or
                         linked_google_identity?(current, info, user),
                       do: Repo.rollback(:identity_not_linked)

                %Identity{user_id: user.id}
                |> Identity.changeset(%{provider: provider, provider_uid: info["sub"]})
                |> Repo.insert!()

                user

              nil ->
                case Accounts.find_or_create_user_from_oauth(provider, response) do
                  {:ok, user} -> user
                  {:error, reason} -> Repo.rollback(reason)
                end
            end
        end

      unless Organizations.get_membership(current, user) do
        if Repo.exists?(
             from b in "organization_auth_blocks",
               where:
                 b.organization_id == type(^current.id, :binary_id) and
                   b.user_id == type(^user.id, :binary_id)
           ),
           do: Repo.rollback(:membership_revoked)

        case Organizations.add_member(current, user) do
          {:ok, _} -> :ok
          {:error, reason} -> Repo.rollback(reason)
        end
      end

      audit(
        current,
        user,
        "organization.signed_in",
        "Signed in with organization identity provider"
      )

      user
    end)
  end

  def valid_identity?(organization, info) do
    is_binary(info["sub"]) and info["sub"] != "" and info["email_verified"] == true and
      match?(%Organization{id: id} when id == organization.id, for_email(info["email"])) and
      (organization.auth_provider != "google" or info["hd"] == organization.auth_domain)
  end

  def verified?(organization),
    do:
      not is_nil(organization.auth_domain_verified_at) and
        DateTime.compare(organization.auth_domain_verified_at, verification_cutoff()) == :gt

  defp verification_cutoff, do: DateTime.add(DateTime.utc_now(), -30, :day)

  defp linked_google_identity?(%{auth_provider: "google"}, info, user) do
    case Accounts.get_identity(:google, info["sub"]) do
      %Identity{user_id: id} -> id == user.id
      _ -> false
    end
  end

  defp linked_google_identity?(_, _, _), do: false

  defp audit(organization, actor, event, summary, opts \\ []) do
    actor = if opts[:via] == "scheduled", do: nil, else: actor
    organization = Repo.preload(organization, :account)

    Glossia.Events.emit(event, organization.account, actor,
      resource_type: "organization",
      resource_id: organization.id,
      summary: summary,
      via: opts[:via]
    )
  end

  defp token, do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
end
