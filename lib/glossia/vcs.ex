defmodule Glossia.VCS do
  use Boundary, deps: [Glossia.Repo], exports: []

  alias Glossia.{Repo}
  alias Glossia.Accounts.{Credential, User}

  @spec repositories(user :: Glossia.Accounts.User.t()) :: [map()]
  def repositories(user) do
    []
  end

  @spec github_credential(user :: User.t()) :: Credential.t() | nil
  defp github_credential(user) do
    user = user |> Repo.preload(:credentials)
    nil
  end
end
