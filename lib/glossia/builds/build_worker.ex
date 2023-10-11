defmodule Glossia.Builds.BuildWorker do
  # Modules
  require Logger
  alias Glossia.Builds.Build
  alias Glossia.Repo
  use Oban.Worker
  alias Glossia.ContentSources, as: ContentSources
  alias Glossia.VirtualMachine, as: VirtualMachine

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "access_token" => access_token,
          "content_source_access_token" => content_source_access_token,
          "project_id" => project_id,
          "type" => type,
          "version" => version,
          "content_source_id" => content_source_id,
          "content_source_platform" => content_source_platform,
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
          content_source_id: content_source_id,
          content_source_platform: content_source_platform,
          content_source_access_token: content_source_access_token
        })

      %Build{} ->
        :ok
    end
  end

  def trigger_build(
        %{
          content_source_id: content_source_id,
          content_source_platform: content_source_platform,
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

    content_source =
      ContentSources.new(String.to_atom(content_source_platform), content_source_id)

    ContentSources.update_state(
      content_source,
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
        GLOSSIA_CONTENT_SOURCE_ID: content_source_id,
        GLOSSIA_CONTENT_SOURCE_PLATFORM: content_source_platform,
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

    ContentSources.update_state(
      content_source,
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
