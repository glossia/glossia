defmodule Glossia.FeatureFlags do
  @moduledoc """
  The application's feature-flag boundary.

  Flags are evaluated against accounts so an operations user can roll out an
  experimental capability to one account at a time.
  """

  alias Glossia.Accounts.Account

  @translation :translation

  @spec enabled?(:translation, %Account{}) :: boolean()
  def enabled?(flag, %Account{} = account) when flag in [@translation] do
    FunWithFlags.enabled?(flag, for: account)
  end

  @spec translation_enabled?(%Account{}) :: boolean()
  def translation_enabled?(%Account{} = account), do: enabled?(@translation, account)
end
