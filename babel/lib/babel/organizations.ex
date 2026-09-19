defmodule Babel.Organizations do
  @moduledoc """
  Organizations and their relationship history across Babel domains.
  """

  import Ecto.Query

  alias Babel.Organizations.Directory
  alias Babel.Organizations.Interaction
  alias Babel.Organizations.Organization
  alias Babel.Organizations.TemporaryAccess
  alias Babel.Organizations.Usage
  alias Babel.Organizations.UsageCache
  alias Babel.Repo
  alias Ecto.Multi

  def list_organizations(options \\ []) do
    Organization
    |> filter_by_state(Keyword.get(options, :state))
    |> exclude_by_state(Keyword.get(options, :state_not))
    |> search(Keyword.get(options, :search))
    |> order(Keyword.get(options, :sort_by), Keyword.get(options, :sort_order))
    |> Repo.all()
  end

  def directory(opts \\ []), do: Directory.list(opts)

  def get_organization(id) do
    case Repo.get(Organization, id) do
      nil ->
        nil

      organization ->
        Repo.preload(organization,
          interactions:
            from(interaction in Interaction, order_by: [desc: interaction.occurred_at])
        )
    end
  end

  def create_organization(attributes) do
    %Organization{}
    |> Organization.changeset(attributes)
    |> Repo.insert()
  end

  def update_organization(%Organization{} = organization, attributes) do
    Multi.new()
    |> Multi.update(:organization, Organization.changeset(organization, attributes))
    |> Multi.run(:state_change, fn repo, %{organization: updated_organization} ->
      record_state_change(repo, organization, updated_organization)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: updated_organization}} -> {:ok, updated_organization}
      {:error, :organization, changeset, _changes} -> {:error, changeset}
      {:error, :state_change, changeset, _changes} -> {:error, changeset}
    end
  end

  def create_interaction(%Organization{} = organization, attributes) do
    attributes =
      attributes
      |> Map.new(fn {key, value} -> {to_string(key), value} end)
      |> Map.put("organization_id", organization.id)

    %Interaction{}
    |> Interaction.changeset(attributes)
    |> Repo.insert()
  end

  def summary do
    organizations = list_organizations()

    %{
      total: Enum.count(organizations),
      researching: Enum.count(organizations, &(&1.state == "researching")),
      qualified: Enum.count(organizations, &(&1.state == "qualified")),
      engaging: Enum.count(organizations, &(&1.state == "engaging")),
      demos_scheduled: Enum.count(organizations, &(&1.state == "demo_scheduled"))
    }
  end

  def usage(%Organization{glossia_organization_id: organization_id})
      when is_binary(organization_id),
      do: UsageCache.fetch(organization_id, fn -> Usage.fetch(organization_id) end)

  def usage(%Organization{}), do: :not_connected

  def grant_temporary_access(%Organization{} = organization, requester, attributes, opts \\ []) do
    client = Keyword.get(opts, :client, &Babel.Glossia.grant_temporary_access/3)

    with organization_id when is_binary(organization_id) <- organization.glossia_organization_id,
         true <- valid_requester?(requester),
         changeset <- TemporaryAccess.changeset(%TemporaryAccess{}, attributes),
         {:ok, temporary_access} <- Ecto.Changeset.apply_action(changeset, :grant),
         {:ok, grant} <-
           client.(
             organization_id,
             %{
               "email" => temporary_access.email,
               "duration_minutes" => temporary_access.duration_minutes,
               "reason" => temporary_access.reason,
               "requested_by_email" => requester.email,
               "requested_by_pomerium_id" => requester.pomerium_id
             },
             []
           ) do
      {:ok, grant}
    else
      nil -> {:error, :not_connected}
      false -> {:error, :unauthorized}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      {:error, _reason} = error -> error
    end
  end

  def create_claimable_glossia_organization(
        %Organization{} = organization,
        requester,
        handle,
        opts \\ []
      ) do
    client = Keyword.get(opts, :client, &Babel.Glossia.create_claimable_organization/2)

    with :ok <- ensure_not_connected(organization),
         true <- valid_requester?(requester),
         :ok <- validate_glossia_handle(handle),
         {:ok, response} <-
           client.(
             %{
               "handle" => handle,
               "name" => organization.name,
               "requested_by_email" => requester.email,
               "requested_by_pomerium_id" => requester.pomerium_id
             },
             []
           ),
         {:ok, organization_id, account_handle} <- parse_claimable_organization(response),
         {:ok, updated_organization} <-
           update_claimable_organization_reference(organization, organization_id, account_handle) do
      {:ok, updated_organization}
    else
      {:error, _reason} = error -> error
      false -> {:error, :unauthorized}
    end
  end

  def transfer_claimable_glossia_organization(
        %Organization{} = organization,
        requester,
        email,
        opts \\ []
      ) do
    client = Keyword.get(opts, :client, &Babel.Glossia.transfer_claimable_organization/3)

    with {:ok, handle} <- connected_account_handle(organization),
         true <- valid_requester?(requester),
         :ok <- validate_email(email),
         {:ok, _response} <-
           client.(
             handle,
             %{
               "email" => email,
               "requested_by_email" => requester.email,
               "requested_by_pomerium_id" => requester.pomerium_id
             },
             []
           ),
         {:ok, _interaction} <-
           record_ownership_transfer(organization, email) do
      {:ok, %{organization | glossia_claimable: false}}
    else
      {:error, "organization_not_claimable"} = error ->
        {:ok, _organization} = mark_glossia_organization_not_claimable(organization)
        error

      {:error, _reason} = error ->
        error

      false ->
        {:error, :unauthorized}
    end
  end

  def favicon_url(%Organization{website_url: website_url}) when is_binary(website_url) do
    case URI.parse(website_url) do
      %URI{scheme: "https", host: host} = uri when is_binary(host) and host != "" ->
        uri
        |> URI.merge("/favicon.ico")
        |> URI.to_string()

      _uri ->
        nil
    end
  end

  def favicon_url(%Organization{}), do: nil

  defp record_state_change(_repo, %{state: state}, %{state: state}), do: {:ok, nil}

  defp record_state_change(repo, previous_organization, updated_organization) do
    %Interaction{}
    |> Interaction.changeset(%{
      organization_id: updated_organization.id,
      kind: "state_change",
      summary:
        "Changed organization state from #{previous_organization.state} to #{updated_organization.state}.",
      occurred_at: DateTime.utc_now(:second)
    })
    |> repo.insert()
  end

  defp valid_requester?(%{email: email, pomerium_id: pomerium_id})
       when is_binary(email) and is_binary(pomerium_id) do
    case String.split(String.downcase(email), "@", parts: 2) do
      [local_part, "glossia.ai"] when local_part != "" -> true
      _ -> false
    end
  end

  defp valid_requester?(_requester), do: false

  defp ensure_not_connected(%Organization{glossia_organization_id: nil}), do: :ok
  defp ensure_not_connected(%Organization{}), do: {:error, :already_connected}

  defp parse_claimable_organization(%{"id" => id, "handle" => handle})
       when is_binary(id) and is_binary(handle) do
    with {:ok, organization_id} <- Ecto.UUID.cast(id),
         true <- valid_glossia_handle?(handle) do
      {:ok, organization_id, handle}
    else
      _error -> {:error, :invalid_glossia_response}
    end
  end

  defp parse_claimable_organization(_response), do: {:error, :invalid_glossia_response}

  defp update_claimable_organization_reference(organization, organization_id, handle) do
    Multi.new()
    |> Multi.update(
      :organization,
      Organization.changeset(organization, %{
        glossia_organization_id: organization_id,
        glossia_account_handle: handle,
        glossia_claimable: true
      })
    )
    |> Multi.insert(:interaction, fn %{organization: updated_organization} ->
      Interaction.changeset(%Interaction{}, %{
        organization_id: updated_organization.id,
        kind: "note",
        summary: "Created claimable Glossia organization \"#{handle}\".",
        occurred_at: DateTime.utc_now(:second)
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: updated_organization}} -> {:ok, updated_organization}
      {:error, :organization, changeset, _changes} -> {:error, changeset}
      {:error, :interaction, changeset, _changes} -> {:error, changeset}
    end
  end

  defp record_ownership_transfer(organization, email) do
    Multi.new()
    |> Multi.update(
      :organization,
      Organization.changeset(organization, %{glossia_claimable: false})
    )
    |> Multi.insert(:interaction, fn %{organization: updated_organization} ->
      Interaction.changeset(%Interaction{}, %{
        organization_id: updated_organization.id,
        kind: "note",
        summary: "Transferred claimable Glossia organization ownership to #{email}.",
        occurred_at: DateTime.utc_now(:second)
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{interaction: interaction}} -> {:ok, interaction}
      {:error, :organization, changeset, _changes} -> {:error, changeset}
      {:error, :interaction, changeset, _changes} -> {:error, changeset}
    end
  end

  defp mark_glossia_organization_not_claimable(organization) do
    organization
    |> Organization.changeset(%{glossia_claimable: false})
    |> Repo.update()
  end

  defp connected_account_handle(%Organization{
         glossia_organization_id: organization_id,
         glossia_account_handle: handle,
         glossia_claimable: true
       })
       when is_binary(organization_id) and is_binary(handle) and handle != "" do
    {:ok, handle}
  end

  defp connected_account_handle(%Organization{glossia_organization_id: organization_id})
       when is_binary(organization_id),
       do: {:error, :not_claimable}

  defp connected_account_handle(%Organization{}), do: {:error, :not_connected}

  defp valid_glossia_handle?(handle) when is_binary(handle) do
    Regex.match?(~r/^[a-z]([a-z0-9-]*[a-z0-9])?$/, handle) and
      String.length(handle) in 2..39
  end

  defp valid_glossia_handle?(_handle), do: false

  defp validate_glossia_handle(handle) do
    if valid_glossia_handle?(handle), do: :ok, else: {:error, :invalid_handle}
  end

  defp valid_email?(email) when is_binary(email) do
    case String.split(String.trim(email), "@", parts: 2) do
      [local_part, domain] when local_part != "" and domain != "" -> true
      _ -> false
    end
  end

  defp valid_email?(_email), do: false

  defp validate_email(email) do
    if valid_email?(email), do: :ok, else: {:error, :invalid_email}
  end

  defp filter_by_state(query, nil), do: query

  defp filter_by_state(query, state),
    do: where(query, [organization], organization.state == ^state)

  defp exclude_by_state(query, nil), do: query

  defp exclude_by_state(query, state),
    do: where(query, [organization], organization.state != ^state)

  defp search(query, search) when is_binary(search) do
    case String.trim(search) do
      "" ->
        query

      value ->
        pattern = "%#{value}%"

        where(
          query,
          [organization],
          ilike(organization.name, ^pattern) or ilike(organization.translation_tool, ^pattern) or
            ilike(organization.notes, ^pattern)
        )
    end
  end

  defp search(query, _search), do: query

  defp order(query, "state", "desc"),
    do: order_by(query, [organization], desc: organization.state)

  defp order(query, "state", _order), do: order_by(query, [organization], asc: organization.state)

  defp order(query, "notes", "desc"),
    do: order_by(query, [organization], desc: organization.notes)

  defp order(query, "notes", _order), do: order_by(query, [organization], asc: organization.notes)
  defp order(query, "name", "desc"), do: order_by(query, [organization], desc: organization.name)
  defp order(query, _sort_by, _order), do: order_by(query, [organization], asc: organization.name)
end
