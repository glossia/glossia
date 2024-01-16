defmodule Glossia.Authorization.NotAuthorizedError do
  @moduledoc ~S"""
  Raised when authorization fails.
  """
  defexception [:message, :status, :reason]
end

defimpl Plug.Exception, for: Glossia.Authorization.NotAuthorizedError do
  # Forbidden
  def status(exception), do: exception.status || 403
  def actions(_exception), do: []
end
