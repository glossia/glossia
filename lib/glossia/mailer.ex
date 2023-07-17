defmodule Glossia.Mailer do
  use Boundary, deps: [], exports: []

  @moduledoc """
  A module to deliver emails.
  """
  use Swoosh.Mailer, otp_app: :glossia
end
