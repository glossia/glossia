defmodule GlossiaEnterpriseWeb.Navigation do
  use GlossiaWeb, :html
  use Gettext, backend: GlossiaEnterpriseWeb.Gettext

  @behaviour Glossia.Navigation

  def account_nav_sections(sections, assigns) do
    if GlossiaEnterprise.Audit.authorized?(assigns[:current_user], assigns[:account]) do
      handle = assigns.handle

      sections ++
        [
          %{
            id: :enterprise,
            label: gettext("Enterprise"),
            icon: "lock",
            items: [
              %{
                label: gettext("Authentication"),
                navigate: ~p"/#{handle}/-/settings/authentication",
                active: assigns[:live_action] == :authentication_settings,
                icon: "lock_password"
              },
              %{
                label: gettext("Audit logs"),
                navigate: ~p"/#{handle}/-/audit-logs",
                active: assigns[:live_action] == :audit_logs,
                icon: "checkup_list"
              }
            ]
          }
        ]
    else
      sections
    end
  end
end
