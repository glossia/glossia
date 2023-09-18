defmodule Glossia.Foundation.Application.Web.Components.App do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import Glossia.Foundation.Application.Core.Gettext

  def primer(assigns) do
    ~H"""
    <link phx-track-static rel="stylesheet" href="/primer_live/primer-live.min.css" />
    <script defer phx-track-static type="text/javascript" src="/primer_live/primer-live.min.js">
    </script>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil

  def glossia_logo(assigns) do
    ~H"""
    <svg
      class={[@class]}
      viewBox="0 0 2204 2204"
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
    >
      <g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g>
          <rect
            id="Rectangle"
            fill="#C8BEFD"
            fill-rule="nonzero"
            x="0"
            y="0"
            width="2204"
            height="2204"
            rx="491.964"
          >
          </rect>
          <path
            d="M952.458,501.267 L401.458,501.267 C374.287,501.267 352.261,523.293 352.261,550.463 L352.261,555.383 C352.261,582.553 374.287,604.579 401.458,604.579 L952.458,604.579 C979.628,604.579 1001.65,582.553 1001.65,555.383 L1001.65,550.463 C1001.65,523.293 979.628,501.267 952.458,501.267 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1838.59,727.57 L1213.79,727.57 C1186.62,727.57 1164.6,749.596 1164.6,776.766 L1164.6,781.686 C1164.6,808.857 1186.62,830.883 1213.79,830.883 L1838.59,830.883 C1865.76,830.883 1887.78,808.857 1887.78,781.686 L1887.78,776.766 C1887.78,749.596 1865.76,727.57 1838.59,727.57 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1474.53,501.267 L1159.68,501.267 C1132.51,501.267 1110.48,523.293 1110.48,550.463 L1110.48,555.383 C1110.48,582.553 1132.51,604.579 1159.68,604.579 L1474.53,604.579 C1501.7,604.579 1523.73,582.553 1523.73,555.383 L1523.73,550.463 C1523.73,523.293 1501.7,501.267 1474.53,501.267 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1833.67,501.267 L1681.16,501.267 C1653.99,501.267 1631.96,523.293 1631.96,550.463 L1631.96,555.383 C1631.96,582.553 1653.99,604.579 1681.16,604.579 L1833.67,604.579 C1860.84,604.579 1882.86,582.553 1882.86,555.383 L1882.86,550.463 C1882.86,523.293 1860.84,501.267 1833.67,501.267 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M953.051,732.49 L800.542,732.49 C773.372,732.49 751.346,754.516 751.346,781.686 L751.346,786.606 C751.346,813.776 773.372,835.802 800.542,835.802 L953.051,835.802 C980.221,835.802 1002.25,813.776 1002.25,786.606 L1002.25,781.686 C1002.25,754.516 980.221,732.49 953.051,732.49 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M588.404,727.57 L401.458,727.57 C374.287,727.57 352.261,749.596 352.261,776.766 L352.261,781.686 C352.261,808.857 374.287,830.883 401.458,830.883 L588.404,830.883 C615.574,830.883 637.6,808.857 637.6,781.686 L637.6,776.766 C637.6,749.596 615.574,727.57 588.404,727.57 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M555.679,1476.43 L368.733,1476.43 C341.563,1476.43 319.537,1454.4 319.537,1427.23 L319.537,1422.31 C319.537,1395.14 341.563,1373.12 368.733,1373.12 L555.679,1373.12 C582.85,1373.12 604.876,1395.14 604.876,1422.31 L604.876,1427.23 C604.876,1454.4 582.85,1476.43 555.679,1476.43 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M411.16,1129.61 C390.988,1149.78 390.988,1182.49 411.162,1202.66 C431.335,1222.83 464.042,1222.83 484.215,1202.66 L411.16,1129.61 Z M616.751,997.063 L652.092,959.389 L615.602,925.159 L580.224,960.538 L616.751,997.063 Z M761.641,1203.81 L799.316,1239.15 L869.998,1163.8 L832.323,1128.46 L761.641,1203.81 Z M484.215,1202.66 L653.278,1033.59 L580.224,960.538 L411.16,1129.61 L484.215,1202.66 Z M581.41,1034.74 L761.641,1203.81 L832.323,1128.46 L652.092,959.389 L581.41,1034.74 Z"
            id="Shape"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M919.733,1471.51 L767.224,1471.51 C740.053,1471.51 718.027,1449.48 718.027,1422.31 L718.027,1417.39 C718.027,1390.22 740.053,1368.2 767.224,1368.2 L919.733,1368.2 C946.903,1368.2 968.929,1390.22 968.929,1417.39 L968.929,1422.31 C968.929,1449.48 946.903,1471.51 919.733,1471.51 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <polyline
            id="Path"
            stroke="#000000"
            stroke-width="103.312"
            points="797.804 1162.84 966.872 993.768 1147.1 1162.84"
          >
          </polyline>
          <path
            d="M1805.27,1476.43 L1180.47,1476.43 C1153.3,1476.43 1131.28,1454.4 1131.28,1427.23 L1131.28,1422.31 C1131.28,1395.14 1153.3,1373.12 1180.47,1373.12 L1805.27,1373.12 C1832.44,1373.12 1854.46,1395.14 1854.46,1422.31 L1854.46,1427.23 C1854.46,1454.4 1832.44,1476.43 1805.27,1476.43 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <polyline
            id="Path"
            stroke="#000000"
            stroke-width="103.312"
            points="1113.87 1203.09 1282.94 1034.03 1463.17 1203.09"
          >
          </polyline>
          <path
            d="M1441.21,1702.73 L1126.36,1702.73 C1099.19,1702.73 1077.16,1680.71 1077.16,1653.54 L1077.16,1648.62 C1077.16,1621.45 1099.19,1599.42 1126.36,1599.42 L1441.21,1599.42 C1468.39,1599.42 1490.41,1621.45 1490.41,1648.62 L1490.41,1653.54 C1490.41,1680.71 1468.39,1702.73 1441.21,1702.73 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1800.35,1702.73 L1647.84,1702.73 C1620.67,1702.73 1598.64,1680.71 1598.64,1653.54 L1598.64,1648.62 C1598.64,1621.45 1620.67,1599.42 1647.84,1599.42 L1800.35,1599.42 C1827.52,1599.42 1849.55,1621.45 1849.55,1648.62 L1849.55,1653.54 C1849.55,1680.71 1827.52,1702.73 1800.35,1702.73 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M919.733,1702.73 L368.733,1702.73 C341.563,1702.73 319.537,1680.71 319.537,1653.54 L319.537,1648.62 C319.537,1621.45 341.563,1599.42 368.733,1599.42 L919.733,1599.42 C946.903,1599.42 968.929,1621.45 968.929,1648.62 L968.929,1653.54 C968.929,1680.71 946.903,1702.73 919.733,1702.73 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1392.2,1132.13 L1355.68,1168.66 L1428.73,1241.71 L1465.26,1205.18 L1392.2,1132.13 Z M1597.79,999.588 L1633.13,961.914 L1596.64,927.683 L1561.26,963.062 L1597.79,999.588 Z M1742.68,1206.33 C1763.49,1225.85 1796.18,1224.8 1815.7,1204 C1835.22,1183.19 1834.17,1150.5 1813.36,1130.98 L1742.68,1206.33 Z M1465.26,1205.18 L1634.32,1036.11 L1561.26,963.062 L1392.2,1132.13 L1465.26,1205.18 Z M1562.45,1037.26 L1742.68,1206.33 L1813.36,1130.98 L1633.13,961.914 L1562.45,1037.26 Z"
            id="Shape"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
        </g>
      </g>
    </svg>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="client-error"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show(".phx-client-error #client-error")}
      phx-connected={hide("#client-error")}
      hidden
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>

    <.flash
      id="server-error"
      kind={:error}
      title="Something went wrong!"
      phx-disconnected={show(".phx-server-error #server-error")}
      phx-connected={hide("#server-error")}
      hidden
    >
      Hang in there while we get back on track
      <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex flex-col items-center justify-between gap-2">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """

  # attr :type, :string, default: nil
  # attr :class, :string, default: nil
  # attr :rest, :global, include: ~w(disabled form name value)

  # slot :inner_block, required: true

  # def button(assigns) do
  #   ~H"""
  #   <button
  #     type={@type}
  #     class={[
  #       "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
  #       "text-sm font-semibold leading-6 text-white active:text-white/80",
  #       @class
  #     ]}
  #     {@rest}
  #   >
  #     <%= render_slot(@inner_block) %>
  #   </button>
  #   """
  # end

  attr :class, :string, default: nil
  attr :href, :string, required: true
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def link_button(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80 text-center",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(
        Glossia.Foundation.Application.Core.Gettext,
        "errors",
        msg,
        msg,
        count,
        opts
      )
    else
      Gettext.dgettext(Glossia.Foundation.Application.Core.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
