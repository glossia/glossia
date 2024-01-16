defmodule Glossia.AccountsFixtures do
  @moduledoc ~S"""
  This module defines test helpers for creating
  entities via the `Glossia.Accounts` context.
  """

  alias Glossia.Accounts.Organization
  alias Glossia.Repo

  def unique_user_email, do: "user#{Glossia.TestHelpers.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  @doc ~S"""
  It returns a unique identifier that can be used as a handle when
  creating user or organization accounts.
  """
  @spec unique_handle :: String.t()
  def unique_handle, do: "#{Glossia.TestHelpers.unique_integer()}"

  @type organization_fixture_attrs :: %{
          handle: String.t() | nil
        }
  @spec organization_fixture(attrs :: organization_fixture_attrs) ::
          Organization.t()
  def organization_fixture(attrs \\ %{handle: unique_handle()}) do
    {:ok, organization} =
      Enum.into(attrs, %{handle: unique_handle()})
      |> Glossia.Accounts.register_organization()

    organization |> Repo.preload(:account)
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Glossia.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
