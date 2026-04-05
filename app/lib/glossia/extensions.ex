defmodule Glossia.Extensions do
  @moduledoc """
  Resolves optional extension modules.

  Glossia keeps a usable default implementation for each extension point.
  Deployments can override these modules in config without changing call
  sites throughout the app.
  """

  def event_handler do
    Application.get_env(:glossia, :event_handler, Glossia.Events.NoopHandler)
  end

  def event_log do
    Application.get_env(:glossia, :event_log, Glossia.EventLog.Empty)
  end

  def policy_extension do
    Application.get_env(:glossia, :policy_extension, Glossia.PolicyExtensions.Noop)
  end

  def blog do
    Application.get_env(:glossia, :blog, Glossia.Blog.Empty)
  end

  def docs do
    Application.get_env(:glossia, :docs, Glossia.Docs.Empty)
  end

  def features do
    Application.get_env(:glossia, :features, Glossia.Features.Default)
  end

  def changelog do
    Application.get_env(:glossia, :changelog, Glossia.Changelog.Empty)
  end

  def marketing_router do
    Application.get_env(:glossia, :marketing_router, Glossia.MarketingRouter.Default)
  end

  def navigation do
    Application.get_env(:glossia, :navigation, Glossia.Navigation.Default)
  end

  def account_nav_sections(sections, assigns) do
    navigation().account_nav_sections(sections, assigns)
  end
end
