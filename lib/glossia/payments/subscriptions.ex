defmodule Glossia.Payments.Subscriptions do
  use Modulex

  defimplementation do
    def subscribe(%{customer_id: customer_id, success_url: success_url, cancel_url: cancel_url}) do
      create_params = %{
        customer: customer_id,
        success_url: success_url,
        cancel_url: cancel_url,
        mode: :subscription,
        line_items: [
          %{
            price: Application.fetch_env!(:glossia, :payments)[:premium_product_id]
          }
        ]
      }

      {:ok, %{url: url}} = Stripe.Checkout.Session.create(create_params)
      url
    end

    def increase_usage_record_by_one(subscription_id) do
      {:ok, _} =
        Stripe.UsageRecord.create(subscription_id, %{
          action: :increment,
          quantity: 1,
          timestamp: :now
        })
    end
  end

  defbehaviour do
    @type subscribe_params :: %{
            :customer_id => String.t(),
            :cancel_url => String.t(),
            :success_url => String.t()
          }

    @callback subscribe(params :: subscribe_params) :: nil

    @callback increase_usage_record_by_one(subscription_id :: String.t()) :: any()
  end
end
