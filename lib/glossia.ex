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
      VCS,
      Accounts,
      Analytics,
      Projects,
      Changelog,
      Translations
    ]
end
