defmodule GlossiaEnterprise do
  @moduledoc """
  Glossia Enterprise — private decorator around the open-source Glossia.

  This library adds enterprise-only capabilities on top of the MPL-licensed
  `:glossia` OTP application. It does not start its own supervision tree; the
  release runs `Glossia.Application` and this project supplies modules that
  glossia looks up at runtime through pluggable seams — for example,
  `GlossiaEnterprise.Runners.Managed` implementing the `Glossia.Runners`
  behaviour.

  The container image built from this repo is what the `../infra/helm/glossia-enterprise`
  chart deploys, in place of the open-source image.
  """
end
