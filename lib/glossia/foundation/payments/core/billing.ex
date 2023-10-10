defmodule Glossia.Foundation.Payments.Core.Billing do
  use Modulex

  defimplementation do
    def manage_url(customer_id, opts \\ []) do
      return_url = opts |> Keyword.get(:return_url)

      {:ok, %{url: url}} =
        Stripe.BillingPortal.Session.create(%{
          customer: customer_id,
          return_url: return_url
        })

      url
    end
  end

  defbehaviour do
    @doc """
    Creates a new payment session and returns the URL to redirect the user to.
    """
    @callback manage_url(customer_id :: String.t(), opts :: Keyword.t()) :: String.t()
  end
end
