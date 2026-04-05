defmodule Glossia.AuthorizerExtension do
  @moduledoc """
  Optional extension point for adding extra authorization actions and scopes.
  """

  @type authorize_error ::
          {:error, :unauthorized}
          | {:error, :insufficient_scope, required_scope :: String.t()}

  @callback required_scope(atom()) :: String.t() | nil
  @callback available_scopes() :: [String.t()]
  @callback authorize(atom(), any(), any(), keyword()) ::
              :ok | authorize_error() | :unknown_action
end
