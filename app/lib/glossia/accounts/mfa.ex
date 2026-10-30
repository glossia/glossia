defmodule Glossia.Accounts.MFA do
  @moduledoc """
  Personal authenticator MFA, single-use recovery, and revocable browser sessions.

  All credential issuance and factor mutations serialize on the user row. Failures
  commit their shared attempt budget; successful proof and session issuance commit
  together. Existing cookie-only sessions remain valid only until a factor changes.
  """
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Glossia.Accounts.{BrowserSession, User}
  alias Glossia.{Accounts, Repo}

  @primary_key false
  @foreign_key_type Uniq.UUID
  schema "user_factors" do
    belongs_to :user, User, primary_key: true
    field :secret, Glossia.Encrypted.Binary, redact: true
    field :confirmed_at, :utc_datetime_usec
    field :enrollment_token_hash, :binary, redact: true
    field :enrollment_expires_at, :utc_datetime_usec
    field :last_used_step, :integer
    field :recovery_hashes, {:array, :binary}, default: [], redact: true
    field :failed_attempts, :integer, default: 0
    field :attempt_window_started_at, :utc_datetime_usec
  end

  def enabled?(user), do: match?(%{confirmed_at: %DateTime{}}, Repo.get(__MODULE__, user.id))

  def enabled_user_ids(users) do
    ids = Enum.map(users, & &1.id)

    Repo.all(
      from f in __MODULE__,
        where: f.user_id in ^ids and not is_nil(f.confirmed_at),
        select: f.user_id
    )
    |> MapSet.new()
  end

  def recently_authenticated?(user, token), do: recent?(user, token)

  def organization_proof(token) do
    case lookup(token, "session") do
      %BrowserSession{organization_sso: proof} -> proof
      nil -> nil
    end
  end

  def sign_in(user, organization_sso \\ nil) do
    locked(user.id, fn current ->
      context = if enabled?(current), do: "challenge", else: "session"
      {context, issue(current, context, organization_sso, false)}
    end)
  end

  def session_user(nil, _token), do: nil

  def session_user(user_id, token) do
    case Accounts.get_user(user_id) do
      nil -> nil
      user -> if authorized?(user, token), do: user
    end
  end

  def authorized?(user, nil) do
    # Reload: callers may hold a User loaded before factor enrollment.
    match?(%User{authentication_version: 0}, Repo.get(User, user.id)) and not enabled?(user)
  end

  def authorized?(user, token) do
    case session(user.id, token, "session") do
      nil -> false
      session -> not enabled?(user) or not is_nil(session.mfa_verified_at)
    end
  end

  def challenge(token) do
    with %BrowserSession{} = session <- lookup(token, "challenge"),
         %User{} = user <- Repo.get(User, session.user_id),
         true <- session.authentication_version == user.authentication_version do
      Accounts.get_user(user.id)
    else
      _ -> nil
    end
  end

  def complete(token, code, recovery? \\ false) do
    case challenge(token) do
      nil ->
        {:error, :expired}

      user ->
        locked(user.id, fn current ->
          with %BrowserSession{} = pending <- session(current.id, token, "challenge"),
               %__MODULE__{confirmed_at: %DateTime{}} = factor <- Repo.get(__MODULE__, current.id),
               :ok <- verify(factor, code, recovery?) do
            Repo.delete!(pending)

            {:ok, Accounts.get_user(current.id),
             issue(current, "session", pending.organization_sso, true)}
          else
            {:error, reason} -> {:error, reason}
            _ -> {:error, :expired}
          end
        end)
    end
  end

  def begin_enrollment(user, token) do
    locked(user.id, fn current ->
      factor = Repo.get(__MODULE__, current.id)

      cond do
        not recent?(current, token) ->
          {:error, :reauthenticate}

        factor && factor.confirmed_at ->
          {:error, :already_enabled}

        pending?(factor, token) ->
          {:ok, factor}

        true ->
          factor =
            (factor || %__MODULE__{user_id: current.id})
            |> change(
              secret: NimbleTOTP.secret(),
              enrollment_token_hash: hash(token),
              enrollment_expires_at: DateTime.add(now(), 300)
            )
            |> Repo.insert_or_update!()

          {:ok, factor}
      end
    end)
  end

  def pending(user, token) do
    factor = Repo.get(__MODULE__, user.id)
    if pending?(factor, token), do: factor
  end

  def confirm(user, token, code) do
    locked(user.id, fn current ->
      factor = pending(current, token)

      with true <- recent?(current, token),
           %__MODULE__{} <- factor,
           :ok <- verify(factor, code, false) do
        codes = recovery_codes()
        factor = Repo.get!(__MODULE__, current.id)

        factor
        |> change(confirmed_at: now(), recovery_hashes: Enum.map(codes, &hash/1))
        |> Repo.update!()

        replacement = rotate(current, token, true)
        audit(current, "user.mfa_enabled", "Enabled two-factor authentication")
        {:ok, codes, replacement}
      else
        {:error, reason} -> {:error, reason}
        _ -> {:error, :reauthenticate}
      end
    end)
  end

  def cancel(user, token) do
    locked(user.id, fn current ->
      if factor = pending(current, token), do: Repo.delete!(factor)
      :ok
    end)
  end

  def manage(user, token, code, recovery?, action) when action in [:disable, :regenerate] do
    locked(user.id, fn current ->
      with true <- recent?(current, token),
           %__MODULE__{confirmed_at: %DateTime{}} = factor <- Repo.get(__MODULE__, current.id),
           :ok <- verify(factor, code, recovery?) do
        codes = if action == :regenerate, do: recovery_codes(), else: []
        factor = Repo.get!(__MODULE__, current.id)

        if action == :disable do
          Repo.delete!(factor)
        else
          factor |> change(recovery_hashes: Enum.map(codes, &hash/1)) |> Repo.update!()
        end

        replacement = rotate(current, token, action != :disable)

        event =
          if action == :disable, do: "user.mfa_disabled", else: "user.mfa_recovery_regenerated"

        audit(current, event, "Updated two-factor authentication")
        {:ok, codes, replacement}
      else
        {:error, reason} -> {:error, reason}
        _ -> {:error, :reauthenticate}
      end
    end)
  end

  def revoke(token) when is_binary(token),
    do: Repo.delete_all(from s in BrowserSession, where: s.token_hash == ^hash(token))

  def revoke(_), do: :ok

  defp verify(factor, code, recovery?) do
    started = factor.attempt_window_started_at

    attempts =
      if started && DateTime.diff(now(), started) < 300, do: factor.failed_attempts, else: 0

    if attempts >= 5 do
      {:error, :rate_limited}
    else
      proof = proof(factor, code, recovery?)

      attrs =
        if proof do
          proof ++ [failed_attempts: 0, attempt_window_started_at: nil]
        else
          [
            failed_attempts: attempts + 1,
            attempt_window_started_at: if(attempts == 0, do: now(), else: started)
          ]
        end

      factor |> change(attrs) |> Repo.update!()
      if proof, do: :ok, else: {:error, :invalid_code}
    end
  end

  defp proof(factor, code, true) when is_binary(code) do
    candidate = hash(String.trim(code))

    if Enum.any?(factor.recovery_hashes, &Plug.Crypto.secure_compare(&1, candidate)),
      do: [recovery_hashes: List.delete(factor.recovery_hashes, candidate)]
  end

  defp proof(factor, code, false) when is_binary(code) do
    step = div(System.system_time(:second), 30)

    matched =
      Enum.find([step, step - 1, step + 1], fn candidate ->
        (is_nil(factor.last_used_step) or candidate > factor.last_used_step) and
          NimbleTOTP.valid?(factor.secret, code, time: candidate * 30)
      end)

    if matched, do: [last_used_step: matched]
  end

  defp proof(_, _, _), do: nil

  defp recent?(user, token) do
    case session(user.id, token, "session") do
      %BrowserSession{} = session ->
        DateTime.diff(now(), session.authenticated_at) in 0..300 and authorized?(user, token)

      nil ->
        false
    end
  end

  defp pending?(%__MODULE__{confirmed_at: nil} = factor, token) when is_binary(token),
    do:
      factor.enrollment_token_hash == hash(token) and
        DateTime.after?(factor.enrollment_expires_at, now())

  defp pending?(_, _), do: false

  defp session(user_id, token, context) do
    with %BrowserSession{user_id: ^user_id} = session <- lookup(token, context),
         %User{authentication_version: version} <- Repo.get(User, user_id),
         true <- session.authentication_version == version do
      session
    else
      _ -> nil
    end
  end

  defp lookup(token, context) when is_binary(token) do
    Repo.one(
      from s in BrowserSession,
        where: s.token_hash == ^hash(token) and s.context == ^context and s.expires_at > ^now()
    )
  end

  defp lookup(_, _), do: nil

  defp issue(user, context, organization_sso, verified?) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    Repo.delete_all(
      from s in BrowserSession, where: s.user_id == ^user.id and s.expires_at <= ^now()
    )

    Repo.insert!(%BrowserSession{
      token_hash: hash(token),
      user_id: user.id,
      context: context,
      authentication_version: user.authentication_version,
      authenticated_at: now(),
      expires_at: DateTime.add(now(), if(context == "challenge", do: 300, else: 28_800)),
      mfa_verified_at: if(verified?, do: now()),
      organization_sso: organization_sso
    })

    token
  end

  defp rotate(user, token, verified?) do
    previous = session(user.id, token, "session")
    Repo.delete_all(from s in BrowserSession, where: s.user_id == ^user.id)

    user =
      user |> change(authentication_version: user.authentication_version + 1) |> Repo.update!()

    issue(user, "session", previous.organization_sso, verified?)
  end

  defp locked(user_id, fun) do
    {:ok, {result, changed?}} =
      Repo.transaction(fn ->
        user = Repo.one!(from u in User, where: u.id == ^user_id, lock: "FOR UPDATE")
        result = fun.(user)
        {result, Repo.get!(User, user_id).authentication_version != user.authentication_version}
      end)

    if changed?, do: GlossiaWeb.Endpoint.broadcast("user_sessions:#{user_id}", "disconnect", %{})
    result
  end

  defp recovery_codes,
    do: for(_ <- 1..10, do: :crypto.strong_rand_bytes(10) |> Base.encode32(padding: false))

  defp hash(value), do: :crypto.hash(:sha256, value)
  defp now, do: DateTime.utc_now()

  defp audit(user, event, summary),
    do:
      Glossia.Events.emit(event, Accounts.get_user(user.id).account, user,
        resource_type: "user",
        resource_id: user.id,
        summary: summary
      )
end
