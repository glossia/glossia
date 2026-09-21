defmodule BabelWeb.ErrorsLive.Components do
  @moduledoc """
  Presentation helpers shared by the errors LiveViews (index, show,
  event). Level/status badges, relative-time and integer formatting,
  Sentry payload accessors, and stack-frame rendering all live here so
  the LiveViews themselves stay focused on interactions.
  """

  use Phoenix.Component
  use Noora

  alias Babel.Errors.CodeHighlight
  alias Babel.Errors.Issue

  @known_contexts ~w(user os runtime device browser app culture trace cloud_resource state response replay)

  @context_acronyms MapSet.new(~w(os sdk gpu cpu url http api ssl tls ip id))

  ## Badges

  attr :level, :any, required: true
  attr :size, :string, default: "small"

  def issue_level_badge(assigns) do
    ~H"""
    <.badge label={level_label(@level)} color={level_color(@level)} style="light-fill" size={@size} />
    """
  end

  attr :status, :any, required: true
  attr :size, :string, default: "small"

  def issue_status_badge(assigns) do
    ~H"""
    <.badge
      label={status_label(@status)}
      color={status_color(@status)}
      style="light-fill"
      size={@size}
    />
    """
  end

  ## Labels + colors

  def status_label(:unresolved), do: "Unresolved"
  def status_label(:resolved), do: "Resolved"
  def status_label(:ignored), do: "Ignored"
  def status_label(_), do: "-"

  def status_color(:unresolved), do: "warning"
  def status_color(:resolved), do: "success"
  def status_color(:ignored), do: "neutral"
  def status_color(_), do: "neutral"

  def level_label(:fatal), do: "Fatal"
  def level_label(:error), do: "Error"
  def level_label(:warning), do: "Warning"
  def level_label(:info), do: "Info"
  def level_label(:debug), do: "Debug"
  def level_label(other) when is_binary(other), do: other |> String.to_atom() |> level_label()
  def level_label(_), do: "-"

  def level_color(:fatal), do: "destructive"
  def level_color(:error), do: "destructive"
  def level_color(:warning), do: "warning"
  def level_color(:info), do: "information"
  def level_color(:debug), do: "neutral"
  def level_color(other) when is_binary(other), do: other |> String.to_atom() |> level_color()
  def level_color(_), do: "neutral"

  def http_method_color("GET"), do: "information"
  def http_method_color("POST"), do: "success"
  def http_method_color("PUT"), do: "warning"
  def http_method_color("PATCH"), do: "warning"
  def http_method_color("DELETE"), do: "destructive"

  def http_method_color(method) when is_binary(method),
    do: http_method_color(String.upcase(method))

  def http_method_color(_), do: "neutral"

  ## Formatting

  def format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")
  def format_datetime(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")
  def format_datetime(bin) when is_binary(bin), do: bin
  def format_datetime(_), do: "-"

  def format_integer(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  def format_integer(_), do: "0"

  def relative_time(%DateTime{} = dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)

    cond do
      diff < 5 -> "just now"
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86_400 -> "#{div(diff, 3600)}h ago"
      diff < 30 * 86_400 -> "#{div(diff, 86_400)}d ago"
      diff < 365 * 86_400 -> "#{div(diff, 30 * 86_400)}mo ago"
      true -> "#{div(diff, 365 * 86_400)}y ago"
    end
  end

  def relative_time(%NaiveDateTime{} = ndt),
    do: ndt |> DateTime.from_naive!("Etc/UTC") |> relative_time()

  def relative_time(bin) when is_binary(bin) do
    case DateTime.from_iso8601(bin) do
      {:ok, dt, _} -> relative_time(dt)
      _ -> bin
    end
  end

  def relative_time(_), do: "-"

  ## Payload accessors

  def stack_frames(%{
        "exception" => %{"values" => [%{"stacktrace" => %{"frames" => frames}} | _]}
      })
      when is_list(frames) do
    frames
    |> Enum.reverse()
    |> Enum.take(30)
  end

  def stack_frames(_), do: []

  def highlighted_frame(frame, payload) do
    CodeHighlight.highlight_frame(frame, Map.get(payload, "platform"))
  end

  def latest_message(payload) do
    case payload["message"] do
      %{"formatted" => formatted} when is_binary(formatted) and formatted != "" -> formatted
      %{"message" => message} when is_binary(message) and message != "" -> message
      msg when is_binary(msg) and msg != "" -> msg
      _ -> nil
    end
  end

  def request_data(payload) do
    case as_map(payload["request"]) do
      empty when map_size(empty) == 0 -> nil
      m -> m
    end
  end

  def sdk_info(payload) do
    case as_map(payload["sdk"]) do
      empty when map_size(empty) == 0 -> nil
      m -> m
    end
  end

  def event_breadcrumbs(payload) do
    case payload["breadcrumbs"] do
      %{"values" => values} when is_list(values) -> values
      values when is_list(values) -> values
      _ -> []
    end
  end

  def extra_pairs(payload) do
    payload["extra"]
    |> as_map()
    |> Enum.sort_by(&elem(&1, 0))
  end

  def module_pairs(payload) do
    payload["modules"]
    |> as_map()
    |> Enum.sort_by(&elem(&1, 0))
  end

  def contexts(payload) do
    map = as_map(payload["contexts"])

    user =
      case as_map(payload["user"]) do
        empty when map_size(empty) == 0 -> nil
        u -> u
      end

    map = if user, do: Map.put_new(map, "user", user), else: map

    map
    |> Enum.filter(fn {_k, v} -> is_map(v) and map_size(v) > 0 end)
    |> Enum.sort_by(fn {k, _} -> context_order(k) end)
  end

  def tag_pairs(%Issue{} = issue, payload) do
    payload_tags = as_map(payload["tags"])

    base = [
      {"environment", get(payload, "environment", "")},
      {"level", to_string(issue.level)},
      {"platform", get(payload, "platform", "")},
      {"release", get(payload, "release", "")},
      {"server_name", get(payload, "server_name", "")},
      {"transaction", get(payload, "transaction", "")},
      {"logger", get(payload, "logger", "")}
    ]

    (base ++ Enum.to_list(payload_tags))
    |> Enum.reject(fn {_, v} -> v == "" or is_nil(v) end)
    |> Enum.uniq_by(&elem(&1, 0))
    |> Enum.sort_by(&elem(&1, 0))
  end

  def format_context_name(name) do
    name
    |> to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", fn word ->
      if MapSet.member?(@context_acronyms, String.downcase(word)) do
        String.upcase(word)
      else
        String.capitalize(word)
      end
    end)
  end

  def flatten_context(map) when is_map(map) do
    map
    |> Enum.reject(fn {k, _} -> k == "type" end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  def flatten_context(_), do: []

  def format_context_value(nil), do: "-"
  def format_context_value(v) when is_binary(v), do: v
  def format_context_value(v) when is_number(v) or is_boolean(v), do: to_string(v)

  def format_context_value(map) when is_map(map) do
    if Enum.all?(map, fn {_, v} -> is_binary(v) or is_number(v) or is_boolean(v) end) do
      Enum.map_join(map, ", ", fn {k, v} -> "#{k}: #{v}" end)
    else
      inspect(map, pretty: true, limit: :infinity)
    end
  end

  def format_context_value(v), do: inspect(v, pretty: true, limit: :infinity)

  ## Frame rendering

  attr :frame, :map, required: true
  attr :payload, :map, required: true

  def stack_frame(assigns) do
    ~H"""
    <div data-part="frame" data-in-app={to_string(@frame["in_app"] == true)}>
      <div data-part="frame-header">
        <span data-part="frame-indicator" />
        <span data-part="frame-mfa">
          <span :if={@frame["module"]} data-part="frame-module">{@frame["module"]}</span><span :if={
            @frame["module"] && @frame["function"]
          }>.</span><span data-part="frame-function">{@frame["function"] || "?"}</span>
        </span>
        <span :if={@frame["filename"]} data-part="frame-location">
          {@frame["filename"]}<span :if={@frame["lineno"]}>:{@frame["lineno"]}</span>
        </span>
      </div>
      <div :if={highlighted_frame(@frame, @payload)} data-part="context">
        {Phoenix.HTML.raw(highlighted_frame(@frame, @payload))}
      </div>
    </div>
    """
  end

  attr :issue, :map, required: true
  attr :event, :map, required: true
  attr :payload, :map, required: true

  def event_panels(assigns) do
    ~H"""
    <.card
      :if={stack_frames(@payload) != []}
      title="Stack trace"
      icon="alert_triangle"
      id="error-stack-card"
    >
      <.card_section>
        <div data-part="event-header">
          <div data-part="event-title">
            <strong :if={present?(@event.exception_type)}>{@event.exception_type}</strong>
            <span :if={
              present?(@event.exception_type) and present?(@event.exception_value)
            }>:</span>
            <span :if={present?(@event.exception_value)}>{@event.exception_value}</span>
          </div>
          <div data-part="event-meta">
            <span>{format_datetime(@event.timestamp)}</span>
            <span :if={present?(@event.release)}>· Release {@event.release}</span>
            <span :if={present?(@event.environment)}>· {@event.environment}</span>
          </div>
        </div>

        <div data-part="stack-frames">
          <.stack_frame :for={frame <- stack_frames(@payload)} frame={frame} payload={@payload} />
        </div>
      </.card_section>
    </.card>

    <.card
      :if={stack_frames(@payload) == [] and latest_message(@payload)}
      title="Message"
      icon="info_circle"
      id="error-message-card"
    >
      <.card_section>
        <pre data-part="message-body">{latest_message(@payload)}</pre>
      </.card_section>
    </.card>

    <.card
      :if={tag_pairs(@issue, @payload) != []}
      title="Tags"
      icon="alert_hexagon"
      id="error-tags-card"
    >
      <.card_section>
        <div data-part="context-metadata-grid" data-columns="2">
          <div :for={{key, value} <- tag_pairs(@issue, @payload)} data-part="context-metadata">
            <div data-part="title">{key}</div>
            <span data-part="label">{value}</span>
          </div>
        </div>
      </.card_section>
    </.card>

    <.card
      :if={contexts(@payload) != []}
      title="Contexts"
      icon="stack_2"
      id="error-contexts-card"
    >
      <.card_section>
        <div data-part="contexts-grid">
          <div :for={{name, data} <- contexts(@payload)} data-part="context-card">
            <div data-part="context-header">
              <span data-part="context-title">{format_context_name(name)}</span>
            </div>
            <div data-part="context-metadata-grid">
              <div :for={{k, v} <- flatten_context(data)} data-part="context-metadata">
                <div data-part="title">{k}</div>
                <span data-part="label">{format_context_value(v)}</span>
              </div>
            </div>
          </div>
        </div>
      </.card_section>
    </.card>

    <.card
      :if={request_data(@payload)}
      title="Request"
      icon="server"
      id="error-request-card"
    >
      <.card_section>
        <.request_panel request={request_data(@payload)} />
      </.card_section>
    </.card>

    <.card
      :if={event_breadcrumbs(@payload) != []}
      title="Breadcrumbs"
      icon="list_tree"
      id="error-breadcrumbs-card"
    >
      <.card_section>
        <div data-part="timeline">
          <div
            :for={crumb <- event_breadcrumbs(@payload)}
            data-part="timeline-item"
            data-level={crumb["level"] || "info"}
          >
            <div data-part="timeline-content">
              <div data-part="timeline-header">
                <.badge
                  label={crumb["category"] || crumb["type"] || "log"}
                  color={level_color(crumb["level"] || "info")}
                  style="light-fill"
                  size="small"
                />
                <span :if={crumb["message"]} data-part="timeline-title">{crumb["message"]}</span>
              </div>
              <pre :if={is_map(crumb["data"]) and map_size(crumb["data"]) > 0} data-part="timeline-data"><code>{format_context_value(crumb["data"])}</code></pre>
            </div>
            <span data-part="timeline-time" title={format_datetime(crumb["timestamp"])}>
              {relative_time(crumb["timestamp"])}
            </span>
          </div>
        </div>
      </.card_section>
    </.card>

    <.card
      :if={extra_pairs(@payload) != []}
      title="Additional data"
      icon="database"
      id="error-extra-card"
    >
      <.card_section>
        <div data-part="context-metadata-grid">
          <div :for={{k, v} <- extra_pairs(@payload)} data-part="context-metadata">
            <div data-part="title">{k}</div>
            <span data-part="label">{format_context_value(v)}</span>
          </div>
        </div>
      </.card_section>
    </.card>

    <.card
      :if={module_pairs(@payload) != []}
      title="Modules"
      icon="package"
      id="error-modules-card"
    >
      <.card_section>
        <div data-part="context-metadata-grid" data-columns="2">
          <div :for={{name, version} <- module_pairs(@payload)} data-part="context-metadata">
            <div data-part="title">{name}</div>
            <span data-part="label">{version}</span>
          </div>
        </div>
      </.card_section>
    </.card>

    <.card
      :if={sdk_info(@payload)}
      title="SDK"
      icon="devices_code"
      id="error-sdk-card"
    >
      <.card_section>
        <.sdk_panel sdk={sdk_info(@payload)} />
      </.card_section>
    </.card>
    """
  end

  attr :request, :map, required: true

  def request_panel(assigns) do
    ~H"""
    <div data-part="request">
      <div :if={@request["method"] || @request["url"]} data-part="request-line">
        <.badge
          label={String.upcase(@request["method"] || "GET")}
          color={http_method_color(@request["method"])}
          style="light-fill"
          size="small"
        />
        <code>{@request["url"]}</code>
      </div>

      <div :if={@request["query_string"] || @request["data"]} data-part="context-metadata-grid">
        <div :if={@request["query_string"]} data-part="context-metadata">
          <div data-part="title">Query string</div>
          <span data-part="label"><code>{@request["query_string"]}</code></span>
        </div>
        <div :if={@request["data"]} data-part="context-metadata">
          <div data-part="title">Body</div>
          <span data-part="label">
            <pre data-part="request-body">{format_context_value(@request["data"])}</pre>
          </span>
        </div>
      </div>

      <div
        :if={is_map(@request["headers"]) and map_size(@request["headers"]) > 0}
        data-part="request-headers"
      >
        <div data-part="request-headers-title">Headers</div>
        <div data-part="context-metadata-grid" data-columns="2">
          <div :for={{k, v} <- Enum.sort(@request["headers"])} data-part="context-metadata">
            <div data-part="title">{k}</div>
            <span data-part="label">{v}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :sdk, :map, required: true

  def sdk_panel(assigns) do
    ~H"""
    <div data-part="context-metadata-grid">
      <div :if={@sdk["name"]} data-part="context-metadata">
        <div data-part="title">Name</div>
        <span data-part="label">{@sdk["name"]}</span>
      </div>
      <div :if={@sdk["version"]} data-part="context-metadata">
        <div data-part="title">Version</div>
        <span data-part="label">{@sdk["version"]}</span>
      </div>
      <div
        :if={is_list(@sdk["integrations"]) and @sdk["integrations"] != []}
        data-part="context-metadata"
      >
        <div data-part="title">Integrations</div>
        <span data-part="label">
          <.badge
            :for={integration <- @sdk["integrations"]}
            label={integration}
            color="focus"
            style="light-fill"
            size="small"
          />
        </span>
      </div>
    </div>
    """
  end

  def present?(value) when is_binary(value) and byte_size(value) > 0, do: true
  def present?(_), do: false

  def normalize_event_id(id) when is_binary(id), do: String.replace(id, "-", "")
  def normalize_event_id(other), do: other |> to_string() |> String.replace("-", "")

  def truncate_title(nil), do: ""

  def truncate_title(title) when is_binary(title) do
    if String.length(title) > 120, do: String.slice(title, 0, 120) <> "…", else: title
  end

  defp as_map(m) when is_map(m), do: m
  defp as_map(_), do: %{}

  defp get(map, key, default) when is_map(map), do: Map.get(map, key, default) || default
  defp get(_, _, default), do: default

  defp context_order(name) do
    case Enum.find_index(@known_contexts, &(&1 == name)) do
      nil -> length(@known_contexts) + :erlang.phash2(name, 1000)
      idx -> idx
    end
  end
end
