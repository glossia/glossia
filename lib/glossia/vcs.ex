defmodule Glossia.VCS do
  @moduledoc """
  It provides utilities for interacting with version control systems.
  """

  alias Glossia.{Repo}
  alias Glossia.Accounts.{Credential, User}

  @spec repositories(user :: Glossia.Accounts.User.t()) :: [map()]
  def repositories(_user) do
    []
  end

  @spec github_credential(user :: User.t()) :: Credential.t() | nil
  defp github_credential(user) do
    _user = user |> Repo.preload(:credentials)
    nil
  end
end
