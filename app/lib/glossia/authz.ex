defmodule Glossia.Authz do
  @moduledoc """
  Authorization facade for the built-in policy plus optional policy extensions.
  """

  alias LetMe.Rule

  @type scopes :: :all | [String.t()]

  @type authorize_error ::
          {:error, :unauthorized}
          | {:error, :insufficient_scope, required_scope :: String.t()}

  @spec required_scope(Glossia.Policy.action()) :: String.t() | nil
  def required_scope(action) when is_atom(action) do
    policy_extension().required_scope(action) || policy_scope(action)
  end

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

  @spec available_scopes() :: [String.t()]
  def available_scopes do
    (policy_scopes() ++ policy_extension().available_scopes())
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec authorize(Glossia.Policy.action(), any, any, keyword) :: :ok | authorize_error
  def authorize(action, subject, object \\ nil, opts \\ []) when is_atom(action) do
    scopes = Keyword.get(opts, :scopes, :all)

    with :ok <- authorize_scope(action, scopes),
         :ok <- do_authorize(action, subject, object, opts) do
      :ok
    end
  end

  @spec authorize?(Glossia.Policy.action(), any, any, keyword) :: boolean
  def authorize?(action, subject, object \\ nil, opts \\ []) do
    match?(:ok, authorize(action, subject, object, opts))
  end

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
    case policy_extension().authorize(action, subject, object, opts) do
      :unknown_action -> Glossia.Policy.authorize(action, subject, object, opts)
      result -> result
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
end
