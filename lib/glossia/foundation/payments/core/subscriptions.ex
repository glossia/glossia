defmodule Glossia.Foundation.Payments.Core.Subscriptions do
  import Glossia.Foundation.Utilities.Core.Plan

  only_for_plans([:cloud]) do
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
    end

    defbehaviour do
      @type subscribe_params :: %{
              :customer_id => String.t(),
              :cancel_url => String.t(),
              :success_url => String.t()
            }

      @callback subscribe(params :: subscribe_params) :: nil
    end
  end
end
