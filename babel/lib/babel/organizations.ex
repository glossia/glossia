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
