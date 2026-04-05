defmodule Glossia.PolicyExtensions.Noop do
  @moduledoc false

  @behaviour Glossia.PolicyExtension

  @impl true
  def required_scope(_action), do: nil

  @impl true
  def available_scopes, do: []

  @impl true
  def authorize(_action, _subject, _object, _opts), do: :unknown_action
end
