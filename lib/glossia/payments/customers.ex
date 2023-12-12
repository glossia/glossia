defmodule Glossia.Payments.Customers do
  use Modulex

  defimplementation do
    def create(name) do
      {:ok, %{id: id}} = Stripe.Customer.create(%{name: name})
      id
    end
  end

  defbehaviour do
    @doc """
    Creates a new customer.
    """
    @callback create(name :: String.t()) :: String.t()
  end
end
