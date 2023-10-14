defmodule Glossia.Auth do
  @moduledoc false

  alias Glossia.Accounts, as: Accounts
  alias Ueberauth.Auth
  require Jason
  require Logger

  defp update_credential(user, auth) do
    %{
      extra: %{
        raw_info: %{
          token: %{other_params: %{"refresh_token_expires_in" => refresh_token_expires_in}}
        }
      }
    } =
      auth

    refresh_token_expires_at =
      DateTime.utc_now() |> DateTime.add(refresh_token_expires_in, :second)

    {:ok, _} =
      Accounts.find_and_update_or_create_credential(%{
        provider: auth.provider,
        provider_id: auth.uid,
        token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        user_id: user.id,
        expires_at: auth.credentials.expires_at,
        refresh_token_expires_at: refresh_token_expires_at
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
end
