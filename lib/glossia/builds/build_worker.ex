defmodule Glossia.Builds.BuildWorker do
  @moduledoc false
  alias Glossia.Builds.Build
  alias Glossia.Repo
  alias Glossia.VirtualMachine, as: VirtualMachine
  require Logger
  use Oban.Worker

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "access_token" => access_token,
          "content_source_access_token" => content_source_access_token,
          "project_id" => project_id,
          "type" => type,
          "version" => version,
          "id_in_content_platform" => id_in_content_platform,
          "content_platform" => content_platform,
          "project_handle" => project_handle,
          "account_handle" => account_handle
        }
      }) do
    build = Repo.get_by(Build, version: version, project_id: project_id)

    case build do
      nil ->
        trigger_build(%{
          access_token: access_token,
          type: type,
          version: version,
          project_id: project_id,
          project_handle: project_handle,
          account_handle: account_handle,
          id_in_content_platform: id_in_content_platform,
          content_platform: content_platform,
          content_source_access_token: content_source_access_token
        })

      %Build{} ->
        :ok
    end
  end

  def trigger_build(
        %{
          id_in_content_platform: id_in_content_platform,
          content_platform: content_platform,
          version: version,
          access_token: access_token,
          content_source_access_token: content_source_access_token,
          project_id: _project_id,
          project_handle: project_handle,
          account_handle: account_handle
        } = attrs
      ) do
    build =
      Repo.insert!(Build.changeset(%Build{}, attrs))

    content_platform_module =
      Glossia.ContentSources.get_platform_module(String.to_atom(content_platform))

    content_platform_module.update_state(
      id_in_content_platform,
      :pending,
      version,
      target_url: "",
      description: "Localizing"
    )

    VirtualMachine.run(%{
      env: %{
        # Project
        GLOSSIA_ACCESS_TOKEN: access_token,
        GLOSSIA_OWNER_HANDLE: account_handle,
        GLOSSIA_PROJECT_HANDLE: project_handle,

        # Event
        GLOSSIA_BUILD_TYPE: build.type,
        GLOSSIA_BUILD_ID: build.id,
        GLOSSIA_BUILD_VERSION: build.version,

        # Content Source
        GLOSSIA_id_in_content_platform: id_in_content_platform,
        GLOSSIA_content_platform: content_platform,
        GLOSSIA_CONTENT_SOURCE_ACCESS_TOKEN: content_source_access_token
      },
      update_status_cb: fn %{
                             vm_id: vm_id,
                             status: status,
                             vm_logs_url: vm_logs_url,
                             markdown_error_message: markdown_error_message
                           } ->
        update_build_status(%{
          build: build,
          vm_id: vm_id,
          status: status,
          vm_logs_url: vm_logs_url,
          markdown_error_message: markdown_error_message
        })
      end
    })

    content_platform_module.update_state(
      id_in_content_platform,
      :success,
      version,
      target_url: "",
      description: "Localized"
    )

    :ok
  end

  defp update_build_status(%{
         build: build,
         vm_id: vm_id,
         status: status,
         vm_logs_url: vm_logs_url,
         markdown_error_message: markdown_error_message
       }) do
    {:ok, _} =
      build
      |> Build.changeset(%{
        vm_id: vm_id,
        vm_logs_url: vm_logs_url,
        status: status,
        markdown_error_message: markdown_error_message
      })
      |> Repo.update()
  end
end
