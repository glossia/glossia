defmodule BabelWeb.Layouts do
  use BabelWeb, :html
  use Noora

  alias Phoenix.LiveView.JS

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_path, :string, required: true
  attr :live_action, :atom, required: true
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div id="babel-shell">
      <header data-part="header">
        <.link navigate={~p"/"} data-part="brand" aria-label="Babel home">
          <span data-part="brand-mark">B</span>
          <span data-part="brand-name">Babel</span>
        </.link>
        <.neutral_button
          id="babel-sidebar-toggle"
          size="large"
          aria-label="Toggle navigation"
          aria-expanded="false"
          aria-controls="babel-navigation"
          phx-click={
            JS.toggle_attribute({"data-mobile-open", ""}, to: "#babel-navigation")
            |> JS.toggle_attribute({"aria-expanded", "true", "false"},
              to: "#babel-sidebar-toggle"
            )
          }
        >
          <.icon name="menu_3" />
        </.neutral_button>
      </header>

      <div data-part="main">
        <aside id="babel-navigation" data-part="sidebar">
          <.sidebar id="babel-sidebar">
            <.sidebar_item
              id="babel-overview-navigation"
              label="Overview"
              icon="smart_home"
              navigate={~p"/"}
              selected={@live_action == :overview}
            />
            <.sidebar_item
            id="babel-growth-navigation"
            label="Growth"
            icon="chart_donut_4"
            navigate={~p"/growth"}
              selected={@live_action == :go_to_market}
            />
            <.sidebar_item
              id="babel-organizations-navigation"
              label="Organizations"
              icon="building"
              navigate={~p"/organizations"}
              selected={@live_action in [:organizations, :organization]}
            />
          </.sidebar>
        </aside>

        <section data-part="content">
          <.flash_group flash={@flash} />
          {render_slot(@inner_block)}
        </section>
      </div>
    </div>
    """
  end

  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <div id="flash-group" aria-live="polite" data-part="flash-group">
      <.alert
        :if={message = Phoenix.Flash.get(@flash, :info)}
        id="flash-info"
        type="secondary"
        status="success"
        size="small"
        title={message}
        dismissible
      />
      <.alert
        :if={message = Phoenix.Flash.get(@flash, :error)}
        id="flash-error"
        type="secondary"
        status="error"
        size="small"
        title={message}
        dismissible
      />
      <.alert
        id="client-error"
        type="secondary"
        status="warning"
        size="small"
        title="Connection lost. Attempting to reconnect..."
        phx-disconnected={JS.show(to: "#client-error") |> JS.remove_attribute("hidden")}
        phx-connected={JS.hide(to: "#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      />
    </div>
    """
  end
end
