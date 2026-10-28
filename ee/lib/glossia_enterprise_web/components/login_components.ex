defmodule GlossiaEnterpriseWeb.LoginComponents do
  use GlossiaWeb, :html
  use Gettext, backend: GlossiaEnterpriseWeb.Gettext

  def login_form(assigns) do
    ~H"""
    <.form
      for={assigns[:organization_form] || to_form(%{}, as: :organization)}
      action={~p"/auth/organization"}
      method="post"
      data-part="interest-form"
    >
      <Noora.TextInput.text_input
        name="organization[email]"
        aria-label={gettext("Work email")}
        type="email"
        input_type="email"
        label={gettext("Work email")}
        required
      />
      <Noora.Button.button
        label={gettext("Continue with your organization")}
        variant="secondary"
        size="large"
      />
    </.form>
    """
  end
end
