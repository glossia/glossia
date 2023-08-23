defmodule Glossia.Foundation.Localizations.Core.Workers.ProcessLocalizationRequestWorker do
  @moduledoc """
  It processes the events that are triggered by the version control system.
  """

  # Modules
  require Logger
  # alias Glossia.Repo
  use Oban.Worker

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "request" => request,
          "project" => _project
        }
      }) do
      Logger.info("Processing localization request", request)
  end

end
