defmodule Glossia.Authorizers.Default do
  @moduledoc false

  @behaviour Glossia.Authorizer

  alias LetMe.Rule

  @impl true
  def required_scope(action) when is_atom(action) do
    extension().required_scope(action) || policy_scope(action)
  end

  @impl true
  def available_scopes do
    (policy_scopes() ++ extension().available_scopes())
    |> Enum.uniq()
    |> Enum.sort()
  end

  @impl true
  def authorize(action, subject, object \\ nil, opts \\ []) when is_atom(action) do
    scopes = Keyword.get(opts, :scopes, :all)

    with :ok <- authorize_scope(action, scopes),
         :ok <- do_authorize(action, subject, object, opts) do
      :ok
    end
  end

  @impl true
  def authorize?(action, subject, object \\ nil, opts \\ []) do
    match?(:ok, authorize(action, subject, object, opts))
  end

  @impl true
  def authorize_scope(_action, :all), do: :ok

  def authorize_scope(action, scopes) when is_list(scopes) do
    required = required_scope!(action)

    if required in scopes do
      :ok
    else
      {:error, :insufficient_scope, required}
    end
  end

  defp required_scope!(action) do
    case required_scope(action) do
      nil ->
        raise ArgumentError,
              "unknown policy action #{inspect(action)} (no matching rule in #{inspect(Glossia.Policy)})"

      scope ->
        scope
    end
  end

  defp do_authorize(action, subject, object, opts) do
    case extension().authorize(action, subject, object, opts) do
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

  defp extension, do: Glossia.Extensions.authorizer_extension()
end
