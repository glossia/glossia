defmodule Glossia.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Glossia.Repo

  alias Glossia.Accounts.{User, Account, Credential, UserToken}

  def find_and_update_or_create_credential(attrs) do
    case Repo.get_by(Credential, provider: attrs.provider, provider_id: attrs.provider_id) do
      # We create the credentials
      nil ->
        %Credential{}
        |> Credential.create_changeset(%{
          provider: attrs.provider,
          provider_id: attrs.provider_id,
          token: attrs.token,
          refresh_token: attrs.refresh_token,
          expires_at: attrs.expires_at |> DateTime.from_unix!(:second),
          user_id: attrs.user_id
        })
        |> Repo.insert()

      # We update the credentials to point to the user
      %Credential{} = credential ->
        credential |> Credential.update_user_changeset(%{user_id: attrs.user_id}) |> Repo.update()
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email) |> Repo.preload(:account)
  end

  def register_user(attrs) do
    registration_changeset = %User{} |> User.registration_changeset(attrs)

    {email, existing_user} =
      case registration_changeset |> Ecto.Changeset.get_change(:email) do
        nil -> {nil, nil}
        email -> {email, Repo.get_by(User, email: email) |> Repo.preload(:account)}
      end

    registration_changeset =
      case {email, existing_user} do
        {nil, _} ->
          registration_changeset

        {email, nil} ->
          handle = email |> String.split("@") |> hd
          registration_changeset |> Ecto.Changeset.put_assoc(:account, %Account{handle: handle})

        _ ->
          registration_changeset
      end

    registration_changeset |> Repo.insert()
  end

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end
end
