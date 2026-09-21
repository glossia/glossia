defmodule Babel.MCP.ListErrorIssuesTool do
  @moduledoc "List error issues captured by the Sentry-compatible ingest endpoint, scoped to an organization."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.Errors
  alias Babel.Errors.Issue
  alias Babel.MCP.Authorization
  alias BabelWeb.Endpoint
  alias Hermes.Server.Response

  @statuses Enum.map(Issue.statuses(), &Atom.to_string/1)
  @sort_columns ["last_seen", "first_seen", "event_count", "level"]

  schema do
    field :organization_id, :integer,
      required: true,
      description: "Organization whose error issues to list."

    field :status, :string,
      enum: @statuses,
      description: "Filter by issue status."

    field :search, :string, description: "Substring match against issue title or culprit."

    field :from, :string, description: "Inclusive ISO 8601 lower bound on last_seen."

    field :to, :string, description: "Inclusive ISO 8601 upper bound on last_seen."

    field :sort, :string,
      enum: @sort_columns,
      description: "Column used to sort the results (default last_seen)."

    field :direction, :string,
      enum: ["asc", "desc"],
      description: "Sort direction (default desc)."

    field :page, :integer, description: "1-indexed page number."
    field :page_size, :integer, description: "Page size, 1-100 (default 25)."
  end

  @impl true
  def execute(params, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        {issues, meta} = Errors.list_issues(params.organization_id, list_opts(params))
        endpoint_url = Endpoint.url()

        response =
          Response.tool()
          |> Response.structured(%{
            issues: Enum.map(issues, &Errors.serialize_issue(&1, endpoint_url)),
            pagination: meta
          })

        {:reply, response, frame}

      {:error, error} ->
        {:error, error, frame}
    end
  end

  defp list_opts(params) do
    [
      status: to_status(params[:status]),
      search: present(params[:search]),
      from: parse_datetime(params[:from]),
      to: parse_datetime(params[:to]),
      sort: to_sort(params[:sort]),
      direction: to_direction(params[:direction]),
      page: params[:page],
      page_size: clamp_page_size(params[:page_size])
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp to_status("unresolved"), do: :unresolved
  defp to_status("resolved"), do: :resolved
  defp to_status("ignored"), do: :ignored
  defp to_status(_), do: nil

  defp to_sort("last_seen"), do: :last_seen
  defp to_sort("first_seen"), do: :first_seen
  defp to_sort("event_count"), do: :event_count
  defp to_sort("level"), do: :level
  defp to_sort(_), do: nil

  defp to_direction("asc"), do: :asc
  defp to_direction("desc"), do: :desc
  defp to_direction(_), do: nil

  defp clamp_page_size(size) when is_integer(size) and size > 0, do: min(size, 100)
  defp clamp_page_size(_), do: nil

  defp present(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp present(_), do: nil

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end
end
