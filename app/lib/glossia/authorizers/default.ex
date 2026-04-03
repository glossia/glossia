defmodule Glossia.Authorizers.Default do
  @moduledoc false

  @behaviour Glossia.Authorizer

  @impl true
  def required_scope(_action), do: nil

  @impl true
  def available_scopes, do: []

  @impl true
  def authorize(_action, _subject, _object \\ nil, _opts \\ []), do: :ok

  @impl true
  def authorize?(_action, _subject, _object \\ nil, _opts \\ []), do: true

  @impl true
  def authorize_scope(_action, _scopes), do: :ok
end
