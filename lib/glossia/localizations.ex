defmodule Glossia.Localizations do
  use Boundary, deps: [], exports: [API.Schemas.LocalizationRequest]

  # Modules
  alias Glossia.Localizations.API.Schemas.LocalizationRequest

  # Types
  @type process_localization_request_opts :: %{ project: Glossia.Project.t() }

  @doc """
  It processes a localization request

  ## Parameteres

  - `request` - The localization request to process.
  - `opts` - The options to process the localization request.
  """
  @spec process_localization_request_opts(request :: LocalizationRequest, opts :: process_localization_request_opts)
  def process_localization_request(request, opts) do
  end
end
