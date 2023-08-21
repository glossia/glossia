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
      VersionControl,
      Accounts,
      Analytics,
      Projects,
      Projects.Project,
      Changelog,
      Builds,
      Events,
      Events.GitEvent,
      Version,
      # Tests
      DataCase,
      AccountsFixtures
    ]
end
