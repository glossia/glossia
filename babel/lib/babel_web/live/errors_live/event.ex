defmodule BabelWeb.ErrorsLive.Event do
  @moduledoc """
  Detail page for a single event captured under an issue. Renders the
  same panels as the issue detail page but scoped to the specific
  event id in the URL rather than the latest event.
  """

  use BabelWeb, :live_view
  use Noora

  import BabelWeb.ErrorsLive.Components

  alias Babel.Errors
  alias Babel.Errors.LiveHelpers
  alias BabelWeb.Layouts

  def mount(%{"id" => id, "event_id" => event_id}, _session, socket) do
    organization = LiveHelpers.current_organization()

    with {:ok, issue} <- Errors.get_issue(organization.id, id),
         {:ok, event} <- Errors.get_event(organization.id, issue.id, event_id) do
      {:ok,
       socket
       |> assign(:organization, organization)
       |> assign(:issue, issue)
       |> assign(:event, event)
       |> assign(:payload, event_payload(event))
       |> assign(:page_title, "Event · #{issue.title}")}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Event not found.")
         |> push_navigate(to: ~p"/errors")}
    end
  end

  def handle_params(_params, uri, socket) do
    parsed = URI.parse(uri)
    {:noreply, assign(socket, current_path: parsed.path || "/errors")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path} live_action={@live_action}>
      <section id="error-event">
        <div data-part="header">
          <div data-part="title-group">
            <div data-part="breadcrumbs">
              <.link navigate={~p"/errors"}>Errors</.link>
              <span data-part="separator">/</span>
              <.link navigate={~p"/errors/#{@issue.id}"}>{@issue.title |> truncate_title()}</.link>
              <span data-part="separator">/</span>
              <span>{normalize_event_id(@event.event_id)}</span>
            </div>
            <h1>{event_headline(@event, @issue)}</h1>
            <p data-part="event-meta">
              <span>{format_datetime(@event.timestamp)}</span>
              <span :if={present?(@event.environment)}>· {@event.environment}</span>
              <span :if={present?(@event.release)}>· Release {@event.release}</span>
            </p>
          </div>
        </div>

        <.event_panels issue={@issue} event={@event} payload={@payload} />
      </section>
    </Layouts.app>
    """
  end

  defp event_headline(event, issue) do
    cond do
      present?(event.exception_type) and present?(event.exception_value) ->
        "#{event.exception_type}: #{event.exception_value}"

      present?(event.exception_type) ->
        event.exception_type

      true ->
        issue.title
    end
  end

  defp event_payload(event) do
    case event.payload do
      %{} = payload ->
        payload

      payload when is_binary(payload) ->
        case Jason.decode(payload) do
          {:ok, %{} = decoded} -> decoded
          _ -> %{}
        end

      _ ->
        %{}
    end
  end
end
