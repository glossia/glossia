defmodule GlossiaEnterpriseWeb.Gettext do
  @moduledoc "Translations compiled with the Enterprise UI, separate from Community catalogs."
  use Gettext.Backend,
    otp_app: :glossia,
    priv: "../ee/priv/gettext",
    plural_forms: Glossia.Gettext.Plural
end
