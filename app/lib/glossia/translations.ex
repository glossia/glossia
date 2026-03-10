defmodule Glossia.Translations do
  @moduledoc """
  Context for managing translations.
  """

  import Ecto.Query

  require Logger

  alias Glossia.Repo
  alias Glossia.Accounts.{Account, Project}
  alias Glossia.Translations.Translation

  def list_project_translations(%Project{} = project, params \\ %{}) do
    from(t in Translation, where: t.project_id == ^project.id)
    |> Flop.validate_and_run(params, for: Translation)
  end

  def translations_by_commit_sha(%Project{} = project) do
    from(t in Translation,
      where: t.project_id == ^project.id,
      where: not is_nil(t.commit_sha),
      order_by: [desc: t.inserted_at]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.commit_sha)
  end

  def get_translation!(id) do
    Repo.one!(
      from(t in Translation,
        where: t.id == ^id,
        preload: [:project, :account]
      )
    )
  end

  def get_translation(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, cast_id} ->
        Repo.one(
          from(t in Translation,
            where: t.id == ^cast_id,
            preload: [:project, :account]
          )
        )

      :error ->
        nil
    end
  end

  def get_translation(_), do: nil

  def create_translation(%Account{} = account, %Project{} = project, attrs) do
    %Translation{account_id: account.id, project_id: project.id}
    |> Translation.changeset(attrs)
    |> Repo.insert()
  end

  def update_translation_sandbox_id(%Translation{} = translation, sandbox_id) do
    translation
    |> Ecto.Changeset.change(%{sandbox_id: sandbox_id})
    |> Repo.update()
  end

  def cancel_active_translations(%Project{} = project) do
    translations =
      from(t in Translation,
        where: t.project_id == ^project.id,
        where: t.status in ["pending", "running"]
      )
      |> Repo.all()

    sandbox = Glossia.Sandbox.adapter()

    Enum.each(translations, fn translation ->
      if translation.sandbox_id do
        case sandbox.delete(translation.sandbox_id) do
          :ok ->
            :ok

          {:error, reason} ->
            Logger.warning(
              "Failed to delete sandbox #{translation.sandbox_id}: #{inspect(reason)}"
            )
        end
      end

      {:ok, updated} =
        update_translation_status(translation, "failed",
          error: "Cancelled: superseded by newer commit"
        )

      broadcast_translation_event(updated, :cancelled)
    end)

    {:ok, length(translations)}
  end

  def update_translation_status(%Translation{} = translation, status, opts \\ []) do
    changes = %{status: status}

    changes =
      if status == "running",
        do: Map.put(changes, :started_at, DateTime.utc_now()),
        else: changes

    changes =
      if status in ["completed", "failed"],
        do: Map.put(changes, :completed_at, DateTime.utc_now()),
        else: changes

    changes =
      if opts[:error],
        do: Map.put(changes, :error, opts[:error]),
        else: changes

    changes =
      if opts[:summary],
        do: Map.put(changes, :summary, opts[:summary]),
        else: changes

    changes =
      if status in ["completed", "failed"],
        do: Map.put(changes, :sandbox_id, nil),
        else: changes

    translation
    |> Ecto.Changeset.change(changes)
    |> Repo.update()
  end

  def subscribe_translation_events(%Translation{id: id}) do
    Phoenix.PubSub.subscribe(Glossia.PubSub, "translation:#{id}")
  end

  def broadcast_translation_event(%Translation{id: id} = translation, event) do
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "translation:#{id}",
      {:translation_event, event}
    )

    # Also broadcast to the project-level topic so list pages can refresh
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "translations:project:#{translation.project_id}",
      {:project_translation_updated, translation, event}
    )
  end

  def subscribe_project_translations(%Project{id: id}) do
    Phoenix.PubSub.subscribe(Glossia.PubSub, "translations:project:#{id}")
  end
end
