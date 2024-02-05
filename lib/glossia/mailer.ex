defmodule Glossia.Mailer do
  @moduledoc ~S"""
  A module to deliver emails.
  """
  use Swoosh.Mailer, otp_app: :glossia
end
