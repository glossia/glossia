defmodule GlossiaWeb.TokiLive do
  use GlossiaWeb, :live_view

  import GlossiaWeb.DashboardComponents

  alias Glossia.{LinguisticReviews, Projects, Toki}

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :refresh_toki, 3_000)

    {:ok,
     assign(socket,
       draft: "",
       guidance: "",
       context_scope: "locale",
       error: nil,
       unavailable: false,
       conversation: nil,
       messages: [],
       review: nil,
       source: nil
     )}
  end

  def handle_params(params, _uri, socket) do
    project = Projects.get_project(socket.assigns.account, params["project"])

    unless project, do: raise(Ecto.NoResultsError, queryable: Glossia.Accounts.Project)
    project = %{project | account: socket.assigns.account}

    unless Toki.authorize_project(:toki_read, socket.assigns.current_user, project) == :ok,
      do: raise(Ecto.NoResultsError, queryable: Glossia.Toki.Conversation)

    handle = socket.assigns.handle

    socket =
      assign(socket,
        project: project,
        sidebar_context: :project,
        sidebar_project: project,
        page_title: gettext("Toki"),
        page: page(params["page"]),
        conversation_id: params["id"],
        breadcrumb_items: [
          {project.handle, ~p"/#{handle}/#{project.handle}"},
          {gettext("Toki"), ~p"/#{handle}/#{project.handle}/-/toki"}
        ]
      )

    {:noreply, refresh(socket)}
  end

  def handle_event("new_conversation", _params, socket) do
    case Toki.create_conversation(socket.assigns.current_user, socket.assigns.project, %{
           "id" => Ecto.UUID.generate()
         }) do
      {:ok, %{conversation: conversation}} ->
        {:noreply,
         push_navigate(socket,
           to:
             ~p"/#{socket.assigns.handle}/#{socket.assigns.project.handle}/-/toki/#{conversation.id}"
         )}

      error ->
        {:noreply, fail(socket, error)}
    end
  end

  def handle_event("draft", %{"message" => %{"content" => content}}, socket),
    do: {:noreply, assign(socket, draft: content)}

  def handle_event("guidance_scope", %{"scope" => scope}, socket)
      when scope in ["locale", "project"],
      do: {:noreply, assign(socket, context_scope: scope)}

  def handle_event("guidance", %{"resolution" => params}, socket) do
    {:noreply,
     assign(socket,
       guidance: params["guidance"] || "",
       context_scope: params["context_scope"] || "locale"
     )}
  end

  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    socket = assign(socket, draft: content, error: nil)

    case Toki.send_message(
           socket.assigns.current_user,
           socket.assigns.project,
           socket.assigns.conversation_id,
           %{"id" => Ecto.UUID.generate(), "content" => content}
         ) do
      {:ok, _detail} ->
        {:noreply,
         socket
         |> assign(draft: "")
         |> push_event("toki-draft-saved", %{form: "toki-composer"})
         |> refresh()}

      error ->
        {:noreply, socket |> fail(error) |> refresh()}
    end
  end

  def handle_event("resolve", %{"resolution" => params}, socket) do
    socket =
      assign(socket,
        guidance: params["guidance"] || "",
        context_scope: params["context_scope"] || "locale",
        error: nil
      )

    # Bind approval to the reply the person actually saw. Never look up a newer
    # reply here and silently approve it instead. The domain rechecks under lock.
    reply =
      Enum.find(socket.assigns.messages, fn message ->
        message.id == params["resolution_message_id"] and message.role == "assistant" and
          message.status == "completed" and not is_nil(message.reply_to_id)
      end)

    review = socket.assigns.review

    result =
      if reply && review do
        LinguisticReviews.answer(
          socket.assigns.current_user,
          socket.assigns.project,
          review.translation_session_id,
          review.id,
          %{
            "answer" => reply.content,
            "resolution_message_id" => reply.id,
            "guidance" => socket.assigns.guidance,
            "context_scope" => socket.assigns.context_scope
          }
        )
      else
        {:error, :resolution_outdated}
      end

    case result do
      {:ok, _review} ->
        {:noreply,
         socket
         |> assign(guidance: "")
         |> push_event("toki-draft-saved", %{form: "toki-resolution"})
         |> put_flash(:info, gettext("Decision approved."))
         |> refresh()}

      error ->
        {:noreply, socket |> fail(error) |> refresh()}
    end
  end

  def handle_info(:refresh_toki, socket) do
    Process.send_after(self(), :refresh_toki, 3_000)
    {:noreply, refresh(socket)}
  end

  defp refresh(socket) do
    user = socket.assigns.current_user
    project = socket.assigns.project

    socket =
      assign(socket,
        can_chat: Toki.authorize_project(:toki_write, user, project) == :ok,
        can_resolve: LinguisticReviews.authorize(:translation_write, user, project) == :ok
      )

    if socket.assigns.conversation_id do
      with {:ok, detail} <- Toki.get_conversation(user, project, socket.assigns.conversation_id),
           {:ok, source} <- Toki.conversation_source(user, project, detail.conversation) do
        review =
          if detail.conversation.linguistic_review,
            do: LinguisticReviews.serialize(detail.conversation.linguistic_review)

        latest = List.last(detail.messages)

        resolution =
          if latest && latest.role == "assistant" && latest.status == "completed" &&
               latest.reply_to_id,
             do: latest

        assign(socket,
          unavailable: false,
          conversation: detail.conversation,
          messages: detail.messages,
          review: review,
          source: source,
          resolution: resolution,
          busy: detail.conversation.status in ["queued", "running"],
          closed:
            review &&
              (review.status != "open" || source.status not in ["running", "awaiting_input"])
        )
      else
        _ ->
          assign(socket, unavailable: true, conversation: nil, messages: [], review: nil)
      end
    else
      case Toki.list_conversations(user, project, %{"page" => socket.assigns.page}) do
        {:ok, {conversations, meta}} ->
          assign(socket, conversations: conversations, meta: meta, unavailable: false)

        _ ->
          assign(socket, unavailable: true, conversations: [])
      end
    end
  end

  defp fail(socket, {:error, reason}), do: assign(socket, error: error_message(reason))
  defp fail(socket, _error), do: assign(socket, error: error_message(:unauthorized))

  defp error_message(:conversation_busy),
    do: gettext("Toki is replying. Your draft is saved; wait for the reply and try again.")

  defp error_message(:resolution_outdated),
    do:
      gettext(
        "The discussion changed. Read the latest reply before approving. Your guidance draft is saved."
      )

  defp error_message(reason) when reason in [:stale, :goal_closed, :already_answered],
    do: gettext("This goal is closed or no longer current. Your draft has not been discarded.")

  defp error_message(reason) when reason in [:rate_limited, :too_many_pending],
    do: gettext("Too many pending messages. Please try again later. Your draft is saved.")

  defp error_message(:invalid_context_scope),
    do: gettext("That guidance scope is not available for this goal. Your draft is saved.")

  defp error_message(%Ecto.Changeset{}),
    do:
      gettext(
        "Check your text: messages and guidance must be at most 8,000 characters. Your draft is saved."
      )

  defp error_message(_reason),
    do: gettext("Could not save. Check your access and try again. Your draft is saved.")

  defp page(value) do
    case Integer.parse(value || "1") do
      {number, ""} when number > 0 -> number
      _ -> 1
    end
  end

  defp title(%{title: "New conversation"}), do: gettext("New conversation")
  defp title(conversation), do: conversation.title

  defp status(%{linguistic_review: %{status: "open"}}), do: gettext("Help requested")
  defp status(%{linguistic_review: %{status: "answered"}}), do: gettext("Resolved")
  defp status(%{linguistic_review: %{}}), do: gettext("Closed")
  defp status(%{status: "queued"}), do: gettext("Queued")
  defp status(%{status: "running"}), do: gettext("Toki is replying")
  defp status(%{status: "failed"}), do: gettext("Reply failed")
  defp status(_), do: gettext("Private conversation")

  defp author(%{role: "assistant"}), do: gettext("Toki")
  defp author(%{user: %{name: name}}) when is_binary(name) and name != "", do: name
  defp author(_), do: gettext("Teammate")

  def render(assigns) do
    ~H"""
    <div id="toki-page">
      <.page_header
        title={gettext("Toki")}
        description={
          gettext("Work through translation decisions together, with Toki and your fluent teammates.")
        }
      >
        <:actions>
          <Noora.Button.button
            :if={@can_chat}
            id="new-toki-conversation"
            label={gettext("New private conversation")}
            variant="secondary"
            phx-click="new_conversation"
          />
          <Noora.Button.button
            :if={@conversation_id}
            navigate={~p"/#{@handle}/#{@project.handle}/-/toki"}
            label={gettext("All conversations")}
            variant="secondary"
          />
        </:actions>
      </.page_header>

      <Noora.Alert.alert :if={@error} id="toki-error" status="error" title={@error} role="alert" />
      <Noora.Alert.alert
        :if={@unavailable}
        id="toki-unavailable"
        status="warning"
        title={
          gettext(
            "This conversation is unavailable. It may have been removed or your access changed."
          )
        }
      />

      <%= if !@unavailable && !@conversation_id do %>
        <Noora.Card.card title={gettext("Conversations")} icon="message_circle">
          <Noora.Card.card_section :if={@conversations == []} class="noora-table" data-part="empty">
            <Noora.Table.table_empty_state
              icon="message_circle"
              title={gettext("No conversations yet")}
              subtitle={
                gettext(
                  "Shared translation goals will appear here when help is needed. You can also start a private conversation with Toki."
                )
              }
            />
          </Noora.Card.card_section>
          <Noora.Card.card_section
            :for={conversation <- @conversations}
            id={"toki-thread-#{conversation.id}"}
            data-part="thread"
          >
            <div data-part="thread-copy">
              <.link navigate={~p"/#{@handle}/#{@project.handle}/-/toki/#{conversation.id}"}>
                {title(conversation)}
              </.link>
              <span :if={conversation.linguistic_review} data-part="muted">
                {conversation.linguistic_review.locale} · {conversation.linguistic_review.output_path}
              </span>
            </div>
            <Noora.Tag.tag label={status(conversation)} />
          </Noora.Card.card_section>
          <Noora.Card.card_section :if={@meta.total_pages > 1} data-part="pagination">
            <Noora.Button.button
              :if={@page > 1}
              label={gettext("Previous")}
              variant="secondary"
              patch={~p"/#{@handle}/#{@project.handle}/-/toki?#{%{page: @page - 1}}"}
            />
            <span>{gettext("Page %{page} of %{total}", page: @page, total: @meta.total_pages)}</span>
            <Noora.Button.button
              :if={@page < @meta.total_pages}
              label={gettext("Next")}
              variant="secondary"
              patch={~p"/#{@handle}/#{@project.handle}/-/toki?#{%{page: @page + 1}}"}
            />
          </Noora.Card.card_section>
        </Noora.Card.card>
      <% end %>

      <%= if !@unavailable && @conversation do %>
        <Noora.Card.card
          :if={@review}
          id="toki-goal"
          title={gettext("Translation goal")}
          icon="language"
        >
          <:actions><Noora.Tag.tag label={status(@conversation)} /></:actions>
          <Noora.Card.card_section data-part="goal-context">
            <h2 dir="auto">{@review.question}</h2>
            <span data-part="muted">{@review.locale} · {@review.output_path}</span>
            <p>
              {gettext(
                "Discuss the ambiguity together. When the latest Toki reply captures the final decision, explicitly approve it below."
              )}
            </p>
            <div data-part="participants" aria-label={gettext("Invited fluent teammates")}>
              <span>{gettext("Invited fluent teammates")}</span>
              <Noora.Tag.tag
                :for={person <- @review.participants}
                label={person.name || gettext("Teammate")}
                icon="user"
              />
              <.link navigate={~p"/-/settings/preferences"}>
                {gettext("Manage your fluent languages")}
              </.link>
            </div>
            <details>
              <summary>{gettext("Source and current translation")}</summary>
              <div data-part="excerpts">
                <div>
                  <strong>{gettext("Source")}</strong>
                  <p dir="auto">{@review.source_excerpt}</p>
                </div>
                <div>
                  <strong>{gettext("Translation")}</strong>
                  <p dir="auto">{@review.translation_excerpt}</p>
                </div>
              </div>
            </details>
            <.link navigate={
              ~p"/#{@handle}/#{@project.handle}/-/sessions/#{@review.translation_session_id}"
            }>
              {gettext("View translation")}
            </.link>
            <Noora.Alert.alert
              :if={@closed}
              id="toki-goal-closed"
              status="information"
              title={
                if @review.status == "answered",
                  do: gettext("Decision approved. This discussion is now read-only."),
                  else:
                    gettext("This translation is no longer current. This discussion is read-only.")
              }
            />
            <p :if={@review.answer} data-part="decision" dir="auto">{@review.answer}</p>
            <p :if={@review.guidance} dir="auto">
              {gettext("Reusable guidance")}: {@review.guidance}
            </p>
            <span :if={@review.context_path} data-part="muted">{@review.context_path}</span>
            <.link
              :if={@review.resumed_session_id}
              id="toki-continuation"
              navigate={~p"/#{@handle}/#{@project.handle}/-/sessions/#{@review.resumed_session_id}"}
            >
              {gettext("View continued translation")}
            </.link>
            <span :if={@review.status == "answered" && !@review.resumed_session_id} data-part="muted">
              {gettext(
                "Translation continues after all open goals are resolved and the current run has paused."
              )}
            </span>
          </Noora.Card.card_section>
        </Noora.Card.card>

        <Noora.Card.card id="toki-discussion" title={title(@conversation)} icon="message_circle">
          <Noora.Card.card_section :if={@messages == []} class="noora-table" data-part="empty">
            <Noora.Table.table_empty_state
              icon="message_circle"
              title={gettext("Talk it through with Toki")}
              subtitle={
                gettext("Ask about your project's translations, terminology, or cultural context.")
              }
            />
          </Noora.Card.card_section>
          <div
            id="toki-messages"
            role="log"
            aria-label={gettext("Conversation history")}
            aria-live="polite"
          >
            <Noora.Card.card_section
              :for={message <- @messages}
              id={"toki-message-#{message.id}"}
              data-part="message"
              data-role={message.role}
            >
              <div data-part="message-heading">
                <strong>{author(message)}</strong>
                <time datetime={DateTime.to_iso8601(message.inserted_at)}>
                  {Calendar.strftime(message.inserted_at, "%H:%M")}
                </time>
                <Noora.Tag.tag :if={message.status == "failed"} label={gettext("Reply failed")} />
              </div>
              <p dir="auto">{message.content}</p>
            </Noora.Card.card_section>
          </div>
          <Noora.Card.card_section data-part="composer-section">
            <p :if={@busy} id="toki-busy" role="status">
              {gettext("Toki is replying. You can keep drafting while you wait.")}
            </p>
            <p :if={@conversation.status == "failed"} role="status">
              {gettext("Toki could not finish the reply. Send another message to continue.")}
            </p>
            <p :if={!@can_chat} role="status">
              {gettext("You have read-only access to this conversation.")}
            </p>
            <.form
              for={%{}}
              id="toki-composer"
              data-part="composer"
              phx-hook="TokiDraft"
              data-draft-key={"toki:#{@current_user.id}:#{@project.id}:#{@conversation.id}:message"}
              phx-change="draft"
              phx-submit="send_message"
            >
              <Noora.TextArea.text_area
                id="toki-content"
                name="message[content]"
                value={@draft}
                label={gettext("Message")}
                placeholder={gettext("Work through a decision with Toki…")}
                rows={2}
                max_length={8_000}
                show_character_count={false}
                disabled={!@can_chat || !!@closed}
              />
              <Noora.Button.button
                id="toki-send"
                label={gettext("Send message")}
                type="submit"
                disabled={@busy || !!@closed || !@can_chat || String.trim(@draft) == ""}
              >
                <:icon_left><Noora.Icon.square_rounded_arrow_up /></:icon_left>
              </Noora.Button.button>
            </.form>
            <span data-part="muted">
              {gettext(
                "Text messages only. Attachments and voice input are not available on the web yet."
              )}
            </span>
          </Noora.Card.card_section>
        </Noora.Card.card>

        <Noora.Card.card
          :if={@review}
          id="toki-approval"
          data-draft-empty={@closed && @guidance == ""}
          title={
            if @closed, do: gettext("Your guidance draft"), else: gettext("Approve final decision")
          }
          icon="check"
        >
          <Noora.Card.card_section data-part="approval">
            <p :if={@closed} id="toki-draft-recovery" role="status">
              {gettext(
                "This goal is closed. Your unsaved guidance is kept below so you can copy it. It has not been applied to repository guidance."
              )}
            </p>
            <p :if={!@closed}>
              {gettext(
                "Approval uses the latest completed Toki reply, not the opening question. Continue the discussion if the decision is not ready."
              )}
            </p>
            <p :if={!@closed && !@resolution} data-part="muted">
              {gettext(
                "Discuss the goal with Toki first. A completed reply is required before approval."
              )}
            </p>
            <p
              :if={!@closed && @resolution}
              id="toki-proposed-decision"
              data-part="decision"
              dir="auto"
            >
              {@resolution.content}
            </p>
            <.form
              for={%{}}
              id="toki-resolution"
              phx-hook="TokiDraft"
              data-draft-key={"toki:#{@current_user.id}:#{@project.id}:#{@conversation.id}:guidance"}
              phx-change="guidance"
              phx-submit="resolve"
            >
              <input
                type="hidden"
                name="resolution[resolution_message_id]"
                value={@resolution && @resolution.id}
              />
              <Noora.TextArea.text_area
                id="toki-guidance"
                name="resolution[guidance]"
                value={@guidance}
                label={gettext("Reusable L10N guidance (optional)")}
                hint={
                  gettext(
                    "Separate from this decision. Leave empty to approve without changing repository guidance."
                  )
                }
                max_length={8_000}
                rows={3}
                disabled={!@closed && !@can_resolve}
                {%{readonly: @closed}}
              />
              <Noora.Dropdown.dropdown
                :if={!@closed}
                id="toki-guidance-scope"
                label={
                  if @context_scope == "project",
                    do: gettext("Project guidance"),
                    else: gettext("Locale guidance")
                }
              >
                <Noora.Dropdown.dropdown_item
                  value="locale"
                  label={gettext("Locale guidance")}
                  phx-click="guidance_scope"
                  phx-value-scope="locale"
                />
                <Noora.Dropdown.dropdown_item
                  value="project"
                  label={gettext("Project guidance")}
                  phx-click="guidance_scope"
                  phx-value-scope="project"
                />
              </Noora.Dropdown.dropdown>
              <input type="hidden" name="resolution[context_scope]" value={@context_scope} />
              <Noora.Button.button
                :if={!@closed}
                id="toki-approve"
                type="submit"
                label={gettext("Approve final decision")}
                disabled={!@can_resolve || @busy || is_nil(@resolution)}
              />
              <p :if={!@can_resolve} data-part="muted">
                {gettext("Translation write access is required to approve a decision.")}
              </p>
            </.form>
          </Noora.Card.card_section>
        </Noora.Card.card>
      <% end %>
    </div>
    """
  end
end
