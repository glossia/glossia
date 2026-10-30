defmodule GlossiaWeb.EditorLive do
  use GlossiaWeb, :live_view
  import GlossiaWeb.DashboardComponents

  alias Glossia.{Editor, Projects}
  alias Glossia.Editor.Content
  alias Noora.Filter

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       error: nil,
       busy: false,
       file: nil,
       fields: [],
       values: %{},
       dirty: false,
       selected: %{}
     )}
  end

  def handle_params(params, _uri, socket) do
    project = Projects.get_project(socket.assigns.account, params["project"])
    unless project, do: raise(Ecto.NoResultsError, queryable: Glossia.Accounts.Project)
    project = %{project | account: socket.assigns.account}

    unless Editor.authorize(socket.assigns.current_user, project) == :ok,
      do: raise(Ecto.NoResultsError, queryable: Glossia.Editor.File)

    filters = [
      %Filter.Filter{id: "locale", display_name: gettext("Language"), type: :text},
      %Filter.Filter{
        id: "status",
        display_name: gettext("Status"),
        type: :option,
        options: ["Synced", "Draft", "In review", "Conflict", "Missing", "Removed"]
      }
    ]

    socket =
      assign(socket,
        project: project,
        sidebar_project: project,
        sidebar_context: :project,
        page_title: gettext("Editor"),
        params: Map.drop(params, ["handle", "project", "id"]),
        file_id: params["id"],
        search: String.trim(params["search"] || ""),
        sort: if(params["sort"] in ~w(path locale format), do: params["sort"], else: "path"),
        direction: if(params["direction"] == "desc", do: "desc", else: "asc"),
        available_filters: filters,
        active_filters: Filter.Operations.decode_filters_from_query(params, filters),
        breadcrumb_items: [
          {project.handle, ~p"/#{socket.assigns.handle}/#{project.handle}"},
          {gettext("Editor"), ~p"/#{socket.assigns.handle}/#{project.handle}/-/editor"}
        ]
      )

    {:noreply, load(socket)}
  end

  def handle_event("search", %{"search" => search}, socket),
    do: {:noreply, patch(socket, Map.put(socket.assigns.params, "search", search))}

  def handle_event("add_filter", %{"value" => id}, socket) do
    if Enum.any?(socket.assigns.available_filters, &(&1.id == id)) do
      {:noreply,
       patch(socket, Filter.Operations.add_filter_to_query(id, socket, socket.assigns.params))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_filter", params, socket),
    do:
      {:noreply,
       patch(
         socket,
         Filter.Operations.update_filters_in_query(params, socket, socket.assigns.params)
       )}

  def handle_event("change", %{"values" => values} = params, socket) do
    {:noreply,
     socket
     |> assign(
       values: values,
       dirty: values != field_values(socket.assigns.fields),
       form_version: Map.get(params, "version", socket.assigns.form_version)
     )
     |> preview()}
  end

  def handle_event("save", %{"values" => values} = params, socket) do
    f = socket.assigns.file

    result =
      with true <- params["file_id"] == f.id,
           {:ok, version} when is_integer(version) <- Ecto.Type.cast(:integer, params["version"]) do
        Editor.save(socket.assigns.current_user, socket.assigns.project, f.id, version, values)
      else
        _ -> {:error, :stale}
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Draft saved. Nothing has been sent to GitHub."))
         |> load()}

      {:error, reason} ->
        {:noreply, assign(socket, error: error(reason))}
    end
  end

  def handle_event("discard", _, socket) do
    f = socket.assigns.file

    case Editor.discard(socket.assigns.current_user, socket.assigns.project, f.id, f.lock_version) do
      {:ok, _} -> {:noreply, load(socket)}
      {:error, reason} -> {:noreply, assign(socket, error: error(reason))}
    end
  end

  def handle_event("reload", _, socket), do: {:noreply, load(socket)}

  def handle_event("select_file:" <> id, _, socket) do
    file = Enum.find(socket.assigns.files, &(&1.id == id))
    checked = !Map.has_key?(socket.assigns.selected, id)

    selected =
      cond do
        socket.assigns.busy ->
          socket.assigns.selected

        checked && file && publishable?(file) ->
          Map.put(socket.assigns.selected, id, file.lock_version)

        true ->
          Map.delete(socket.assigns.selected, id)
      end

    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event(event, _, socket)
      when event in ["synchronize", "publish", "publish_many", "refresh_review"] do
    if socket.assigns.busy || socket.assigns.dirty do
      {:noreply, socket}
    else
      user = socket.assigns.current_user
      project = socket.assigns.project
      file = socket.assigns.file
      selected = socket.assigns.selected

      {:noreply,
       socket
       |> assign(busy: true, error: nil)
       |> start_async(:repository_action, fn ->
         case event do
           "synchronize" ->
             Editor.synchronize(user, project)

           "publish" ->
             Editor.publish(user, project, file.id, file.lock_version)

           "publish_many" ->
             Editor.publish_many(user, project, selected)

           "refresh_review" ->
             with {:ok, _} <- Editor.refresh_review(user, project, file.id),
                  do: Editor.synchronize(user, project)
         end
       end)}
    end
  end

  def handle_async(:repository_action, {:ok, result}, socket) do
    socket = socket |> assign(busy: false) |> load()

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(selected: %{})
         |> put_flash(:info, gettext("Repository action completed."))}

      {:error, reason} ->
        {:noreply, assign(socket, error: error(reason))}
    end
  end

  def handle_async(:repository_action, {:exit, _}, socket),
    do:
      {:noreply,
       socket |> assign(busy: false) |> load() |> assign(error: error(:repository_unavailable))}

  defp patch(socket, params),
    do:
      push_patch(socket,
        to: ~p"/#{socket.assigns.handle}/#{socket.assigns.project.handle}/-/editor?#{params}"
      )

  defp load(socket) do
    {:ok, files} = Editor.list_files(socket.assigns.current_user, socket.assigns.project)
    file = if socket.assigns.file_id, do: Enum.find(files, &(&1.id == socket.assigns.file_id))

    if socket.assigns.file_id && !file,
      do: raise(Ecto.NoResultsError, queryable: Glossia.Editor.File)

    source = file && Enum.find(files, &(&1.path == file.source_path && &1.path != file.path))

    result =
      if file,
        do: Content.fields(file.format, file.draft_content || file.content),
        else: {:ok, []}

    {fields, content_error} =
      case result do
        {:ok, fields} -> {fields, nil}
        {:error, reason} -> {[], error(reason)}
      end

    source_fields =
      case source && Content.fields(source.format, source.content) do
        {:ok, fields} -> Map.new(fields, &{&1.id, &1.value})
        _ -> %{}
      end

    socket
    |> assign(
      files: files,
      rows: filter_files(files, socket.assigns),
      search_results: search_results(files, socket.assigns),
      drafts: Enum.filter(files, &publishable?/1),
      file: file,
      form_version: file && file.lock_version,
      fields: fields,
      source: source,
      source_fields: source_fields,
      values: field_values(fields),
      dirty: false,
      error: content_error,
      content_error: content_error,
      editable:
        file && file.active && !file.conflict && is_nil(file.branch) && is_nil(content_error)
    )
    |> preview()
  end

  defp field_values(fields), do: Map.new(fields, &{&1.id, &1.value})

  defp field_dom_id(id), do: "editor-field-#{Base.url_encode64(id, padding: false)}"

  defp result_path(assigns, result) do
    ~p"/#{assigns.handle}/#{assigns.project.handle}/-/editor/#{result.file.id}"
    |> URI.parse()
    |> Map.put(:fragment, field_dom_id(result.field.id))
    |> URI.to_string()
  end

  defp publishable?(file),
    do: file.active && !file.conflict && is_nil(file.branch) && !is_nil(file.draft_content)

  defp field_label(label) do
    label
    |> String.trim_leading("$.")
    |> String.split(".")
    |> Enum.map(&Phoenix.Naming.humanize/1)
    |> Enum.join(" › ")
  end

  defp preview(socket) do
    body = Enum.find(socket.assigns.fields, &(&1.label == "Body"))
    value = if body, do: socket.assigns.values[body.id], else: ""

    assign(socket, preview: markdown_html(value))
  end

  defp markdown_html(value) do
    case Glossia.Markdown.to_html(value || "", render: [unsafe: false]) do
      {:ok, html} -> html
      _ -> ""
    end
  end

  defp search_results(_files, %{search: ""}), do: []

  defp search_results(files, assigns) do
    query = Regex.compile!(Regex.escape(assigns.search), "iu")

    files
    |> filter_files(assigns)
    |> Stream.flat_map(fn file ->
      case Content.fields(file.format, file.draft_content || file.content) do
        {:ok, fields} ->
          for field <- fields, [{start, _}] <- [Regex.run(query, field.value, return: :index)] do
            # Locate the match in the original Unicode string for a useful
            # excerpt even when the matching phrase is far into a long body.
            before = field.value |> binary_part(0, start) |> String.slice(-60, 60)

            after_match =
              field.value
              |> binary_part(start, byte_size(field.value) - start)
              |> String.slice(0, 180)

            excerpt = String.replace(before <> after_match, ~r/\s+/u, " ")
            %{id: file.id <> field.id, file: file, field: field, excerpt: excerpt}
          end

        _ ->
          []
      end
    end)
    |> Enum.take(200)
  end

  defp filter_files(files, assigns) do
    files
    |> Enum.filter(fn file ->
      Enum.all?(assigns.active_filters, fn filter ->
        actual = if filter.id == "status", do: status(file), else: file.locale
        value = to_string(filter.value || "")

        case filter.operator do
          :!= -> actual != value
          :=~ -> String.contains?(String.downcase(actual), String.downcase(value))
          :"!=~" -> !String.contains?(String.downcase(actual), String.downcase(value))
          _ -> value == "" || actual == value
        end
      end)
    end)
    |> Enum.sort_by(
      &Map.fetch!(&1, String.to_existing_atom(assigns.sort)),
      if(assigns.direction == "desc", do: :desc, else: :asc)
    )
  end

  defp sort_path(assigns, field) do
    params =
      Map.merge(assigns.params, %{
        "sort" => field,
        "direction" =>
          if(assigns.sort == field && assigns.direction == "asc", do: "desc", else: "asc")
      })

    ~p"/#{assigns.handle}/#{assigns.project.handle}/-/editor?#{params}"
  end

  defp status(%{active: false}), do: "Removed"
  defp status(%{pull_request_url: url}) when not is_nil(url), do: "In review"
  defp status(%{conflict: true}), do: "Conflict"
  defp status(%{draft_content: draft}) when not is_nil(draft), do: "Draft"
  defp status(%{blob_sha: nil}), do: "Missing"
  defp status(_), do: "Synced"

  defp error(:stale),
    do: gettext("Someone changed this draft. Copy your edits, then reload before saving.")

  defp error(:repository_changed),
    do:
      gettext(
        "The repository file changed. Your draft is safe. Discard it and sync to load the latest version."
      )

  defp error(:publication_pending),
    do:
      gettext(
        "This draft is frozen for publication. Retry the pull request or check its review status."
      )

  defp error(:repository_not_connected),
    do: gettext("Connect this project to a GitHub repository first.")

  defp error(:not_configured), do: gettext("GitHub is not configured on this instance.")

  defp error(:review_open),
    do:
      gettext("The pull request is still open. Merge or close it in GitHub before editing again.")

  defp error(:unsupported_file),
    do:
      gettext(
        "A configured file is too large, binary, or not a regular file. The editor supports text files up to 1 MB."
      )

  defp error(:too_many_files),
    do: gettext("This repository exceeds the editor limit of 2,000 configured files.")

  defp error(reason) when is_binary(reason), do: reason

  defp error(_),
    do:
      gettext(
        "This action could not be completed safely. Your draft has been kept. Check the repository connection and try again."
      )

  def render(assigns) do
    ~H"""
    <div id="editor-page" data-view={if @file, do: "file", else: "list"}>
      <.page_header
        title={gettext("Editor")}
        description={gettext("Shape your content. Keep your repository as the source of truth.")}
      >
        <:actions>
          <Noora.Button.button
            :if={@file}
            label={gettext("All files")}
            variant="secondary"
            navigate={~p"/#{@handle}/#{@project.handle}/-/editor"}
            data-confirm={if @dirty, do: gettext("Leave without saving these edits?")}
          />
          <Noora.Button.button
            id="editor-sync"
            label={if @busy, do: gettext("Working…"), else: gettext("Sync repository")}
            variant="secondary"
            phx-click="synchronize"
            disabled={@busy || @dirty}
          />
        </:actions>
      </.page_header>

      <Noora.Alert.alert :if={@error} id="editor-error" status="error" title={@error} role="alert">
        <:action>
          <Noora.Button.button
            label={gettext("Reload")}
            variant="secondary"
            phx-click="reload"
            data-confirm={gettext("Reload and replace any unsaved edits?")}
          />
        </:action>
      </Noora.Alert.alert>

      <%= if @file do %>
        <Noora.Card.card icon="file_text" title={@file.path}>
          <:actions><Noora.Tag.tag label={status(@file)} /></:actions>
          <Noora.Card.card_section data-part="document-meta">
            <span>{String.upcase(@file.format)} · {@file.locale}</span>
            <span :if={@source}>{gettext("Source:")} {@source.path} · {@source.locale}</span>
            <span :if={!@file.blob_sha}>
              {gettext("Not in the repository yet. Start from the source content.")}
            </span>
          </Noora.Card.card_section>
          <Noora.Card.card_section :if={@file.pull_request_url} data-part="review">
            <Noora.Alert.alert
              status="success"
              title={
                gettext(
                  "Your edit is ready for review. Merge the pull request to update the repository."
                )
              }
            />
            <Noora.Button.button
              label={gettext("View pull request")}
              href={@file.pull_request_url}
              variant="secondary"
              target="_blank"
              rel="noopener noreferrer"
            />
            <Noora.Button.button
              label={gettext("Check review status")}
              phx-click="refresh_review"
              variant="secondary"
              disabled={@busy}
            />
          </Noora.Card.card_section>
          <Noora.Card.card_section :if={@file.branch && !@file.pull_request_url}>
            <Noora.Alert.alert
              status="warning"
              title={
                gettext(
                  "Publication started. The draft is frozen; retry to recover the same pull request, not create a duplicate."
                )
              }
            />
          </Noora.Card.card_section>
          <Noora.Card.card_section
            :if={@fields == [] && !@content_error}
            class="noora-table"
            data-part="empty"
          >
            <Noora.Table.table_empty_state
              icon="file_text"
              title={gettext("No editable text")}
              subtitle={
                gettext(
                  "This file contains no text fields. Numbers, flags, and structure stay managed in the repository."
                )
              }
            />
          </Noora.Card.card_section>
          <.form
            :if={@fields != []}
            for={%{}}
            id="editor-form"
            phx-change="change"
            phx-submit="save"
            phx-hook="ContentEditor"
            data-dirty={to_string(@dirty)}
            data-preview={@preview}
            data-leave-confirm={gettext("Leave without saving these edits?")}
          >
            <input type="hidden" name="file_id" value={@file.id} />
            <input type="hidden" name="version" value={@form_version} />
            <Noora.Card.card_section :if={@file.format == "markdown"} data-part="formatting">
              <Noora.Button.button
                :for={
                  {format, label} <- [
                    {"paragraph", gettext("Text")},
                    {"heading", gettext("Heading")},
                    {"bold", gettext("Bold")},
                    {"italic", gettext("Italic")},
                    {"list", gettext("List")},
                    {"ordered", gettext("Numbered list")},
                    {"quote", gettext("Quote")},
                    {"link", gettext("Link")},
                    {"undo", gettext("Undo")},
                    {"redo", gettext("Redo")}
                  ]
                }
                label={label}
                type="button"
                variant="secondary"
                data-format={format}
                disabled={!@editable || @busy}
              />
            </Noora.Card.card_section>
            <Noora.Card.card_section
              :if={@file.format == "markdown"}
              id="editor-link-controls"
              data-part="link-controls"
              phx-update="ignore"
              hidden
              data-invalid-url={gettext("Enter a valid https, http, or mailto link.")}
            >
              <Noora.TextInput.text_input
                id="editor-link-url"
                name="link_url"
                label={gettext("Link URL")}
                type="basic"
              />
              <Noora.Button.button
                type="button"
                label={gettext("Apply link")}
                data-format="apply_link"
                variant="secondary"
              />
              <Noora.Button.button
                type="button"
                label={gettext("Remove link")}
                data-format="remove_link"
                variant="secondary"
              />
            </Noora.Card.card_section>
            <Noora.Card.card_section data-part="fields">
              <div
                :for={field <- @fields}
                data-part="field-row"
                data-body={@file.format == "markdown" && field.label == "Body"}
              >
                <div :if={Map.has_key?(@source_fields, field.id)} data-part="source">
                  <Noora.Label.label label={
                    gettext("Source · %{label}", label: field_label(field.label))
                  } />
                  <%= if @file.format == "markdown" && field.id == "body" do %>
                    <article class="prose" dir="auto">
                      {raw(markdown_html(@source_fields[field.id]))}
                    </article>
                  <% else %>
                    <p dir="auto">{@source_fields[field.id]}</p>
                  <% end %>
                </div>
                <%= if @file.format == "markdown" && field.id == "body" do %>
                  <input
                    type="hidden"
                    id="editor-body"
                    name="values[body]"
                    value={@values[field.id]}
                    disabled={!@editable || @busy}
                  />
                  <div id={field_dom_id(field.id)} data-part="visual-editor" phx-update="ignore">
                    <Noora.Label.label label={gettext("Body")} />
                    <div data-part="visual-warning" hidden>
                      <Noora.Alert.alert
                        status="warning"
                        title={
                          gettext(
                            "This document uses formatting the visual editor cannot safely preserve, such as embedded HTML, entities, or footnotes. Its body is read-only. You can still edit the text fields above."
                          )
                        }
                      />
                    </div>
                    <div data-part="visual-surface" data-label={gettext("Body")}></div>
                    <article id="editor-preview" data-part="visual-fallback" class="prose" dir="auto">
                      {raw(@preview)}
                    </article>
                  </div>
                <% else %>
                  <Noora.TextArea.text_area
                    id={field_dom_id(field.id)}
                    name={"values[#{field.id}]"}
                    label={field_label(field.label)}
                    value={@values[field.id]}
                    rows={if @file.format == "markdown", do: 1, else: 3}
                    max_length={1_000_000}
                    show_character_count={false}
                    disabled={!@editable || @busy}
                    aria-label={field_label(field.label)}
                    phx-debounce="250"
                    dir="auto"
                  />
                <% end %>
              </div>
            </Noora.Card.card_section>
            <Noora.Card.card_section data-part="save-bar">
              <div data-part="save-status">
                <strong>
                  {if @dirty,
                    do: gettext("Unsaved changes"),
                    else:
                      if(@file.draft_content, do: gettext("Draft saved"), else: gettext("Up to date"))}
                </strong>
                <span>
                  {gettext("Save here first. Review this file or group saved changes from All files.")}
                </span>
              </div>
              <Noora.Button.button
                :if={@file.draft_content && !@file.branch}
                label={gettext("Discard draft")}
                type="button"
                variant="secondary"
                phx-click="discard"
                disabled={@busy}
                data-confirm={gettext("Discard the saved draft? This cannot be undone.")}
              />
              <Noora.Button.button
                id="editor-save"
                label={gettext("Save draft")}
                type="submit"
                variant="secondary"
                disabled={!@editable || !@dirty || @busy}
              />
              <Noora.Button.button
                :if={!@file.pull_request_url}
                id="editor-publish"
                type="button"
                label={
                  if @file.branch,
                    do: gettext("Retry pull request"),
                    else: gettext("Create pull request")
                }
                phx-click="publish"
                disabled={
                  @dirty || @busy || !@file.draft_content ||
                    (is_nil(@file.branch) && (@file.conflict || !@file.active))
                }
                data-confirm={
                  gettext("Create a GitHub pull request with the saved changes to this file?")
                }
              />
            </Noora.Card.card_section>
          </.form>
        </Noora.Card.card>
      <% else %>
        <Noora.Card.card
          :if={@drafts != []}
          icon="file_text"
          title={gettext("Review saved changes")}
        >
          <:actions>
            <Noora.Tag.tag label={gettext("%{count} selected", count: map_size(@selected))} />
          </:actions>
          <Noora.Card.card_section data-part="draft-selection">
            <p>
              {gettext(
                "Choose the saved drafts to include together in one pull request. Unselected files stay untouched."
              )}
            </p>
            <div :for={file <- @drafts} data-part="draft-option">
              <Noora.Button.button
                id={"editor-select-#{file.id}"}
                label={file.path}
                variant="secondary"
                aria-pressed={to_string(Map.has_key?(@selected, file.id))}
                phx-click={"select_file:#{file.id}"}
                disabled={@busy}
              >
                <:icon_left>
                  <Noora.Icon.icon name={
                    if Map.has_key?(@selected, file.id), do: "check", else: "plus"
                  } />
                </:icon_left>
              </Noora.Button.button>
              <Noora.Button.button
                label={gettext("Edit")}
                variant="secondary"
                navigate={~p"/#{@handle}/#{@project.handle}/-/editor/#{file.id}"}
              />
            </div>
          </Noora.Card.card_section>
          <Noora.Card.card_section data-part="batch-actions">
            <Noora.Button.button
              id="editor-publish-many"
              label={gettext("Create pull request (%{count} files)", count: map_size(@selected))}
              phx-click="publish_many"
              disabled={@busy || map_size(@selected) == 0}
              data-confirm={
                gettext("Create one GitHub pull request with these %{count} saved files?",
                  count: map_size(@selected)
                )
              }
            />
          </Noora.Card.card_section>
        </Noora.Card.card>
        <Noora.Card.card icon="folders" title={gettext("Repository content")}>
          <:actions>
            <span data-part="muted">{length(@files)} {gettext("files tracked")}</span>
          </:actions>
          <Noora.Card.card_section data-part="toolbar">
            <.form for={%{}} phx-change="search">
              <Noora.TextInput.text_input
                id="editor-search"
                name="search"
                type="search"
                value={@search}
                placeholder={gettext("Search the text in your content…")}
                phx-debounce="300"
                show_suffix={false}
              />
            </.form>
            <Noora.Filter.filter_dropdown
              id="editor-filters"
              available_filters={@available_filters}
              active_filters={@active_filters}
            />
            <Noora.Filter.active_filter :for={filter <- @active_filters} filter={filter} />
          </Noora.Card.card_section>
          <Noora.Card.card_section :if={@search != ""} data-part="search-summary">
            <p>
              {gettext("%{count} matching text fields. Search includes source text and saved drafts.",
                count: length(@search_results)
              )}
            </p>
            <p :if={length(@search_results) == 200}>
              {gettext("Showing the first 200 matches. Refine your search to find a specific phrase.")}
            </p>
          </Noora.Card.card_section>
          <Noora.Card.card_section data-part="file-list">
            <Noora.Table.table
              :if={@search != ""}
              id="editor-search-results"
              rows={@search_results}
              row_key={& &1.id}
              row_navigate={fn result -> result_path(assigns, result) end}
            >
              <:col :let={result} label={gettext("Matching text")}>
                <Noora.Table.text_cell
                  label={result.excerpt}
                  sublabel={field_label(result.field.label)}
                />
              </:col>
              <:col :let={result} label={gettext("Language")}>
                <Noora.Table.text_cell label={result.file.locale} />
              </:col>
              <:col :let={result} label={gettext("Location")}>
                <Noora.Table.text_cell label={result.file.path} sublabel={status(result.file)} />
              </:col>
              <:empty_state>
                <Noora.Table.table_empty_state
                  icon="search"
                  title={gettext("No matching text")}
                  subtitle={
                    gettext("Try another word or phrase, or remove a language or status filter.")
                  }
                />
              </:empty_state>
            </Noora.Table.table>
            <Noora.Table.table
              :if={@search == ""}
              id="editor-files"
              rows={@rows}
              row_key={& &1.id}
              row_navigate={fn file -> ~p"/#{@handle}/#{@project.handle}/-/editor/#{file.id}" end}
            >
              <:col
                :let={file}
                label={gettext("File")}
                patch={sort_path(assigns, "path")}
                sort_order={if @sort == "path", do: @direction}
              >
                <Noora.Table.text_cell
                  label={file.path}
                  sublabel={
                    if file.path == file.source_path, do: gettext("Source"), else: file.source_path
                  }
                  icon="file_text"
                />
              </:col>
              <:col
                :let={file}
                label={gettext("Language")}
                patch={sort_path(assigns, "locale")}
                sort_order={if @sort == "locale", do: @direction}
              >
                <Noora.Table.text_cell label={file.locale} />
              </:col>
              <:col
                :let={file}
                label={gettext("Format")}
                patch={sort_path(assigns, "format")}
                sort_order={if @sort == "format", do: @direction}
              >
                <Noora.Table.text_cell label={String.upcase(file.format)} />
              </:col>
              <:col :let={file} label={gettext("Status")}>
                <Noora.Table.text_cell label={status(file)} />
              </:col>
              <:empty_state>
                <Noora.Table.table_empty_state
                  icon="folders"
                  title={
                    if @files == [],
                      do: gettext("Your content starts here"),
                      else: gettext("No matching files")
                  }
                  subtitle={
                    if @files == [],
                      do:
                        gettext(
                          "Sync your repository to discover the sources and translations configured in L10N.md. Markdown, JSON, YAML, and text are supported."
                        ),
                      else: gettext("Try a different search or remove a filter.")
                  }
                />
              </:empty_state>
            </Noora.Table.table>
          </Noora.Card.card_section>
        </Noora.Card.card>
        <p data-part="muted">
          {gettext(
            "Drafts are shared with your project team. Nothing reaches GitHub until you create a pull request."
          )}
        </p>
      <% end %>
    </div>
    """
  end
end
