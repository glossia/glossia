defmodule Glossia.Runners.Default do
  @moduledoc """
  Default `Glossia.Runners` implementation.

  Places work on the single ephemeral FLAME pool described by `Glossia.Flame`,
  configured from `:glossia, :flame`. This is the open-source deployment shape:
  one pool, on-demand runner pods when the k8s backend is selected, no
  operator-controlled scaling. See `Glossia.Runners` for the swap point.
  """

  @behaviour Glossia.Runners

  @impl true
  def pool_child_spec, do: Glossia.Flame.pool_child_spec()

  @impl true
  def pool_name, do: Glossia.Flame.pool_name()

  @impl true
  def child?, do: Glossia.Flame.child?()

  @impl true
  def call(fun, opts), do: FLAME.call(pool_name(), fun, opts)

  @impl true
  def place_child(child_spec, opts), do: FLAME.place_child(pool_name(), child_spec, opts)
end
