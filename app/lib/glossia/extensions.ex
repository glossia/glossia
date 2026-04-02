defmodule Glossia.Extensions do
  @moduledoc """
  Resolves optional enterprise extension modules.

  Open source Glossia keeps a usable default implementation for each
  extension point. Enterprise deployments can override these modules in
  config without changing call sites throughout the app.
  """

  def audit_sink do
    Application.get_env(:glossia, :audit_sink, Glossia.Auditing.DefaultSink)
  end

  def authorizer do
    Application.get_env(:glossia, :authorizer, Glossia.Authorizers.Default)
  end
end
