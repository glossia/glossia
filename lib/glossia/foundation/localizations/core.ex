defmodule Glossia.Foundation.Localizations.Core do
  use Boundary, deps: [], exports: [API.Schemas.LocalizationRequest]

  # Modules
  alias Glossia.Localizations.API.Schemas.LocalizationRequest
  alias Glossia.Foundation.Localizations.Core.Workers.ProcessLocalizationRequestWorker

  # Types
  @type process_localization_request_opts :: %{project: Glossia.Project.t()}

  @doc """
  It processes a localization request

  ## Parameteres

  - `request` - The localization request to process.
  - `opts` - The options to process the localization request.
  """
  @spec process_localization_request(
          request :: LocalizationRequest.t(),
          opts :: process_localization_request_opts()
        ) :: :ok | {:error, term()}
  def process_localization_request(request, %{project: project} = _opts) do
    %{request: request, project: project}
    |> ProcessLocalizationRequestWorker.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
