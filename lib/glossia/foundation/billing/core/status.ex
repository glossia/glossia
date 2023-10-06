defmodule Glossia.Foundation.Billing.Core.Status do
  @doc """
  Returns true if billing is enabled for the environment in which the project is running.
  """
  @spec enabled?() :: boolean()
  def enabled? do
    api_key = Application.get_env(:stripity_stripe, :api_key)
    api_key != nil && api_key != ""
  end
end
