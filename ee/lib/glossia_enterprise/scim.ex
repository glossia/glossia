defmodule GlossiaEnterprise.SCIM do
  @moduledoc """
  Organization-scoped SCIM provisioning, following Tuist's Users and synthetic
  role-group model. Deactivation revokes membership, not the global user.

  Provisioning never changes a shared user's email or OAuth identities. Existing
  users must already belong to the organization before its IdP can manage them.
  Inactive resources remain addressable so an IdP can reactivate them.
  """
  import Ecto.Query
  alias Glossia.Accounts.{Account, Organization, OrganizationMembership, User}
  alias Glossia.{Accounts, Organizations, Repo, Roles}
  alias GlossiaEnterprise.SCIM.{ProvisionedUser, Token}

  def create_token(organization, actor, attrs) do
    if Roles.has_organization_role?(actor, organization, "admin") do
      plaintext =
        "glossia_scim_" <> Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

      Repo.transaction(fn ->
        token =
          %Token{organization_id: organization.id, token_hash: hash(plaintext)}
          |> Token.changeset(attrs)
          |> persist(&Repo.insert/1)

        audit(organization, actor, "scim.token_created", "Created SCIM provisioning token")
        %{token: token, plaintext: plaintext}
      end)
    else
      {:error, :unauthorized}
    end
  end

  def list_tokens(organization, actor) do
    if Roles.has_organization_role?(actor, organization, "admin") do
      Repo.all(
        from t in Token, where: t.organization_id == ^organization.id, order_by: t.inserted_at
      )
    else
      []
    end
  end

  def revoke_token(organization, actor, id) do
    if Roles.has_organization_role?(actor, organization, "admin") and valid_id?(id) do
      Repo.transaction(fn ->
        token = Repo.get_by(Token, id: id, organization_id: organization.id)
        if is_nil(token), do: Repo.rollback(:not_found)
        Repo.delete!(token)
        audit(organization, actor, "scim.token_revoked", "Revoked SCIM provisioning token")
      end)
    else
      {:error, :unauthorized}
    end
  end

  def authenticate_token("glossia_scim_" <> _ = plaintext) when byte_size(plaintext) == 56 do
    case Repo.get_by(Token, token_hash: hash(plaintext)) do
      nil -> {:error, :invalid_token}
      token -> {:ok, Organizations.get_organization(token.organization_id)}
    end
  end

  def authenticate_token(_), do: {:error, :invalid_token}
  defp hash(value), do: :crypto.hash(:sha256, value)

  def list_users(organization, filter, start_index, count) do
    with {:ok, query} <- filter_users(users_query(organization), filter) do
      total = Repo.aggregate(query, :count)

      rows =
        Repo.all(
          from [u, _, _] in query, order_by: u.id, offset: ^(start_index - 1), limit: ^count
        )

      {:ok, %{rows: rows, total: total, start_index: start_index}}
    end
  end

  def get_user(organization, id) do
    if valid_id?(id) do
      case Repo.one(from [u, _, _] in users_query(organization), where: u.id == ^id) do
        nil -> {:error, :not_found}
        resource -> {:ok, resource}
      end
    else
      {:error, :not_found}
    end
  end

  defp users_query(organization) do
    from u in User,
      left_join: m in OrganizationMembership,
      on: m.user_id == u.id and m.organization_id == ^organization.id,
      left_join: p in ProvisionedUser,
      on: p.user_id == u.id and p.organization_id == ^organization.id,
      where: not is_nil(m.id) or not is_nil(p.id),
      select: %{user: u, membership: m, provisioning: p}
  end

  defp filter_users(query, nil), do: {:ok, query}

  defp filter_users(query, {"username", value}),
    do:
      {:ok,
       from([u, _, _] in query, where: fragment("lower(?)", u.email) == ^String.downcase(value))}

  defp filter_users(query, {"externalid", value}),
    do: {:ok, from([_, _, p] in query, where: p.external_id == ^value)}

  defp filter_users(_, _), do: {:error, :invalid_filter}

  def provision_user(organization, attrs) do
    transaction(organization, fn current ->
      email = String.downcase(String.trim(attrs.user_name))
      # Different organizations can provision the same email concurrently.
      Repo.query!("SELECT pg_advisory_xact_lock(hashtextextended($1, 0))", [email])
      {user, created?} = provisionable_user(current, email, attrs)
      apply_attrs(current, user, attrs, created?)
    end)
  end

  defp provisionable_user(organization, email, attrs) do
    case Accounts.get_user_by_email(email) do
      nil ->
        account =
          %Account{}
          |> Account.changeset(%{
            handle: "scim-" <> Base.encode16(:crypto.strong_rand_bytes(10), case: :lower)
          })
          |> persist(&Repo.insert/1)

        user =
          %User{account_id: account.id}
          |> User.changeset(%{email: email, name: attrs[:display_name]})
          |> persist(&Repo.insert/1)

        Accounts.ensure_personal_organization!(user)
        {%{user | account: account}, true}

      user ->
        unless Organizations.get_membership(organization, user) ||
                 Repo.get_by(ProvisionedUser, organization_id: organization.id, user_id: user.id),
               do: Repo.rollback(:email_taken)

        {user, false}
    end
  end

  def update_user(organization, id, attrs) do
    transaction(organization, fn current ->
      %{user: user} = fetch_user!(current, id)

      if attrs[:user_name] && String.downcase(String.trim(attrs.user_name)) != user.email,
        do: Repo.rollback(:mutability)

      apply_attrs(current, user, attrs, false)
    end)
  end

  def deactivate_user(organization, id), do: update_user(organization, id, %{active: false})

  defp apply_attrs(organization, user, attrs, created?) do
    membership = Organizations.get_membership(organization, user)
    provisioned = Repo.get_by(ProvisionedUser, organization_id: organization.id, user_id: user.id)
    active = Map.get(attrs, :active, if(provisioned, do: provisioned.active, else: true))

    if active do
      role = Map.get(attrs, :role, if(membership, do: membership.role, else: "member"))
      set_role!(organization, user, role)

      if is_nil(membership) do
        %{user_id: user.id, organization_id: organization.id}
        |> GlossiaEnterprise.SCIM.AttachmentNotifierWorker.new()
        |> Oban.insert!()
      end
    else
      protect_last_admin!(organization, user)
      Organizations.remove_member(organization, user)
    end

    (provisioned ||
       %ProvisionedUser{
         organization_id: organization.id,
         user_id: user.id,
         identity_linkable: created?
       })
    |> ProvisionedUser.changeset(Map.put(attrs, :active, active))
    |> persist(&Repo.insert_or_update/1)

    audit(organization, nil, "scim.user_updated", "Updated SCIM organization membership")
    fetch_user!(organization, user.id)
  end

  def claim_identity(organization, user) do
    # Only a new, IdP-created account can be linked without an existing login.
    # Provisioning an existing member never grants control of their identity.
    {count, _} =
      Repo.update_all(
        from(p in ProvisionedUser,
          where:
            p.organization_id == ^organization.id and p.user_id == ^user.id and
              p.identity_linkable and p.active
        ),
        set: [identity_linkable: false]
      )

    count == 1
  end

  def list_groups(organization) do
    Enum.map(
      [
        {"admins", "Admins", "admin"},
        {"members", "Members", "member"},
        {"linguists", "Linguists", "linguist"}
      ],
      fn {id, name, role} ->
        members =
          Repo.all(
            from m in OrganizationMembership,
              join: u in User,
              on: u.id == m.user_id,
              where: m.organization_id == ^organization.id and m.role == ^role,
              select: u
          )

        %{id: id, display_name: name, members: members}
      end
    )
  end

  def get_group(organization, id) do
    case Enum.find(list_groups(organization), &(&1.id == id)) do
      nil -> {:error, :not_found}
      group -> {:ok, group}
    end
  end

  def patch_group(organization, id, operations) do
    transaction(organization, fn current ->
      role =
        case id do
          "admins" -> "admin"
          "members" -> "member"
          "linguists" -> "linguist"
          _ -> Repo.rollback(:not_found)
        end

      Enum.each(operations, fn {operation, ids} ->
        targets = Enum.map(ids, &fetch_user!(current, &1))
        if Enum.any?(targets, &is_nil(&1.membership)), do: Repo.rollback(:invalid_value)

        {:ok, previous} = get_group(current, id)

        Enum.each(targets, fn %{user: user} ->
          if operation == "remove",
            do: remove_group_role!(current, user, role),
            else: set_role!(current, user, role)
        end)

        if operation == "replace" do
          for user <- previous.members,
              user.id not in ids,
              do: remove_group_role!(current, user, role)
        end
      end)

      audit(current, nil, "scim.group_updated", "Updated SCIM organization roles")
      {:ok, group} = get_group(current, id)
      group
    end)
  end

  defp remove_group_role!(organization, user, role) do
    if Organizations.get_membership(organization, user).role == role do
      # Removing a role-group does not deprovision the user. It returns them to
      # basic member access; DELETE /Users or active=false revokes membership.
      set_role!(organization, user, "member")
    end
  end

  defp set_role!(organization, user, role) do
    if role != "admin", do: protect_last_admin!(organization, user)

    result =
      case Organizations.get_membership(organization, user) do
        nil ->
          Organizations.add_member(organization, user, role)

        %{role: ^role} = membership ->
          {:ok, membership}

        membership ->
          with {:ok, updated} <- Organizations.update_member_role(organization, user, role) do
            if membership.role == "admin" and role != "admin" do
              updated
              |> Ecto.Changeset.change(scopes: Glossia.MemberPermissions.basic_scopes())
              |> Repo.update()
            else
              {:ok, updated}
            end
          end
      end

    case result do
      {:ok, _} -> :ok
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp protect_last_admin!(organization, user) do
    if Organizations.sole_admin?(organization, user), do: Repo.rollback(:last_admin)
  end

  defp fetch_user!(organization, id) do
    case get_user(organization, id) do
      {:ok, resource} -> resource
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp transaction(organization, fun) do
    Repo.transaction(fn ->
      current =
        Repo.one!(from o in Organization, where: o.id == ^organization.id, lock: "FOR UPDATE")

      fun.(current)
    end)
  end

  defp persist(changeset, fun) do
    case fun.(changeset) do
      {:ok, value} -> value
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp valid_id?(id), do: match?({:ok, _}, Ecto.UUID.cast(id))

  defp audit(organization, actor, name, summary) do
    organization = Repo.preload(organization, :account)

    Glossia.Events.emit(name, organization.account, actor,
      resource_type: "organization",
      resource_id: organization.id,
      summary: summary,
      via: "scim"
    )
  end
end
