defmodule Glossia do
  @moduledoc """
  Glossia keeps the contexts that define your domain
  and business logic.
  """
  use Boundary,
    deps: [],
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
      API,
      Localizations,
      {Localizations.API.Schemas, []},
      # Tests
      DataCase,
      AccountsFixtures
    ]
end
