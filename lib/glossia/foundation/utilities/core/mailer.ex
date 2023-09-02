defmodule Glossia.Foundation.Utilities.Core.Mailer do
  @moduledoc """
  A module to deliver emails.
  """
  use Swoosh.Mailer, otp_app: :glossia
end
