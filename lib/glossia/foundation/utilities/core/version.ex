defmodule Glossia.Foundation.Utilities.Core.Version do
  # Module

  @current File.read!("priv/version.txt")
  @external_resource "priv/version.txt"

  @doc """
  It returns the current version of Glossia.
  """
  @spec current_version() :: String.t()
  def current_version, do: @current
end
