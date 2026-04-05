defmodule Glossia.Authz do
  @moduledoc """
  Authorization facade for the built-in policy plus optional policy extensions.
  """

  alias LetMe.Rule

  @type scopes :: :all | [String.t()]

  @type authorize_error ::
          {:error, :unauthorized}
          | {:error, :insufficient_scope, required_scope :: String.t()}

  @doc "Returns the OAuth/API scope string for an authorization action."
  @spec required_scope(Glossia.Policy.action()) :: String.t() | nil
  def required_scope(action) when is_atom(action) do
    extension_scope(action) || policy_scope(action)
  end

  @doc "Returns the scope for an action or raises if the action is unknown."
  @spec required_scope!(Glossia.Policy.action()) :: String.t()
  def required_scope!(action) do
    case required_scope(action) do
      nil ->
        raise ArgumentError,
              "unknown policy action #{inspect(action)} (no matching rule in #{inspect(Glossia.Policy)})"

      scope ->
        scope
    end
  end

  @doc "Lists all available scopes from the built-in policy and any configured extension."
  @spec available_scopes() :: [String.t()]
  def available_scopes do
    (policy_scopes() ++ extension_scopes())
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc "Checks both scope access and policy authorization for an action."
  @spec authorize(Glossia.Policy.action(), any, any, keyword) :: :ok | authorize_error
  def authorize(action, subject, object \\ nil, opts \\ []) when is_atom(action) do
    scopes = Keyword.get(opts, :scopes, :all)

    with :ok <- authorize_scope(action, scopes),
         :ok <- do_authorize(action, subject, object, opts) do
      :ok
    end
  end

  @doc "Boolean variant of `authorize/4`."
  @spec authorize?(Glossia.Policy.action(), any, any, keyword) :: boolean
  def authorize?(action, subject, object \\ nil, opts \\ []) do
    match?(:ok, authorize(action, subject, object, opts))
  end

  @doc "Validates that the provided scopes cover the requested action."
  @spec authorize_scope(Glossia.Policy.action(), scopes) ::
          :ok | {:error, :insufficient_scope, required_scope :: String.t()}
  def authorize_scope(_action, :all), do: :ok

  def authorize_scope(action, scopes) when is_list(scopes) do
    required = required_scope!(action)

    if required in scopes do
      :ok
    else
      {:error, :insufficient_scope, required}
    end
  end

  defp do_authorize(action, subject, object, opts) do
    case policy_extension() do
      nil ->
        Glossia.Policy.authorize(action, subject, object, opts)

      extension ->
        case extension.authorize(action, subject, object, opts) do
          :unknown_action -> Glossia.Policy.authorize(action, subject, object, opts)
          result -> result
        end
    end
  end

  defp policy_scope(action) do
    case Glossia.Policy.get_rule(action) do
      %Rule{object: object, action: rule_action} -> "#{object}:#{rule_action}"
      nil -> nil
    end
  end

  defp policy_scopes do
    Glossia.Policy.list_rules()
    |> Enum.map(fn rule -> "#{rule.object}:#{rule.action}" end)
  end

  defp policy_extension, do: Glossia.Extensions.policy_extension()

  defp extension_scope(action) do
    case policy_extension() do
      nil -> nil
      extension -> extension.required_scope(action)
    end
  end

  defp extension_scopes do
    case policy_extension() do
      nil -> []
      extension -> extension.available_scopes()
    end
  end
end
