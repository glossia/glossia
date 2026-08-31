defmodule Babel.Organizations.Directory do
  @moduledoc false

  alias Babel.Glossia
  alias Babel.Organizations
  alias Babel.Organizations.DirectoryCache

  @glossia_organization_limit 200

  def list(opts \\ []) do
    local_organizations = Organizations.list_organizations()
    query = Keyword.get(opts, :query, &Glossia.query/2)
    cache = Keyword.get(opts, :cache, DirectoryCache)

    case DirectoryCache.fetch(fn -> fetch_glossia_organizations(query) end, cache) do
      {:ok, glossia_organizations} ->
        glossia_organizations
        |> reconcile(local_organizations)
        |> filter_and_sort(opts)

      {:error, _reason} ->
        local_organizations
        |> local_directory()
        |> filter_and_sort(opts)
    end
  end

  defp fetch_glossia_organizations(query) do
    case query.(glossia_organization_query(), limit: @glossia_organization_limit) do
      {:ok, response} -> parse_glossia_organizations(response)
      {:error, _reason} = error -> error
    end
  end

  defp parse_glossia_organizations(%{"rows" => rows}) when is_list(rows) do
    {:ok, Enum.flat_map(rows, &parse_glossia_organization/1)}
  end

  defp parse_glossia_organizations(_response), do: {:error, :invalid_response}

  defp parse_glossia_organization(%{"organization_id" => id, "name" => name})
       when is_binary(id) and is_binary(name) do
    case Ecto.UUID.cast(id) do
      {:ok, id} -> [%{id: id, name: name}]
      :error -> []
    end
  end

  defp parse_glossia_organization(_row), do: []

  defp reconcile(glossia_organizations, local_organizations) do
    organizations_by_glossia_id =
      Map.new(local_organizations, fn organization ->
        {organization.glossia_organization_id, organization}
      end)

    glossia_entries =
      Enum.map(glossia_organizations, fn glossia_organization ->
        %{
          id: "glossia-#{glossia_organization.id}",
          name: glossia_organization.name,
          source: :glossia,
          organization: Map.get(organizations_by_glossia_id, glossia_organization.id)
        }
      end)

    lead_entries =
      local_organizations
      |> Enum.reject(& &1.glossia_organization_id)
      |> Enum.map(&lead_entry/1)

    sort(glossia_entries ++ lead_entries)
  end

  defp local_directory(local_organizations) do
    local_organizations
    |> Enum.map(fn organization ->
      if organization.glossia_organization_id do
        %{
          id: "glossia-#{organization.glossia_organization_id}",
          name: organization.name,
          source: :glossia,
          organization: organization
        }
      else
        lead_entry(organization)
      end
    end)
    |> sort()
  end

  defp lead_entry(organization) do
    %{
      id: "lead-#{organization.id}",
      name: organization.name,
      source: :lead,
      organization: organization
    }
  end

  defp sort(entries) do
    Enum.sort_by(entries, fn entry ->
      {directory_source_order(entry.source), String.downcase(entry.name)}
    end)
  end

  defp directory_source_order(:glossia), do: 0
  defp directory_source_order(:lead), do: 1

  defp filter_and_sort(entries, opts) do
    entries
    |> filter_by_source(Keyword.get(opts, :source))
    |> exclude_source(Keyword.get(opts, :source_not))
    |> search(Keyword.get(opts, :search))
    |> order(Keyword.get(opts, :sort_by), Keyword.get(opts, :sort_order))
  end

  defp filter_by_source(entries, "glossia"), do: Enum.filter(entries, &(&1.source == :glossia))
  defp filter_by_source(entries, "lead"), do: Enum.filter(entries, &(&1.source == :lead))
  defp filter_by_source(entries, _source), do: entries

  defp exclude_source(entries, "glossia"), do: Enum.reject(entries, &(&1.source == :glossia))
  defp exclude_source(entries, "lead"), do: Enum.reject(entries, &(&1.source == :lead))
  defp exclude_source(entries, _source), do: entries

  defp search(entries, search) when is_binary(search) do
    case String.trim(search) do
      "" ->
        entries

      search ->
        Enum.filter(entries, &String.contains?(String.downcase(&1.name), String.downcase(search)))
    end
  end

  defp search(entries, _search), do: entries

  defp order(entries, "source", "desc"), do: Enum.sort_by(entries, &source_name/1, :desc)
  defp order(entries, "source", _order), do: Enum.sort_by(entries, &source_name/1)
  defp order(entries, "name", "desc"), do: Enum.sort_by(entries, &String.downcase(&1.name), :desc)
  defp order(entries, _sort_by, _order), do: sort(entries)

  defp source_name(%{source: :glossia}), do: "glossia"
  defp source_name(%{source: :lead}), do: "lead"

  defp glossia_organization_query do
    """
    SELECT organizations.id::text AS organization_id, organizations.name
    FROM organizations
    ORDER BY organizations.name ASC
    """
  end
end
