defmodule Glossia.Runners do
  @moduledoc """
  Placement seam for isolated compute.

  In the open-source build there is only one place work runs: the process
  that asked for it. `Glossia.Runners.Default` is a straight in-process
  implementation, and the whole `Glossia.Runners` API stays as a behaviour
  so a downstream build can swap it for a scaled-out placement — a runner
  pool, a queue backed by dedicated workers, a Kubernetes-scheduled child.

  A wrapper picks its own implementation with:

      config :glossia, :runners, module: MyApp.Runners.Managed

  The `GLOSSIA_RUNNERS_MODULE` env var carries the same override for
  operators who don't rebuild.
  """

  @type child_spec :: :supervisor.child_spec() | {module(), term()} | module()

  @callback pool_child_spec() :: child_spec() | nil
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
  def child?, do: impl().child?()
  def call(fun, opts \\ []) when is_function(fun, 0), do: impl().call(fun, opts)
  def place_child(child_spec, opts \\ []), do: impl().place_child(child_spec, opts)
end
