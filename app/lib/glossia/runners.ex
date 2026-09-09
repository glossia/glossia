defmodule Glossia.Runners do
  @moduledoc """
  Placement backend for isolated compute — translation runners and sandbox
  children.

  Callers reach isolated compute through this module rather than through FLAME
  directly, so the pool topology, backend, and scaling policy can be swapped
  without touching call sites. The default implementation, `Glossia.Runners.Default`,
  wraps the single ephemeral FLAME pool configured from `:glossia, :flame` — the
  same behavior the app has today. An alternative implementation can be selected
  with:

      config :glossia, :runners, module: MyApp.Runners.Managed

  which is how the enterprise build swaps in a managed, operator-scaled pool.
  """

  @type child_spec :: :supervisor.child_spec() | {module(), term()} | module()

  @callback pool_child_spec() :: child_spec()
  @callback pool_name() :: atom()
  @callback child?() :: boolean()
  @callback call(fun :: (-> any()), opts :: keyword()) :: any()
  @callback place_child(child_spec :: term(), opts :: keyword()) ::
              {:ok, pid()} | :ignore | {:error, term()}

  def impl do
    :glossia
    |> Application.get_env(:runners, [])
    |> Keyword.get(:module, Glossia.Runners.Default)
  end

  def pool_child_spec, do: impl().pool_child_spec()
  def pool_name, do: impl().pool_name()
  def child?, do: impl().child?()
  def call(fun, opts \\ []) when is_function(fun, 0), do: impl().call(fun, opts)
  def place_child(child_spec, opts \\ []), do: impl().place_child(child_spec, opts)
end
