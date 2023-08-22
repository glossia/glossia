defmodule Glossia.Version do
  use Boundary

  @current File.read!("priv/version.txt")
  @external_resource "priv/version.txt"

  def current_version, do: @current
end
