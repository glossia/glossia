defmodule Glossia.VCS do
  @moduledoc """
  It provides utilities for interacting with version control systems.
  """

  alias Glossia.Accounts.{Credential}

  @spec repositories(user :: Glossia.Accounts.User.t()) :: [map()]
  def repositories(_user) do
    []
  end
end
