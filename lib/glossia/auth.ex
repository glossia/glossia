defmodule Glossia.Auth do
  @moduledoc """
  Retrieve the user information from an auth request
  """
  require Logger
  require Jason

  alias Ueberauth.Auth
  alias Glossia.Accounts
  alias Glossia.Accounts.{User}

  def find_or_create(%Auth{provider: :identity} = auth) do
    case validate_pass(auth.credentials) do
      :ok ->
        email = email_from_auth(auth)

        user =
          case Accounts.get_user_by_email(email) do
            %User{} = user -> user
            _ -> Accounts.register_user(%{email: email, password: generate_password()})
          end

        user = user |> update_credential(auth)
        {:ok, basic_info(user)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec update_credential(user :: User.t(), auth :: Ueberauth.Auth.t()) :: User.t()
  defp update_credential(user, auth) do
    {:ok, _} =
      Accounts.find_and_update_or_create_credential(%{
        provider: auth.provider,
        provider_id: auth.uid,
        token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        user_id: user.id,
        expires_at: auth.credentials.expires_at
      })

    user
  end

  defp generate_password do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> binary_part(0, 16)
  end

  def find_or_create(%Auth{} = auth) do
    email = email_from_auth(auth)

    {:ok, user} =
      case Accounts.get_user_by_email(email) do
        %Accounts.User{} = user ->
          {:ok, user}

        _ ->
          Accounts.register_user(%{email: email, password: generate_password()})
      end

    user = user |> update_credential(auth)

    {:ok, basic_info(user)}
  end

  # github does it this way
  defp avatar_from_auth(%{info: %{urls: %{avatar_url: image}}}), do: image

  # facebook does it this way
  defp avatar_from_auth(%{info: %{image: image}}), do: image

  # default case if nothing matches
  defp avatar_from_auth(auth) do
    Logger.warning("#{auth.provider} needs to find an avatar URL!")
    Logger.debug(Jason.encode!(auth))
    nil
  end

  defp basic_info(user) do
    %{
      id: user.id,
      handle: user.account.handle,
      email: user.email
    }
  end

  def email_from_auth(auth) do
    auth.info.email
  end

  defp name_from_auth(auth) do
    if auth.info.name do
      auth.info.name
    else
      name =
        [auth.info.first_name, auth.info.last_name]
        |> Enum.filter(&(&1 != nil and &1 != ""))

      if Enum.empty?(name) do
        auth.info.nickname
      else
        Enum.join(name, " ")
      end
    end
  end

  defp validate_pass(%{other: %{password: nil}}) do
    {:error, "Password required"}
  end

  defp validate_pass(%{other: %{password: pw, password_confirmation: pw}}) do
    :ok
  end

  defp validate_pass(%{other: %{password: _}}) do
    {:error, "Passwords do not match"}
  end

  defp validate_pass(_), do: {:error, "Password Required"}
end
