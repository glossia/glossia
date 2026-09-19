defmodule Babel.GoToMarket do
  @moduledoc """
  Public-source prospect research and reviewable, draft-only outreach preparation.
  """

  import Ecto.Query

  alias Babel.GoToMarket.Prospect
  alias Babel.GoToMarket.Search.Tavily
  alias Babel.Organizations
  alias Babel.Organizations.Organization
  alias Babel.Repo

  @discovery_queries [
    %{
      query: "site:phrase.com customer story localization engineering product development",
      translation_tool: "Phrase"
    },
    %{
      query: "site:crowdin.com customer story localization engineering product development",
      translation_tool: "Crowdin"
    },
    %{
      query: "site:lokalise.com case study localization engineering product development",
      translation_tool: "Lokalise"
    }
  ]

  def list_prospects(options \\ []) do
    Prospect
    |> filter_by_status(Keyword.get(options, :status))
    |> order_by([prospect], asc: prospect.status, desc: prospect.updated_at)
    |> Repo.all()
  end

  def get_prospect(id), do: Repo.get(Prospect, id)

  def create_prospect(attributes) do
    %Prospect{}
    |> Prospect.changeset(attributes)
    |> Repo.insert()
  end

  def discover_new_prospects(searcher \\ &Tavily.search/1) do
    with {:ok, results} <- search_public_sources(searcher) do
      summary =
        results
        |> Enum.uniq_by(& &1.source_url)
        |> Enum.reduce(%{created: 0, already_known: 0}, &store_discovered_organization/2)

      {:ok, summary}
    end
  end

  def update_prospect(%Prospect{} = prospect, attributes) do
    prospect
    |> Prospect.changeset(attributes)
    |> Repo.update()
  end

  def prospect_summary do
    prospects = list_prospects()

    %{
      total: Enum.count(prospects),
      researching: Enum.count(prospects, &(&1.status == "researching")),
      ready: Enum.count(prospects, &(&1.status == "ready")),
      demos_booked: Enum.count(prospects, &(&1.status == "demo_booked"))
    }
  end

  defp search_public_sources(searcher) do
    Enum.reduce_while(@discovery_queries, {:ok, []}, fn source, {:ok, results} ->
      case searcher.(source.query) do
        {:ok, found_results} when is_list(found_results) ->
          {:cont, {:ok, results ++ annotate_discovery_results(found_results, source)}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp annotate_discovery_results(results, source) do
    Enum.map(results, &Map.put(&1, :translation_tool, source.translation_tool))
  end

  defp store_discovered_organization(result, summary) do
    attributes = discovered_organization_attributes(result)

    case Repo.get_by(Organization, website_url: attributes.website_url) do
      nil ->
        case create_discovered_organization(attributes, result) do
          {:ok, _organization} -> Map.update!(summary, :created, &(&1 + 1))
          {:error, _reason} -> summary
        end

      _organization ->
        Map.update!(summary, :already_known, &(&1 + 1))
    end
  end

  defp discovered_organization_attributes(result) do
    %{
      name: source_name(result.title),
      website_url: result.source_url,
      origin_url: result.source_url,
      translation_tool: result.translation_tool,
      state: "researching",
      notes:
        "Automatically discovered from a public source. Verify the company, current public contact, and workflow before drafting an introduction."
    }
  end

  defp create_discovered_organization(attributes, result) do
    with {:ok, organization} <- Organizations.create_organization(attributes),
         {:ok, _interaction} <-
           Organizations.create_interaction(organization, %{
             kind: "research",
             summary: "Captured a public-source signal for review.",
             body: source_name(result.evidence),
             source_url: result.source_url,
             occurred_at: DateTime.utc_now(:second)
           }) do
      {:ok, organization}
    end
  end

  defp source_name(value) when is_binary(value), do: String.trim(value)
  defp source_name(_value), do: "Public company signal"

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status), do: where(query, [prospect], prospect.status == ^status)
end
