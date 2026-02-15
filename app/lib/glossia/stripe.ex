defmodule Glossia.Stripe do
  @moduledoc false

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Glossia.Accounts.Account
  alias Glossia.Auditing
  alias Glossia.Repo
  import Ecto.Query

  alias Glossia.Stripe.MeterEvents

  @access_statuses ~w(active trialing past_due)

  def enabled? do
    cfg = config()

    Keyword.get(cfg, :enabled, false) and
      present?(Application.get_env(:stripity_stripe, :api_key)) and
      present?(Keyword.get(cfg, :price_id))
  end

  def webhook_secret do
    config()
    |> Keyword.get(:webhook_secret)
    |> case do
      secret when is_binary(secret) and secret != "" -> secret
      _ -> nil
    end
  end

  def meter_event_name do
    config()
    |> Keyword.get(:meter_event_name)
    |> case do
      name when is_binary(name) and name != "" -> name
      _ -> nil
    end
  end

  # Report usage credits to Stripe Billing Meters.
  #
  # This expects you to have created a meter-backed, usage-based Price in Stripe
  # and set the meter's event name to `STRIPE_METER_EVENT_NAME` (defaults to
  # "glossia_usage_credits").
  #
  # Value is a positive integer quantity (e.g. cents as "credits").
  def report_usage_credits(%Account{} = account, credits, opts \\ [])
      when is_integer(credits) and credits > 0 do
    Tracer.with_span "glossia.stripe.report_usage_credits" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.credits", credits}
      ])

      with true <-
             present?(Application.get_env(:stripity_stripe, :api_key)) or
               {:error, :missing_api_key},
           event_name when is_binary(event_name) and event_name != "" <-
             meter_event_name() ||
               {:error, :missing_meter_event_name},
           customer_id when is_binary(customer_id) and customer_id != "" <-
             account.stripe_customer_id ||
               {:error, :missing_customer},
           {:ok, _result} <- MeterEvents.create(event_name, customer_id, credits, opts) do
        :ok
      else
        {:error, _} = error -> error
        _ -> {:error, :unexpected_response}
      end
    end
  end

  def create_checkout_session(%Account{} = account, user, success_url, cancel_url)
      when is_binary(success_url) and is_binary(cancel_url) do
    Tracer.with_span "glossia.stripe.create_checkout_session" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.user.id", if(match?(%{id: _}, user), do: to_string(user.id), else: "")}
      ])

      with true <- enabled?() or {:error, :not_enabled},
           {:ok, session} <- do_create_checkout_session(account, user, success_url, cancel_url),
           url when is_binary(url) and url != "" <- session.url do
        {:ok, %{id: session.id, url: url}}
      else
        {:error, _} = error -> error
        _ -> {:error, :unexpected_response}
      end
    end
  end

  def sync_checkout_session_to_account(%Account{} = account, session_id)
      when is_binary(session_id) do
    Tracer.with_span "glossia.stripe.sync_checkout_session_to_account" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.stripe.checkout_session.id", to_string(session_id)}
      ])

      with true <- enabled?() or {:error, :not_enabled},
           {:ok, session} <- Stripe.Checkout.Session.retrieve(session_id),
           customer_id when is_binary(customer_id) and customer_id != "" <-
             stripe_id(session.customer) || {:error, :missing_customer},
           subscription_id when is_binary(subscription_id) and subscription_id != "" <-
             stripe_id(session.subscription) || {:error, :missing_subscription},
           {:ok, subscription} <- Stripe.Subscription.retrieve(subscription_id) do
        status = subscription.status
        has_access = access_from_status(status)

        Tracer.set_attributes([
          {"glossia.stripe.subscription.id", to_string(subscription_id)},
          {"glossia.stripe.subscription.status", to_string(status)},
          {"glossia.account.has_access", has_access}
        ])

        account
        |> Account.changeset(%{
          has_access: has_access,
          stripe_customer_id: customer_id,
          stripe_subscription_id: subscription_id,
          stripe_subscription_status: status,
          stripe_current_period_end: unix_to_datetime(subscription.current_period_end)
        })
        |> Repo.update()
      else
        {:error, _} = error -> error
        _ -> {:error, :unexpected_response}
      end
    end
  end

  def customer_portal_url(%Account{} = account, return_url) when is_binary(return_url) do
    Tracer.with_span "glossia.stripe.customer_portal_url" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account.id)}])

      with true <- enabled?() or {:error, :not_enabled},
           customer_id when is_binary(customer_id) and customer_id != "" <-
             account.stripe_customer_id ||
               {:error, :missing_customer},
           {:ok, session} <-
             Stripe.BillingPortal.Session.create(%{
               customer: customer_id,
               return_url: return_url
             }),
           url when is_binary(url) and url != "" <- session.url do
        {:ok, url}
      else
        {:error, _} = error -> error
        _ -> {:error, :unexpected_response}
      end
    end
  end

  def handle_webhook_event(%{"type" => type, "data" => %{"object" => object}})
      when is_binary(type) and is_map(object) do
    Tracer.with_span "glossia.stripe.handle_webhook_event" do
      Tracer.set_attributes([{"glossia.stripe.event.type", type}])

      case type do
        "checkout.session.completed" ->
          handle_checkout_completed(object)

        "customer.subscription.created" ->
          handle_subscription_event(object)

        "customer.subscription.updated" ->
          handle_subscription_event(object)

        "customer.subscription.deleted" ->
          handle_subscription_deleted(object)

        _ ->
          :ok
      end
    end
  end

  def handle_webhook_event(_), do: :ok

  defp handle_checkout_completed(session) do
    Tracer.with_span "glossia.stripe.handle_checkout_completed" do
      account_id =
        session["client_reference_id"] || get_in(session, ["metadata", "glossia_account_id"])

      customer_id = session["customer"]
      subscription_id = session["subscription"]

      Tracer.set_attributes([
        {"glossia.account.id", if(is_binary(account_id), do: account_id, else: "")},
        {"glossia.stripe.subscription.id",
         if(is_binary(subscription_id), do: subscription_id, else: "")}
      ])

      if session["mode"] == "subscription" and is_binary(account_id) and account_id != "" do
        case Repo.get(Account, account_id) do
          nil ->
            Logger.warning(
              "Stripe webhook: checkout completed for unknown account_id=#{inspect(account_id)}"
            )

            :ok

          %Account{} = account ->
            attrs = %{
              has_access: true,
              stripe_customer_id: customer_id,
              stripe_subscription_id: subscription_id,
              stripe_subscription_status: "active"
            }

            case account |> Account.changeset(attrs) |> Repo.update() do
              {:ok, account} ->
                Auditing.record("billing.checkout_completed", account, nil,
                  resource_type: "account",
                  resource_id: to_string(account.id),
                  summary: "Stripe checkout completed (subscription active)."
                )

                :ok

              {:error, changeset} ->
                log_changeset_error(changeset, type: "checkout.session.completed")
            end
        end
      else
        Logger.warning("Stripe webhook: checkout completed without client_reference_id")
        :ok
      end
    end
  end

  defp handle_subscription_event(subscription) do
    Tracer.with_span "glossia.stripe.handle_subscription_event" do
      subscription_id = subscription["id"]
      customer_id = subscription["customer"]
      status = subscription["status"]

      Tracer.set_attributes([
        {"glossia.stripe.subscription.id",
         if(is_binary(subscription_id), do: subscription_id, else: "")},
        {"glossia.stripe.subscription.status", to_string(status || "")}
      ])

      if is_binary(subscription_id) and subscription_id != "" do
        account =
          Account
          |> where([a], a.stripe_subscription_id == ^subscription_id)
          |> Repo.one()

        account =
          account ||
            if is_binary(customer_id) and customer_id != "" do
              Account |> where([a], a.stripe_customer_id == ^customer_id) |> Repo.one()
            end

        case account do
          nil ->
            Logger.warning(
              "Stripe webhook: subscription event for unknown subscription_id=#{inspect(subscription_id)}"
            )

            :ok

          %Account{} = account ->
            has_access = access_from_status(status)

            attrs = %{
              has_access: has_access,
              stripe_customer_id: customer_id,
              stripe_subscription_id: subscription_id,
              stripe_subscription_status: status,
              stripe_current_period_end: unix_to_datetime(subscription["current_period_end"])
            }

            case account |> Account.changeset(attrs) |> Repo.update() do
              {:ok, account} ->
                Auditing.record("billing.subscription_updated", account, nil,
                  resource_type: "account",
                  resource_id: to_string(account.id),
                  summary: "Stripe subscription updated (status=#{status}, access=#{has_access})."
                )

                :ok

              {:error, changeset} ->
                log_changeset_error(changeset, type: "subscription")
            end
        end
      else
        :ok
      end
    end
  end

  defp handle_subscription_deleted(subscription) do
    Tracer.with_span "glossia.stripe.handle_subscription_deleted" do
      subscription_id = subscription["id"]
      customer_id = subscription["customer"]

      Tracer.set_attributes([
        {"glossia.stripe.subscription.id",
         if(is_binary(subscription_id), do: subscription_id, else: "")}
      ])

      account =
        if is_binary(subscription_id) and subscription_id != "" do
          Account |> where([a], a.stripe_subscription_id == ^subscription_id) |> Repo.one()
        end

      account =
        account ||
          if is_binary(customer_id) and customer_id != "" do
            Account |> where([a], a.stripe_customer_id == ^customer_id) |> Repo.one()
          end

      case account do
        nil ->
          :ok

        %Account{} = account ->
          status = subscription["status"] || "canceled"

          attrs = %{
            has_access: false,
            stripe_subscription_status: status,
            stripe_current_period_end: unix_to_datetime(subscription["current_period_end"])
          }

          case account |> Account.changeset(attrs) |> Repo.update() do
            {:ok, account} ->
              Auditing.record("billing.subscription_deleted", account, nil,
                resource_type: "account",
                resource_id: to_string(account.id),
                summary: "Stripe subscription deleted (status=#{status})."
              )

              :ok

            {:error, changeset} ->
              log_changeset_error(changeset, type: "subscription.deleted")
          end
      end
    end
  end

  defp do_create_checkout_session(account, user, success_url, cancel_url) do
    price_id = Keyword.get(config(), :price_id)

    params =
      %{
        mode: "subscription",
        # Usage-only subscriptions can have a 0 amount at signup (metered usage is
        # billed in arrears). Collect a payment method up-front so future invoices
        # can be charged automatically.
        payment_method_collection: "always",
        line_items: [%{price: price_id, quantity: 1}],
        success_url: success_url,
        cancel_url: cancel_url,
        client_reference_id: to_string(account.id),
        metadata: %{"glossia_account_id" => to_string(account.id)},
        subscription_data: %{
          metadata: %{
            "glossia_account_id" => to_string(account.id),
            "glossia_user_id" => to_string(user.id)
          }
        }
      }
      |> maybe_put_customer(account)
      |> maybe_put_customer_email(user)

    Stripe.Checkout.Session.create(params)
  end

  defp maybe_put_customer(params, %Account{stripe_customer_id: customer_id})
       when is_binary(customer_id) and customer_id != "" do
    Map.put(params, :customer, customer_id)
  end

  defp maybe_put_customer(params, _account), do: params

  defp maybe_put_customer_email(params, %{email: email}) when is_binary(email) and email != "" do
    if Map.has_key?(params, :customer) do
      params
    else
      Map.put(params, :customer_email, email)
    end
  end

  defp maybe_put_customer_email(params, _user), do: params

  defp access_from_status(status) when is_binary(status),
    do: status in @access_statuses

  defp access_from_status(_), do: false

  defp unix_to_datetime(nil), do: nil

  defp unix_to_datetime(unix) when is_integer(unix) do
    DateTime.from_unix!(unix)
  end

  defp unix_to_datetime(unix) when is_binary(unix) do
    case Integer.parse(unix) do
      {int, ""} -> DateTime.from_unix!(int)
      _ -> nil
    end
  end

  defp stripe_id(%{id: id}) when is_binary(id) and id != "", do: id
  defp stripe_id(id) when is_binary(id) and id != "", do: id
  defp stripe_id(_), do: nil

  defp config do
    Application.get_env(:glossia, __MODULE__, [])
  end

  defp present?(value) when is_binary(value), do: value != ""
  defp present?(_), do: false

  defp log_changeset_error(changeset, metadata) do
    Logger.error("Stripe webhook: failed to update account: #{inspect(changeset.errors)}",
      stripe: metadata
    )

    :ok
  end
end
