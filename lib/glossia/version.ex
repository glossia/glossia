defmodule Glossia.Version do
  @current File.read!("priv/version.txt")

  def current_version, do: @current
end
