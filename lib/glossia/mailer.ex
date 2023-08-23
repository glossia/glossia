defmodule Glossia.Mailer do
  @moduledoc """
  A module to deliver emails.
  """
  use Boundary
  use Swoosh.Mailer, otp_app: :glossia
end
