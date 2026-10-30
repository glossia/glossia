defmodule GlossiaWeb.MFAHTML do
  use GlossiaWeb, :html

  embed_templates "mfa_html/*"

  attr :email, :string, required: true
  attr :recovery, :boolean, default: false
  attr :action, :string, required: true
  slot :inner_block

  def code_form(assigns) do
    ~H"""
    <.form for={%{}} action={@action} method="post" data-part="form" id="mfa-code-form">
      <input type="hidden" name="username" value={@email} autocomplete="username" readonly />
      <input :if={@recovery} type="hidden" name="recovery" value="true" />
      <Noora.TextInput.text_input
        id="mfa-code"
        name="mfa_code"
        value=""
        label={if @recovery, do: gettext("Recovery code"), else: gettext("Authentication code")}
        aria-label={if @recovery, do: gettext("Recovery code"), else: gettext("Authentication code")}
        inputmode={if @recovery, do: "text", else: "numeric"}
        {%{autocomplete: if(@recovery, do: "off", else: "one-time-code"),
          pattern: if(@recovery, do: nil, else: "[0-9]{6}"),
          maxlength: if(@recovery, do: nil, else: "6")}}
        autocapitalize="none"
        spellcheck="false"
        required
        autofocus
      />
      {render_slot(@inner_block)}
    </.form>
    """
  end
end
