defmodule Glossia.Sandboxes do
  @moduledoc """
  Account-scoped ephemeral environments for running Glossia workflows.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Glossia.Accounts.{Account, Project}
  alias Glossia.Repo
  alias Glossia.Sandboxes.{Sandbox, SandboxSession}

  @active_statuses ~w(pending ready terminating)
  @deadline_statuses ~w(pending ready)
  @reap_batch_size 50

  def list_sandboxes(%Account{id: account_id}, params \\ %{}) do
    Sandbox
    |> where(account_id: ^account_id)
    |> preload([:project])
    |> Flop.validate_and_run(params, for: Sandbox)
  end

  def get_sandbox(%Account{id: account_id}, id) when is_binary(id) do
    with {:ok, id} <- Ecto.UUID.cast(id) do
      Sandbox
      |> where(id: ^id, account_id: ^account_id)
      |> preload([:account, :project])
      |> Repo.one()
    else
      :error -> nil
    end
  end

  def get_sandbox(_account, _id), do: nil

  def get_sandbox_by_id(id) when is_binary(id) do
    with {:ok, id} <- Ecto.UUID.cast(id) do
      Sandbox
      |> where(id: ^id)
      |> preload([:account, :project])
      |> Repo.one()
    else
      :error -> nil
    end
  end

  def get_sandbox_by_id(_), do: nil

  def create_sandbox(%Account{} = account, project \\ nil, attrs \\ %{}, opts \\ []) do
    with :ok <- ensure_enabled(),
         :ok <- ensure_project_owner(account, project),
         {:ok, sandbox} <- reserve_sandbox(account, project, attrs) do
      start_reserved_sandbox(sandbox, account, project, opts)
    end
  end

  def destroy_sandbox(%Sandbox{} = sandbox, opts \\ []) do
    adapter = Keyword.get(opts, :adapter, Glossia.Sandbox.adapter())
    reason = Keyword.get(opts, :reason, "destroyed")

    cond do
      sandbox.status == "terminated" ->
        close_open_sessions(sandbox, reason)
        {:ok, sandbox}

      sandbox.status == "failed" ->
        close_open_sessions(sandbox, reason)
        {:ok, sandbox}

      true ->
        with {:ok, terminating} <- update_sandbox(sandbox, %{status: "terminating"}) do
          case adapter.delete(to_string(sandbox.id)) do
            :ok ->
              mark_terminated(terminating, reason)

            {:error, delete_error} when delete_error in [:not_found, "not_found"] ->
              mark_terminated(terminating, reason)

            {:error, delete_error} ->
              mark_delete_retryable(terminating, delete_error)
          end
        end
    end
  end

  def execute_sandbox(sandbox, command, opts \\ [])

  def execute_sandbox(%Sandbox{purpose: "project_setup"}, _command, _opts) do
    {:error, :sandbox_operation_not_allowed}
  end

  def execute_sandbox(%Sandbox{status: "ready"} = sandbox, command, opts)
      when is_binary(command) do
    adapter = Keyword.get(opts, :adapter, Glossia.Sandbox.adapter())

    with {:ok, opts} <- normalize_execute_opts(Keyword.drop(opts, [:adapter])) do
      adapter.execute(to_string(sandbox.id), command, opts)
    end
  end

  def execute_sandbox(%Sandbox{}, _command, _opts), do: {:error, :sandbox_not_ready}

  def read_file(sandbox, path, opts \\ [])

  def read_file(%Sandbox{purpose: "project_setup"}, _path, _opts) do
    {:error, :sandbox_operation_not_allowed}
  end

  def read_file(%Sandbox{status: "ready"} = sandbox, path, opts) when is_binary(path) do
    adapter = Keyword.get(opts, :adapter, Glossia.Sandbox.adapter())
    adapter.download_file(to_string(sandbox.id), path)
  end

  def read_file(%Sandbox{}, _path, _opts), do: {:error, :sandbox_not_ready}

  def write_file(sandbox, path, content, opts \\ [])

  def write_file(%Sandbox{purpose: "project_setup"}, _path, _content, _opts) do
    {:error, :sandbox_operation_not_allowed}
  end

  def write_file(%Sandbox{status: "ready"} = sandbox, path, content, opts)
      when is_binary(path) and is_binary(content) do
    adapter = Keyword.get(opts, :adapter, Glossia.Sandbox.adapter())
    adapter.upload_file(to_string(sandbox.id), path, content)
  end

  def write_file(%Sandbox{}, _path, _content, _opts), do: {:error, :sandbox_not_ready}

  def delete_file(sandbox, path, opts \\ [])

  def delete_file(%Sandbox{purpose: "project_setup"}, _path, _opts) do
    {:error, :sandbox_operation_not_allowed}
  end

  def delete_file(%Sandbox{status: "ready"} = sandbox, path, opts) when is_binary(path) do
    adapter = Keyword.get(opts, :adapter, Glossia.Sandbox.adapter())
    adapter.delete_file(to_string(sandbox.id), path)
  end

  def delete_file(%Sandbox{}, _path, _opts), do: {:error, :sandbox_not_ready}

  def reap_expired_sandboxes(now \\ DateTime.utc_now(), opts \\ []) do
    retry_after_ms =
      Keyword.get(opts, :delete_retry_after_ms, configured(:delete_retry_after_ms, 60_000))

    retry_before = DateTime.add(now, -retry_after_ms, :millisecond)

    now
    |> claim_reapable_sandboxes(retry_before)
    |> Enum.map(&destroy_sandbox(&1, Keyword.put(opts, :reason, "deadline")))
  end

  def mark_failed(%Sandbox{} = sandbox, reason) do
    update_sandbox(sandbox, %{
      status: "failed",
      error: reason,
      terminated_at: DateTime.utc_now()
    })
    |> case do
      {:ok, updated} ->
        close_open_sessions(updated, "failed")
        {:ok, updated}

      error ->
        error
    end
  end

  defp reserve_sandbox(account, project, attrs) do
    now = DateTime.utc_now()
    attrs = normalize_attrs(attrs, project, now)

    Repo.transaction(fn ->
      lock_account!(account)

      with :ok <- enforce_quota(account),
           {:ok, sandbox} <-
             %Sandbox{account_id: account.id, project_id: project && project.id}
             |> Sandbox.changeset(attrs)
             |> Repo.insert() do
        sandbox
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp start_reserved_sandbox(sandbox, account, project, opts) do
    adapter = Keyword.get(opts, :adapter, Glossia.Sandbox.adapter())

    adapter_attrs = %{
      id: to_string(sandbox.id),
      account_id: to_string(account.id),
      project_id: project && to_string(project.id),
      purpose: sandbox.purpose,
      labels: sandbox.labels,
      deadline_at: sandbox.deadline_at
    }

    case adapter.create(adapter_attrs) do
      {:ok, backend_ref} ->
        case mark_ready(sandbox, backend_ref, DateTime.utc_now()) do
          {:ok, ready} ->
            {:ok, ready}

          {:error, reason} ->
            adapter.delete(to_string(sandbox.id))
            {:error, reason}
        end

      {:error, reason} ->
        {:ok, failed} = mark_failed(sandbox, inspect(reason))
        {:error, failed.error}
    end
  end

  defp lock_account!(%Account{id: account_id}) do
    Account
    |> where(id: ^account_id)
    |> lock("FOR UPDATE")
    |> Repo.one!()
  end

  defp mark_ready(sandbox, backend_ref, now) do
    Repo.transaction(fn ->
      {count, _} =
        Sandbox
        |> where(id: ^sandbox.id, status: "pending")
        |> Repo.update_all(
          set: [
            status: "ready",
            backend_ref: to_string(backend_ref),
            ready_at: now,
            updated_at: now
          ]
        )

      if count == 1 do
        %SandboxSession{}
        |> SandboxSession.changeset(%{
          sandbox_id: sandbox.id,
          account_id: sandbox.account_id,
          project_id: sandbox.project_id,
          status: "open",
          opened_at: now
        })
        |> Repo.insert!()

        Sandbox
        |> Repo.get!(sandbox.id)
        |> Repo.preload([:account, :project])
      else
        Repo.rollback(:sandbox_not_pending)
      end
    end)
  end

  defp claim_reapable_sandboxes(now, retry_before) do
    Repo.transaction(fn ->
      ids =
        Sandbox
        |> where(
          [s],
          (s.status in ^@deadline_statuses and not is_nil(s.deadline_at) and
             s.deadline_at <= ^now) or
            (s.status == "terminating" and s.updated_at <= ^retry_before)
        )
        |> order_by([s], asc: s.updated_at)
        |> limit(^@reap_batch_size)
        |> lock("FOR UPDATE SKIP LOCKED")
        |> select([s], s.id)
        |> Repo.all()

      if ids == [] do
        []
      else
        Sandbox
        |> where([s], s.id in ^ids)
        |> Repo.update_all(set: [status: "terminating", updated_at: now])

        Sandbox
        |> where([s], s.id in ^ids)
        |> Repo.all()
      end
    end)
    |> case do
      {:ok, sandboxes} -> sandboxes
      {:error, _reason} -> []
    end
  end

  defp mark_terminated(sandbox, reason) do
    now = DateTime.utc_now()

    Multi.new()
    |> Multi.update(
      :sandbox,
      Sandbox.changeset(sandbox, %{
        status: "terminated",
        terminated_at: now,
        error: nil
      })
    )
    |> Multi.update_all(
      :sessions,
      from(s in SandboxSession, where: s.sandbox_id == ^sandbox.id and s.status == "open"),
      set: [status: "closed", closed_at: now, close_reason: reason, updated_at: now]
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{sandbox: updated}} -> {:ok, updated}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  defp mark_delete_retryable(sandbox, reason) do
    update_sandbox(sandbox, %{status: "terminating", error: inspect(reason)})
    |> case do
      {:ok, _updated} -> {:error, reason}
      error -> error
    end
  end

  defp update_sandbox(sandbox, attrs) do
    sandbox
    |> Sandbox.changeset(attrs)
    |> Repo.update()
  end

  defp close_open_sessions(%Sandbox{} = sandbox, reason) do
    now = DateTime.utc_now()

    SandboxSession
    |> where(sandbox_id: ^sandbox.id, status: "open")
    |> Repo.update_all(
      set: [status: "closed", closed_at: now, close_reason: reason, updated_at: now]
    )
  end

  defp normalize_attrs(attrs, project, now) do
    attrs = stringify_keys(attrs)
    ttl_seconds = configured(:default_ttl_seconds, 3600)

    %{
      "status" => "pending",
      "purpose" => attrs["purpose"] || "manual",
      "backend" => attrs["backend"] || "flame",
      "labels" => attrs["labels"] || %{},
      "deadline_at" => attrs["deadline_at"] || DateTime.add(now, ttl_seconds, :second),
      "project_id" => project && project.id
    }
  end

  defp ensure_enabled do
    if configured(:enabled, true), do: :ok, else: {:error, :sandboxes_disabled}
  end

  defp ensure_project_owner(_account, nil), do: :ok
  defp ensure_project_owner(%Account{id: account_id}, %Project{account_id: account_id}), do: :ok
  defp ensure_project_owner(%Account{}, %Project{}), do: {:error, :project_not_found}

  defp enforce_quota(%Account{id: account_id}) do
    max_active = configured(:max_active_per_account, 3)

    active_count =
      Sandbox
      |> where(account_id: ^account_id)
      |> where([s], s.status in ^@active_statuses)
      |> Repo.aggregate(:count)

    if active_count < max_active do
      :ok
    else
      {:error, :sandbox_quota_exceeded}
    end
  end

  defp normalize_execute_opts(opts) when is_list(opts) do
    case Keyword.get(opts, :timeout_ms) do
      nil ->
        {:ok, Keyword.delete(opts, :timeout_ms)}

      timeout when is_integer(timeout) and timeout > 0 ->
        {:ok, opts}

      timeout when is_float(timeout) and timeout > 0 ->
        {:ok, Keyword.put(opts, :timeout_ms, trunc(timeout))}

      _timeout ->
        {:error, :invalid_timeout}
    end
  end

  defp normalize_execute_opts(_opts), do: {:error, :invalid_options}

  defp configured(key, default) do
    :glossia
    |> Application.get_env(Glossia.Sandbox, [])
    |> Keyword.get(key, default)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(_), do: %{}
end
