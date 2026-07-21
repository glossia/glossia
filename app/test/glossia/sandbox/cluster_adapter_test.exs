defmodule Glossia.Sandbox.ClusterAdapterTest do
  use ExUnit.Case, async: true

  alias Glossia.Sandbox.ClusterAdapter

  test "normalizes a runner placement timeout" do
    timeout =
      {:timeout,
       {FLAME.Pool, :place_child,
        [Glossia.RunnerPool, {Glossia.Sandbox.Runner, []}, [timeout: 120_000, link: false]]}}

    place_child = fn _pool, _child_spec, _opts -> exit(timeout) end

    assert {:error, {:sandbox_start_timeout, ^timeout}} =
             ClusterAdapter.create(%{id: Ecto.UUID.generate()}, place_child)
  end
end
