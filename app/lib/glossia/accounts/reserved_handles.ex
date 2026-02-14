defmodule Glossia.Accounts.ReservedHandles do
  @reserved ~w(
    admin api auth billing blog cookies dashboard dev docs
    interest login logout oauth org organizations privacy
    settings support terms up webhooks www mcp
  )

  def reserved?(handle), do: String.downcase(handle) in @reserved
  def list, do: @reserved
end
