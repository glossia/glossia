defmodule Glossia.Authz do
  @moduledoc """
  Authorization facade for the configured backend.

  Open source Glossia uses the default trust-based backend. Enterprise
  deployments can swap in a finer-grained authorization module without
  changing call sites.
  """

  @type scopes :: :all | [String.t()]

  @type authorize_error ::
          {:error, :unauthorized}
          | {:error, :insufficient_scope, required_scope :: String.t()}

  @spec required_scope(atom()) :: String.t() | nil
  def required_scope(action) when is_atom(action) do
    authorizer().required_scope(action)
  end

  @spec required_scope!(atom()) :: String.t()
  def required_scope!(action) do
    case required_scope(action) do
      nil ->
        raise ArgumentError, "unknown authorization action #{inspect(action)}"

      scope ->
        scope
    end
  end

  @spec available_scopes() :: [String.t()]
  def available_scopes do
    authorizer().available_scopes()
  end

  @spec authorize(atom(), any, any, keyword) :: :ok | authorize_error
  def authorize(action, subject, object \\ nil, opts \\ []) when is_atom(action) do
    authorizer().authorize(action, subject, object, opts)
  end

  @spec authorize?(atom(), any, any, keyword) :: boolean
  def authorize?(action, subject, object \\ nil, opts \\ []) do
    authorizer().authorize?(action, subject, object, opts)
  end

  @spec authorize_scope(atom(), scopes) ::
          :ok | {:error, :insufficient_scope, required_scope :: String.t()}
  def authorize_scope(action, scopes), do: authorizer().authorize_scope(action, scopes)

  defp authorizer, do: Glossia.Extensions.authorizer()
end
