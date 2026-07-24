defmodule Glossia.Analytics.Smolanalytics do
  @moduledoc """
  Delivers Glossia domain events to smolanalytics without blocking mutation flows.

  Domain-event handling only persists a background job. The job performs the
  network request and relies on Oban for retries, while smolanalytics uses the
  generated event identifier to make repeated delivery idempotent.
  """

  use Oban.Worker, queue: :analytics, max_attempts: 8

  @behaviour Glossia.Events.Handler

  alias Glossia.Events.Event

  require Logger

  @impl Glossia.Events.Handler
  def handle_event(%Event{} = event) do
    if config()[:enabled] do
      event
      |> build_event()
      |> then(&new(%{"event" => &1}))
      |> Oban.insert()
      |> case do
        {:ok, _job} ->
          :ok

        {:error, reason} ->
          Logger.warning("Unable to enqueue analytics event",
            event_name: event.name,
            reason: inspect(reason)
          )

          :ok
      end
    else
      :ok
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event" => event}}) do
    configuration = config()

    request =
      configuration
      |> Keyword.get(:request_options, [])
      |> Glossia.HTTP.new()

    case Req.post(request,
           url: event_url(configuration),
           auth: {:bearer, Keyword.fetch!(configuration, :write_key)},
           json: event,
           retry: false,
           receive_timeout: 5_000
         ) do
      {:ok, %Req.Response{status: status}} when status in 200..299 ->
        :ok

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "smolanalytics returned HTTP #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, Exception.message(reason)}
    end
  end

  @doc false
  def build_event(%Event{} = event) do
    account_id = resource_id(event.account)
    user_id = resource_id(event.user)

    properties =
      %{
        "account_id" => account_id,
        "actor_type" => if(user_id, do: "user", else: "system"),
        "environment" => config()[:environment],
        "resource_id" => event.opts |> Keyword.get(:resource_id) |> property_value(),
        "resource_type" => event.opts |> Keyword.get(:resource_type) |> property_value(),
        "user_id" => user_id,
        "via" => event.opts |> Keyword.get(:via) |> property_value()
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> Map.new()

    %{
      "id" => Ecto.UUID.generate(),
      "name" => event.name,
      "distinct_id" => distinct_id(account_id, user_id),
      "timestamp" => DateTime.to_iso8601(event.occurred_at),
      "properties" => properties
    }
  end

  defp config do
    Application.fetch_env!(:glossia, __MODULE__)
  end

  defp event_url(configuration) do
    configuration
    |> Keyword.fetch!(:url)
    |> String.trim_trailing("/")
    |> Kernel.<>("/v1/events")
  end

  defp distinct_id(_account_id, user_id) when is_binary(user_id), do: "user:#{user_id}"
  defp distinct_id(account_id, nil) when is_binary(account_id), do: "system:account:#{account_id}"

  defp resource_id(%{id: id}) when not is_nil(id), do: to_string(id)
  defp resource_id(_resource), do: nil

  defp property_value(nil), do: nil
  defp property_value(value) when is_atom(value), do: Atom.to_string(value)
  defp property_value(value), do: to_string(value)
end
