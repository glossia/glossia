defmodule Glossia.Accounts.ReservedHandlesTest do
  use ExUnit.Case, async: true

  alias Glossia.Accounts.ReservedHandles
  alias Glossia.I18n

  test "reserves the URL segment of every locale we serve" do
    for locale <- I18n.locales() do
      assert ReservedHandles.reserved?(I18n.segment(locale)),
             "#{locale} serves /#{I18n.segment(locale)} but its handle is not reserved"
    end
  end

  test "reserves languages we do not serve yet" do
    # Any of these could become a marketing prefix later, and by then the
    # handle has to still be free.
    for language <- ~w(sw eu cy ga is hi vi th tl fj sm zu yo ha) do
      assert ReservedHandles.reserved?(language)
    end
  end

  test "reserves script and region qualified locales" do
    for locale <- ~w(zh-hans zh-hant pt-br pt-pt es-419 es-mx en-gb fr-ca) do
      assert ReservedHandles.reserved?(locale)
    end
  end

  test "is case insensitive" do
    assert ReservedHandles.reserved?("ES")
    assert ReservedHandles.reserved?("zh-Hans")
  end

  test "still reserves the application's own routes" do
    for route <- ~w(admin api auth dashboard docs settings signup) do
      assert ReservedHandles.reserved?(route)
    end
  end

  test "leaves ordinary handles alone" do
    for handle <- ~w(pepicrft glossia tuist acme shopify soundcloud studio) do
      refute ReservedHandles.reserved?(handle)
    end
  end
end
