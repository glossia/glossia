defmodule Glossia.Extensions do
  @moduledoc """
  Resolves optional enterprise extension modules.

  Open source Glossia keeps a usable default implementation for each
  extension point. Enterprise deployments can override these modules in
  config without changing call sites throughout the app.
  """

  def event_handler do
    Application.get_env(:glossia, :event_handler, Glossia.Events.NoopHandler)
  end

  def authorizer do
    Application.get_env(:glossia, :authorizer, Glossia.Authorizers.Default)
  end

  def blog do
    Application.get_env(:glossia, :blog, Glossia.Blog.Default)
  end

  def docs do
    Application.get_env(:glossia, :docs, Glossia.Docs.Default)
  end

  def features do
    Application.get_env(:glossia, :features, Glossia.Features.Default)
  end

  def changelog do
    Application.get_env(:glossia, :changelog, Glossia.Changelog.Default)
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
