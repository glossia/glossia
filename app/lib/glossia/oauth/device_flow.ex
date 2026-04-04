defmodule Glossia.OAuth.DeviceFlow do
  @moduledoc false

  import Ecto.Query

  alias Boruta.AccessTokensAdapter
  alias Boruta.Oauth.Authorization.Scope
  alias Boruta.Oauth.Client
  alias Boruta.Oauth.TokenResponse
  alias Glossia.OAuth.DeviceAuthorization
  alias Glossia.Repo

  @device_code_bytes 32
  @default_interval 5
  @default_expires_in 900
  @max_user_code_attempts 5
  @user_code_alphabet String.graphemes("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

  @device_grant_type "urn:ietf:params:oauth:grant-type:device_code"

  def device_grant_type, do: @device_grant_type

  def default_interval, do: @default_interval
  def default_expires_in, do: @default_expires_in

  def start_authorization(%Client{} = client, raw_scope) do
    with :ok <- ensure_first_party_device_client(client),
         {:ok, scope} <- validate_scope(raw_scope),
         {:ok, code_data} <- build_unique_codes() do
      expires_at = DateTime.add(DateTime.utc_now(), @default_expires_in, :second)

      attrs = %{
        client_id: client.id,
        scope: scope,
        device_code_hash: hash_device_code(code_data.device_code),
        user_code: code_data.user_code,
        interval: @default_interval,
        expires_at: expires_at,
        status: "pending"
      }

      case %DeviceAuthorization{}
           |> DeviceAuthorization.create_changeset(attrs)
           |> Repo.insert() do
        {:ok, _device_authorization} ->
          {:ok,
           %{
             device_code: code_data.device_code,
             user_code: code_data.user_code,
             scope: scope,
             interval: @default_interval,
             expires_in: @default_expires_in
           }}

        {:error, changeset} ->
          {:error, {:validation, changeset}}
      end
    end
  end

  def get_by_user_code(raw_user_code) do
    with {:ok, normalized} <- normalize_user_code(raw_user_code) do
      query =
        from d in DeviceAuthorization,
          where: d.user_code == ^normalized,
          preload: [:user]

      case Repo.one(query) do
        nil -> {:error, :invalid_user_code}
        device_authorization -> {:ok, device_authorization}
      end
    end
  end

  def approve(%DeviceAuthorization{} = device_authorization, user_id) do
    device_authorization
    |> DeviceAuthorization.approve_changeset(user_id)
    |> Repo.update()
  end

  def deny(%DeviceAuthorization{} = device_authorization, user_id) do
    device_authorization
    |> DeviceAuthorization.deny_changeset(user_id)
    |> Repo.update()
  end

  def exchange_device_code(%Client{} = client, device_code) do
    now = DateTime.utc_now()
    device_code_hash = hash_device_code(device_code)

    with {:ok, authorization} <- get_authorization(device_code_hash),
         :ok <- ensure_same_client(authorization, client),
         :ok <- ensure_not_expired(authorization, now),
         :ok <- ensure_poll_interval(authorization, now),
         {:ok, authorization} <- mark_polled(authorization, now) do
      case authorization.status do
        "pending" ->
          {:error, :authorization_pending}

        "denied" ->
          {:error, :access_denied}

        "consumed" ->
          {:error, :invalid_grant}

        "approved" ->
          issue_token_for_approved_authorization(client, authorization.id)
      end
    end
  end

  def ensure_first_party_device_client(%Client{metadata: metadata}) do
    if metadata_truthy?(metadata, "first_party") and metadata_truthy?(metadata, "device_flow") do
      :ok
    else
      {:error, :unauthorized_client}
    end
  end

  def ensure_first_party_device_client(_), do: {:error, :unauthorized_client}

  def normalize_user_code(raw_user_code) when is_binary(raw_user_code) do
    normalized =
      raw_user_code
      |> String.upcase()
      |> String.replace(~r/[^A-Z0-9]/, "")

    case normalized do
      <<a::binary-size(4), b::binary-size(4)>> -> {:ok, "#{a}-#{b}"}
      _ -> {:error, :invalid_user_code}
    end
  end

  def normalize_user_code(_), do: {:error, :invalid_user_code}

  defp build_unique_codes(attempt \\ 1)

  defp build_unique_codes(attempt) when attempt <= @max_user_code_attempts do
    user_code = generate_user_code()

    exists? =
      Repo.exists?(
        from d in DeviceAuthorization,
          where: d.user_code == ^user_code
      )

    if exists? do
      build_unique_codes(attempt + 1)
    else
      {:ok, %{device_code: generate_device_code(), user_code: user_code}}
    end
  end

  defp build_unique_codes(_attempt), do: {:error, :code_generation_failed}

  defp generate_device_code do
    :crypto.strong_rand_bytes(@device_code_bytes)
    |> Base.url_encode64(padding: false)
  end

  defp generate_user_code do
    chars =
      :crypto.strong_rand_bytes(8)
      |> :binary.bin_to_list()
      |> Enum.map(fn byte ->
        Enum.at(@user_code_alphabet, rem(byte, length(@user_code_alphabet)))
      end)

    chars
    |> Enum.join()
    |> then(fn <<a::binary-size(4), b::binary-size(4)>> -> "#{a}-#{b}" end)
  end

  defp get_authorization(device_code_hash) do
    query =
      from d in DeviceAuthorization,
        where: d.device_code_hash == ^device_code_hash,
        preload: [:user]

    case Repo.one(query) do
      nil -> {:error, :invalid_grant}
      authorization -> {:ok, authorization}
    end
  end

  defp ensure_same_client(%DeviceAuthorization{client_id: client_id}, %Client{id: client_id}),
    do: :ok

  defp ensure_same_client(_, _), do: {:error, :invalid_client}

  defp ensure_not_expired(%DeviceAuthorization{expires_at: expires_at}, now) do
    if DateTime.compare(expires_at, now) == :gt do
      :ok
    else
      {:error, :expired_token}
    end
  end

  defp ensure_poll_interval(%DeviceAuthorization{last_polled_at: nil}, _now), do: :ok

  defp ensure_poll_interval(
         %DeviceAuthorization{last_polled_at: last_polled_at, interval: interval},
         now
       ) do
    if DateTime.diff(now, last_polled_at, :second) >= interval do
      :ok
    else
      {:error, :slow_down}
    end
  end

  defp mark_polled(device_authorization, now) do
    device_authorization
    |> Ecto.Changeset.change(last_polled_at: now)
    |> Repo.update()
  end

  defp issue_token_for_approved_authorization(%Client{} = client, authorization_id) do
    Repo.transaction(fn ->
      authorization =
        Repo.one!(
          from d in DeviceAuthorization,
            where: d.id == ^authorization_id,
            preload: [:user],
            lock: "FOR UPDATE"
        )

      with "approved" <- authorization.status,
           :ok <- ensure_not_expired(authorization, DateTime.utc_now()),
           %{} = user <- authorization.user,
           {:ok, resource_owner} <- Boruta.Config.resource_owners().get_by(sub: user.id),
           {:ok, authorized_scope} <-
             Scope.authorize(
               scope: authorization.scope,
               against: %{client: client, resource_owner: resource_owner}
             ),
           {:ok, token} <-
             AccessTokensAdapter.create(
               %{
                 client: client,
                 sub: user.id,
                 scope: authorized_scope,
                 resource_owner: resource_owner
               },
               refresh_token: true
             ),
           {:ok, _authorization} <-
             authorization
             |> DeviceAuthorization.consume_changeset()
             |> Repo.update() do
        TokenResponse.from_token(%{token: token})
      else
        "pending" ->
          Repo.rollback(:authorization_pending)

        "denied" ->
          Repo.rollback(:access_denied)

        "consumed" ->
          Repo.rollback(:invalid_grant)

        {:error, reason} ->
          Repo.rollback(reason)

        _ ->
          Repo.rollback(:server_error)
      end
    end)
    |> case do
      {:ok, token_response} -> {:ok, token_response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_scope(nil), do: {:ok, ""}
  defp validate_scope(""), do: {:ok, ""}

  defp validate_scope(scope) when is_binary(scope) do
    allowed_scopes =
      Glossia.Policy.list_rules()
      |> Enum.map(fn rule -> "#{rule.object}:#{rule.action}" end)
      |> MapSet.new()

    requested_scopes = scope |> String.split(" ", trim: true) |> MapSet.new()

    if MapSet.subset?(requested_scopes, allowed_scopes) do
      {:ok, requested_scopes |> MapSet.to_list() |> Enum.sort() |> Enum.join(" ")}
    else
      {:error, :invalid_scope}
    end
  end

  defp validate_scope(_), do: {:error, :invalid_scope}

  defp hash_device_code(device_code) when is_binary(device_code) do
    :crypto.hash(:sha256, device_code)
    |> Base.encode16(case: :lower)
  end

  defp metadata_truthy?(metadata, key) when is_map(metadata) do
    value =
      Map.get(metadata, key) ||
        Map.get(metadata, String.to_atom(key))

    value in [true, "true", 1, "1"]
  rescue
    ArgumentError -> false
  end
end
