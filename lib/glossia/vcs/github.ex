defmodule Glossia.VCS.Github do
  @moduledoc """
  An interface to interact with GitHub's API.
  """

  @doc """
  Given a user session it traverses the installations the user has access
  to and returns the repositories of those installations.
  """
  @spec user_repositories(auth :: Tentacat.Client.auth()) :: [map()]
  def user_repositories(auth) do
    {200, installation_data, _response} = user_installations(auth)

    installation_data["installations"]
    |> Enum.map(& &1["id"])
    |> Enum.flat_map(fn installation_id ->
      {200, repositories_data, _response} =
        user_installation_repositories(auth, installation_id)

      repositories_data["repositories"]
    end)
  end

  @doc """
  Given a user session, it returns all the app installations the user has access to.
  """
  @spec user_installations(auth :: Tentacat.Client.auth()) :: Tentacat.response()
  def user_installations(auth) do
    Tentacat.App.Installations.list_for_user(client(auth))
  end

  @doc """
  Given a user session and an installation id it returns all the repositories the installation
  has access to.
  """
  @spec user_installation_repositories(
          auth :: Tentacat.Client.auth(),
          installation_id :: integer()
        ) ::
          Tentacat.response()
  def user_installation_repositories(auth, installation_id) do
    Tentacat.App.Installations.list_repositories_for_user(client(auth), installation_id)
  end

  @spec client(auth :: Tentacat.Client.auth()) :: Tentacat.Client.t()
  defp client(auth) do
    Tentacat.Client.new(auth)
  end
end
