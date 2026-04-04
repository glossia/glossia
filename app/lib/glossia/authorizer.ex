defmodule Glossia.Authorizer do
  @moduledoc """
  Behaviour for authorization backends.

  The default backend keeps the existing OSS policy model. Enterprise can
  replace it with a finer-grained permission system.
  """

  @type scopes :: :all | [String.t()]

  @type authorize_error ::
          {:error, :unauthorized}
          | {:error, :insufficient_scope, required_scope :: String.t()}

  @callback required_scope(atom()) :: String.t() | nil
  @callback authorize(atom(), any(), any(), keyword()) :: :ok | authorize_error()
  @callback authorize?(atom(), any(), any(), keyword()) :: boolean()
  @callback authorize_scope(atom(), scopes()) ::
              :ok | {:error, :insufficient_scope, required_scope :: String.t()}
end
