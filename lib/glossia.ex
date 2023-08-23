defmodule Glossia do
  @moduledoc """
  Glossia keeps the contexts that define your domain
  and business logic.
  """
  use Boundary,
    deps: [
      # GlossiaWeb
    ],
    exports: [
      Auth,
      ErrorReporter,
      Blog,
      ContentSources,
      Accounts,
      Analytics,
      Projects,
      Projects.Project,
      Changelog,
      Builds,
      Events,
      Events.GitEvent,
      Version,
      Modules,
      Modules.API,
      Modules.API.Web,
      {Modules.API.Web, []},
    ]
end
