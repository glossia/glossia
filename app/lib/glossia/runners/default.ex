defmodule Glossia.Runners.Default do
  @moduledoc """
  In-process `Glossia.Runners` implementation.

  Every callback runs in the caller. `call/2` invokes the passed function
  directly; `place_child/2` starts a supervised child under a local
  `DynamicSupervisor` so the child inherits ordinary OTP shutdown rather than
  outliving the process that placed it.

  A scale-out implementation belongs in a downstream build (see
  `Glossia.Runners` for the swap point). This one is what the open-source
  repository ships: one process, whatever isolation the operator already runs
  its workload with.
  """

  @behaviour Glossia.Runners

  @supervisor Glossia.Runners.Default.Supervisor

  @impl true
  def pool_child_spec, do: {DynamicSupervisor, strategy: :one_for_one, name: @supervisor}

  @impl true
  def child?, do: false

  @impl true
  def call(fun, _opts), do: fun.()

  @impl true
  def place_child(child_spec, _opts) do
    DynamicSupervisor.start_child(@supervisor, child_spec)
  end
end
