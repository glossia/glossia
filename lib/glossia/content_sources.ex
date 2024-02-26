defmodule Glossia.ContentSources do
  @moduledoc false

  require Logger
  alias Glossia.Repo
  alias Glossia.ContentSources.{ContentSource}
  import Ecto.Query, only: [from: 2]
  alias Glossia.ContentSources.Platforms.GitHub

  @doc ~S"""
  Given the atom representing a content source platform,
  it returns the module that implements the content source platform.
  """
  @spec get_platform_module(platform :: atom()) :: module() | nil
  def get_platform_module(platform) do
    get_platform_modules()
    |> Enum.find(fn {platform_id, _} -> platform_id == platform end)
    |> case do
      {_, module} -> module
      nil -> nil
    end
  end

  defp get_platform_modules() do
    [{:github, GitHub}]
  end

  def get_content_source_by_id(id) do
    Repo.get(ContentSource, id)
  end

  def get_accounts_content_sources(accounts) do
    Repo.all(
      from p in ContentSource,
        where: p.account_id in ^Enum.map(accounts, & &1.id),
        order_by: [desc: p.inserted_at]
    )
  end

  @doc ~S"""
  Creates a new content source with the given attributes.
  """
  def create_content_source(attrs) do
    changeset = %ContentSource{} |> ContentSource.changeset(attrs)
    changeset |> Repo.insert()
  end

  @doc ~S"""
  Given a git event, it processes it.
  """
  def trigger_build(
        _project,
        %{type: "new_content", version: _version}
      ) do
    # TODO
    # project = project |> Repo.preload(:account)

    # content_platform_module =
    #   Glossia.ContentSources.get_platform_module(project.content_platform)

    # {:ok, access_token} =
    #   content_platform_module.generate_auth_token(project.id_in_content_platform)

    # :ok =
    #   %{
    #     type: "new_version",
    #     version: version,
    #     id_in_content_platform: project.id_in_content_platform,
    #     content_platform: project.content_platform,
    #     project_id: project.id,
    #     project_handle: project.handle,
    #     account_handle: project.account.handle
    #   }
    #   |> Map.put(:access_token, generate_token_for_project(project))
    #   |> Map.put(
    #     :content_source_access_token,
    #     access_token
    #   )
    #   |> Glossia.Builds.trigger_build()

    # # We should ignore events that are coming from a branch other than the default.
    # # ["refs", "heads" | tail] = Map.fetch!(attrs, :ref) |> String.split("/")
    # # branch = tail |> Enum.join("/")
    :ok
  end
end
