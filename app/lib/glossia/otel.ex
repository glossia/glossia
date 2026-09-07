defmodule Glossia.OTel do
  @moduledoc false

  def setup do
    OpentelemetryBandit.setup()
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:glossia, :repo])
    OpentelemetryLoggerMetadata.setup()
  end
end
