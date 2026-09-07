defmodule Glossia.Accounts.ReservedHandles do
  @moduledoc """
  Handles that would collide with a route Glossia serves itself.

  Language identifiers are in here too, and not only the ones we translate
  into today: `/es` and friends are the roots of the translated marketing site,
  so adding a language must never mean taking a URL away from an account that
  claimed the handle in the meantime. The list comes from
  `Glossia.I18n.reservable_segments/0`, which is CLDR's locale inventory.
  """

  @routes ~w(
    admin api auth billing blog cookies dashboard dev docs
    interest login logout oauth org organizations privacy
    settings signup support terms up webhooks www mcp
  )

  @reserved MapSet.new(@routes ++ Glossia.I18n.reservable_segments())

  def reserved?(handle), do: MapSet.member?(@reserved, String.downcase(handle))

  def list, do: @reserved |> MapSet.to_list() |> Enum.sort()
end
