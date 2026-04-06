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
    Application.get_env(:glossia, :policy_extension)
  end

  def site do
    Application.get_env(:glossia, :site, Glossia.Site.Empty)
  end

  def site_markdown do
    Application.get_env(:glossia, :site_markdown)
  end

  def site_router do
    Application.get_env(:glossia, :site_router, Glossia.SiteRouter.Default)
  end

  def account_nav_sections(sections, assigns) do
    Glossia.Navigation.account_nav_sections(sections, assigns)
  end

  def navigation_extension do
    Application.get_env(:glossia, :navigation_extension)
  end
end
