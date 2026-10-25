defmodule GlossiaWeb.TranslationChannel do
  @moduledoc "Authorized native translation snapshots over the existing cross-node session PubSub."
  use Phoenix.Channel, log_join: false, log_handle_in: false

  alias Glossia.{Accounts, Authz, Projects, TranslationSessions}
  alias Glossia.TranslationSessions.Progress
  alias GlossiaWeb.Plugs.BearerAuth
  alias GlossiaWeb.TranslationSnapshot

  @renew_ms 5_000
  @coalesce_ms 100

  @impl true
  def join("translation:" <> id, %{"organization" => organization, "project" => project}, socket)
      when is_binary(organization) and is_binary(project) do
    socket = assign(socket, session_id: id, organization: organization, project: project)

    with {:ok, session} <- authorize(socket),
         :ok <- TranslationSessions.subscribe_session_events(session),
         progress <- TranslationSessions.session_progress(session.id),
         {:ok, session} <- authorize(socket),
         {:ok, snapshot} <-
           TranslationSnapshot.bounded(
             TranslationSnapshot.project(session, progress, progress.seq)
           ) do
      Process.send_after(self(), :renew, @renew_ms)

      {:ok, snapshot, assign(socket, progress: progress, snapshot: snapshot, flush_timer: nil)}
    else
      {:error, reason} -> {:error, %{reason: reason}}
    end
  end

  def join(_topic, _payload, _socket), do: {:error, %{reason: "not_found"}}

  @impl true
  def handle_in(_event, _payload, socket),
    do: {:reply, {:error, %{reason: "unsupported"}}, socket}

  @impl true
  def handle_info({:translation_session_event, event}, socket) do
    # Only application-owned milestones reach the fold. Native clients don't
    # need streamed text, thinking, raw failure details, or provider metadata.
    progress =
      cond do
        Progress.durable_event?(event) ->
          Progress.apply_event(socket.assigns.progress, Map.delete(event, :output_preview))

        match?(%{type: "item_event", event: %{type: "turn_start"}}, event) ->
          Progress.apply_event(socket.assigns.progress, event)

        true ->
          socket.assigns.progress
      end

    if progress != socket.assigns.progress,
      do: {:noreply, socket |> assign(:progress, progress) |> schedule_snapshot()},
      else: {:noreply, socket}
  end

  def handle_info({:translation_session_status, _status}, socket),
    do: {:noreply, schedule_snapshot(socket)}

  def handle_info({:translation_session_publication, _session}, socket),
    do: {:noreply, schedule_snapshot(socket)}

  def handle_info(:flush_snapshot, socket) do
    socket = assign(socket, :flush_timer, nil)

    with {:ok, session} <- authorize(socket),
         seq <- TranslationSessions.max_progress_seq(session.id),
         {:ok, session} <- authorize(socket),
         {:ok, snapshot} <-
           TranslationSnapshot.bounded(
             TranslationSnapshot.project(session, socket.assigns.progress, seq)
           ) do
      push(socket, "snapshot", snapshot)
      {:noreply, assign(socket, :snapshot, snapshot)}
    else
      {:error, reason} -> deny(socket, reason)
    end
  end

  # This lease also heals missed PubSub deliveries from the authoritative
  # durable fold. Transient call counts may reset; output is never retained.
  def handle_info(:renew, socket) do
    with {:ok, session} <- authorize(socket),
         progress <- TranslationSessions.session_progress(session.id),
         {:ok, session} <- authorize(socket),
         {:ok, snapshot} <-
           TranslationSnapshot.bounded(
             TranslationSnapshot.project(session, progress, progress.seq)
           ) do
      if snapshot != socket.assigns.snapshot, do: push(socket, "snapshot", snapshot)
      Process.send_after(self(), :renew, @renew_ms)
      {:noreply, assign(socket, progress: progress, snapshot: snapshot)}
    else
      {:error, reason} -> deny(socket, reason)
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp schedule_snapshot(%{assigns: %{flush_timer: nil}} = socket),
    do: assign(socket, :flush_timer, Process.send_after(self(), :flush_snapshot, @coalesce_ms))

  defp schedule_snapshot(socket), do: socket

  defp authorize(socket) do
    %{credential: credential, organization: organization, project: project, session_id: id} =
      socket.assigns

    with {:ok, user, scopes, _grant} <- authenticate(credential.value),
         {:ok, account} <- found(Accounts.get_account_by_handle(organization)),
         :ok <- permitted(Authz.authorize(:translation_read, user, account, scopes: scopes)),
         :ok <- permitted(Authz.authorize(:project_read, user, account)),
         {:ok, project} <- found(Projects.get_project(account, project)),
         {:ok, session} <- found(TranslationSessions.get_project_session(project, id)) do
      {:ok, session}
    end
  end

  defp authenticate(value) do
    case BearerAuth.verify(value) do
      {:ok, _, _, _} = result -> result
      :error -> {:error, "sign_in_required"}
    end
  end

  defp found(nil), do: {:error, "not_found"}
  defp found(resource), do: {:ok, resource}
  defp permitted(:ok), do: :ok
  defp permitted(_), do: {:error, "forbidden"}

  defp deny(socket, "payload_too_large" = reason) do
    push(socket, "error", %{reason: reason})
    {:stop, :normal, socket}
  end

  defp deny(socket, reason) do
    push(socket, "access_revoked", %{reason: reason})
    {:stop, :normal, socket}
  end
end
