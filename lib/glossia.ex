defmodule Glossia do
  @env Mix.env()
  @doc """
  Returns true if the current environment is `:dev`.
  """
  @spec dev_env?() :: boolean()
  def dev_env?, do: @env == :dev
end
