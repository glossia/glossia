defmodule Glossia.Version do
  use Boundary

  # Module

  @current File.read!("priv/version.txt")
  @external_resource "priv/version.txt"

  @doc """
  It returns the current version of Glossia.
  """
  @spec current_version() :: String.t()
  def current_version, do: @current
end
