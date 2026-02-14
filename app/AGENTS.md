This is a web application written using the Phoenix web framework.

## Deployment

Deploy with `fnox exec kamal deploy`. The `fnox exec` wrapper injects secrets (like `KAMAL_REGISTRY_PASSWORD`) that Kamal needs at deploy time.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- **CSS**: Always use CSS custom properties (variables) defined in `:root` instead of hardcoded color values, border-radius, or shadow values. If a new token is needed, add it to the `:root` block in `priv/static/assets/styles.css` first, then reference it with `var(--token-name)`. Never use hardcoded hex colors, rgba values, or pixel values for design tokens directly in selectors
- **Prose content**: Use the `.prose` CSS class for any content-heavy pages (blog posts, legal pages, documentation). This class provides consistent typography, spacing, and code block styling
- **SEO-ready content**: All public-facing content (blog posts, docs, landing pages) must be optimized for search engine indexing. Use descriptive headings (h1, h2, h3), include relevant keywords naturally, add meaningful link text (never "click here"), and ensure all images have alt attributes. Blog post titles and summaries should be clear and keyword-rich. External links to authoritative sources improve SEO ranking
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps
- **Internationalization**: All user-facing text in templates must be wrapped with `gettext/1` or `gettext/2`. Never use bare string literals for UI text. Use `gettext("text")` for simple strings and `gettext("text with %{var}", var: value)` for interpolation. After adding new strings, run `mix gettext.extract` to update the POT files
- **Authorization**: Every controller action that accesses or mutates resources must be authorized. Use `Glossia.Policy.authorize/3` (from LetMe) to check that the current user has the required scope and relationship to the resource. Never rely solely on token scope presence as proof of authorization; always verify at the resource level. Review new controllers for missing authorization checks before merging.
- **OAuth/API security**: Bearer token validation (`GlossiaWeb.Plugs.BearerAuth`) rejects invalid, expired, or revoked tokens with 401. The OAuth consent screen must always be shown before granting tokens to clients. Do not bypass or auto-approve authorization requests.
- **API and MCP parity**: When adding new data structures that represent features, ensure they are exposed through both the REST API and the MCP server. Every resource available via the API should have a corresponding MCP tool, and vice versa, so that users get a consistent experience regardless of the interface they use
- **JSON encoding/decoding**: Use Elixir's built-in `JSON` module (available since Elixir 1.18) instead of the `Jason` library for all new code. The `JSON` module is part of the standard library and requires no external dependency
- **Error handling**: Prefer pattern matching on `{:ok, _}` / `{:error, _}` tuples over `try/rescue` blocks. Use `rescue` only when interfacing with code that raises exceptions (e.g., third-party libraries with no tuple-returning alternative). Idiomatic Elixir uses tagged tuples and `with` chains for control flow, not exceptions
- **Public accounts**: The app supports public accounts that are read-only, allowing non-authenticated users to experience the product. Always design pages considering what an unauthenticated visitor will see. Be careful with authorization: public account pages must be accessible without login, but write/mutation actions must still require authentication. Every dashboard or content page should gracefully handle the "viewing as guest" case
- **URL-driven state**: All interactive page state (search queries, sort column/direction, active filters, pagination page) must be reflected in URL search params. Use `push_patch/2` to update the URL when state changes, and read params in `handle_params/3` to restore state. This ensures pages are shareable, bookmarkable, and work correctly with browser back/forward navigation
- **Auditability**: When implementing features that involve user-visible mutations (creating, updating, deleting resources, membership changes, billing events, etc.), add audit log entries via `Glossia.Auditing.record/4`. If a mutation is useful for auditability or compliance, log it. Event names follow a `resource.action` convention (e.g., `member.invited`, `voice.created`)
- **API pagination and filtering**: All REST API list endpoints must support pagination, filtering, and sorting via [Flop](https://hex.pm/packages/flop). Every Ecto schema exposed through a list endpoint must derive `Flop.Schema` with explicit `filterable` and `sortable` fields. Context list functions accept a `params` map and call `Flop.validate_and_run/3`. Controllers return a `meta` object alongside the resource list containing `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, and `has_previous_page?`. Clients paginate with `page` and `page_size` query parameters and filter with `filters[field]` parameters

## Design system

The design system uses a three-tier token architecture inspired by the [theme-ui theme specification](https://theme-ui.com/theme-spec), implemented entirely with CSS custom properties in `priv/static/assets/styles.css`. No build tools or utility frameworks are needed.

### Three-tier token architecture

1. **Primitive tokens** - Raw palette values named by what they *are*. Defined once, never used directly in component styles.
   - Colors: `--color-stone-50` through `--color-stone-900`, `--color-violet-*`, `--color-amber-*`, `--color-green-*`, `--color-code-*`
   - Typography: `--font-family-sans`, `--font-family-mono`, `--font-size-2xs` through `--font-size-7xl`
   - Spacing: `--space-0` through `--space-20` (base-4 scale)
   - Others: radii, shadows, z-indices, durations

2. **Semantic tokens** - Purpose-based references named by what they *do*. These are what component styles consume.
   - Colors: `--color-text`, `--color-bg`, `--color-primary`, `--color-border`, etc.
   - Typography: `--font-body`, `--font-heading`, `--font-code`, `--text-xs` through `--text-display`
   - Layout: `--transition`, `--radius-default`, `--radius-large`, `--shadow-card`, `--shadow-default`, `--max-width`

3. **Component tokens** - Scoped overrides for specific surfaces or components. Defined via CSS selector scope (e.g., `.dash-shell`).

### Token categories (theme-ui mapping)

| Category | CSS prefix | Example |
|---|---|---|
| colors | `--color-` | `--color-primary`, `--color-text-muted` |
| fonts | `--font-` | `--font-body`, `--font-code` |
| fontSizes | `--text-` | `--text-sm`, `--text-display` |
| fontWeights | `--weight-` | `--weight-bold` |
| lineHeights | `--leading-` | `--leading-normal` |
| space | `--space-` | `--space-4` (16px) |
| radii | `--radius-` | `--radius-md` |
| shadows | `--shadow-` | `--shadow-card` |
| zIndices | `--z-` | `--z-sticky`, `--z-dropdown` |
| transitions | `--duration-` | `--duration-normal` |

### Surface theming

The app has two visual surfaces sharing one CSS file:

- **Marketing site** (public pages): Uses the `app.html.heex` layout. Inherits `:root` token defaults directly.
- **Dashboard** (authenticated pages): Uses the `dashboard.html.heex` layout. Overrides tokens via the `.dash-shell` CSS scope.

To override a token for the dashboard, define it inside `.dash-shell { }`. Marketing pages never see dashboard overrides since they lack that wrapper element.

### Atomic design

**Atoms** - Smallest reusable visual units:
- `.button` (primary, secondary variants)
- `.badge`, `.mono`, `.lead`, `.muted`
- Heading styles (h1-h4 with responsive clamp)

**Molecules** - Composed from atoms:
- `.card` base pattern (blog-card, tool-card, feature, docs-category-card, dash-project-card all extend this)
- `.avatar-dropdown` (shared between marketing header and dashboard topbar)
- `.flash-bar` (info/error notification variants)
- `.breadcrumbs` (docs navigation)

**Components** - Page-level compositions:
- `.site-header` / `.site-footer` (marketing layout)
- `.hero` (page hero sections)
- `.prose` (long-form rendered content)
- `.dash-shell` (dashboard: sidebar + topbar + main area)

### Rules

1. **Never use raw values** in component styles. Always reference a semantic or primitive token via `var()`.
2. **Spacing uses the base-4 scale** (`--space-*`). Allowed values: 0, 1px, 2px, 4px, 6px, 8px, 10px, 12px, 16px, 20px, 24px, 32px, 40px, 48px, 64px, 80px.
3. **Typography must use the scale** (`--text-*` for sizes, `--weight-*` for weights, `--leading-*` for line-heights).
4. **Standard breakpoints only**: 400px (small phones), 768px (mobile), 960px (tablet). No other breakpoints.
5. **Dashboard overrides scope to `.dash-shell`**. Never add dashboard-specific tokens to `:root`.
6. **Prism/code colors use `--color-code-*` tokens**. The Catppuccin Mocha palette is defined once in primitives.
7. **SVG decorative elements** (like the geometric accent on the home page) are an exception to the no-hardcoded-values rule since SVG attributes cannot reference CSS custom properties without JavaScript.
8. **Add new tokens to the correct tier**: if it is a new raw color or size, add a primitive. If it maps to a purpose, add a semantic. If it is surface-specific, scope it as a component token.

### LiveView component mapping

When migrating templates to LiveView function components:

- Each **atom** maps to a function component with a `variant` attribute: `<.button variant="primary">`
- Each **molecule** maps to a function component with slots: `<.card><:title>...</:title><:body>...</:body></.card>`
- CSS classes map directly to component `attr` declarations. Use `data-*` attributes for state variants (e.g., `data-variant="primary"`)
- Dashboard-specific components should live in a dedicated `dashboard_components.ex` module, not in `core_components.ex`

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input


## Documentation source files

Each doc page at `/docs/:category/:slug` has a corresponding Markdown source file at `priv/docs/:category/:slug.md`. The raw Markdown is also available at `/docs/:category/:slug.md`. The synthetic API Reference page (`/docs/reference/api`) has no Markdown source since it is generated from Scalar and the OpenAPI spec.

## CLI changelog

When making user-facing changes to the CLI (in `cli/`), add an entry to `cli/CHANGELOG.md` under the `## NEXT` section. Place the entry under the appropriate sub-heading:

- **Features** - New functionality or capabilities
- **Bug Fixes** - Corrections to existing behavior
- **Performance** - Speed or resource improvements
- **Refactors** - Code restructuring without behavior changes
- **Documentation** - Docs-only changes
- **Chores** - Tooling, CI, dependency updates

Each entry is a single `- ` prefixed line with a concise description. Empty sub-headings are fine and will be cleaned up at release time. The release script (`mise run cli/release`) converts `## NEXT` into a versioned heading automatically.

<!-- usage-rules-start -->

<!-- phoenix:elixir-start -->
## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

## Test guidelines

- **Always run tests with `async: true`**: Every test module must use `async: true` (e.g., `use GlossiaWeb.ConnCase, async: true` or `use Glossia.DataCase, async: true`). This ensures the test suite scales and catches shared-state bugs early
- **Never mutate global state in tests**: Do not use `Application.put_env/3`, `System.put_env/2`, or any other mechanism that writes to global (process-independent) state inside tests. Global state mutations break parallel execution because one test's changes leak into another. If a function reads from `Application.get_env`, design it to accept an overridable option via a keyword argument instead
- **Use Mimic for mocking, never Mox**: The project uses [Mimic](https://hex.pm/packages/mimic) (`{:mimic, "~> 1.10", only: :test}`). Mimic works by copying modules and does not require explicit behaviour definitions, making it simpler. Call `Mimic.copy(ModuleName)` in `test_helper.exs` for each module you need to mock, then use `stub/3` or `expect/3` in individual tests. Mimic stubs are process-scoped so they work with `async: true`
- **Dependency-inject rather than hard-wire**: When a function calls an external service or module that you want to mock in tests, accept it as an option in the last keyword-list argument with a default. For example:

      def translate(text, opts \\ []) do
        client = Keyword.get(opts, :client, Glossia.LLM.Client)
        client.complete(text)
      end

  This lets tests pass `client: mock_module` without touching global config
- **Always use `start_supervised!/1`** to start processes in tests as it guarantees cleanup between tests
- **Avoid** `Process.sleep/1` and `Process.alive?/1` in tests
  - Instead of sleeping to wait for a process to finish, **always** use `Process.monitor/1` and assert on the DOWN message:

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

   - Instead of sleeping to synchronize before the next call, **always** use `_ = :sys.get_state/1` to ensure the process has handled prior messages
<!-- phoenix:elixir-end -->

<!-- phoenix:phoenix-start -->
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
<!-- phoenix:phoenix-end -->

<!-- phoenix:ecto-start -->
## Ecto Guidelines

- **Always** preload Ecto associations in queries when they'll be accessed in templates, ie a message that needs to reference the `message.user.email`
- Remember `import Ecto.Query` and other supporting modules when you write `seeds.exs`
- `Ecto.Schema` fields always use the `:string` type, even for `:text`, columns, ie: `field :name, :string`
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT the `:allow_nil` option**. By default, Ecto validations only run if a change for the given field exists and the change value is not nil, so such as option is never needed
- You **must** use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields
- Fields which are set programatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct
- **Always** invoke `mix ecto.gen.migration migration_name_using_underscores` when generating migration files, so the correct timestamp and conventions are applied
<!-- phoenix:ecto-end -->

<!-- phoenix:html-start -->
## Phoenix HTML guidelines

- Phoenix templates **always** use `~H` or .html.heex files (known as HEEx), **never** use `~E`
- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` function to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- For "app wide" template imports, you can import/alias into the `my_app_web.ex`'s `html_helpers` block, so they will be available to all LiveViews, LiveComponent's, and all modules that do `use MyAppWeb, :html` (replace "my_app" by the actual app name)

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`**. **Never use `else if` or `elseif` in Elixir**, **always** use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx require special tag annotation if you want to insert literal curly's like `{` or `}`. If you want to show a textual code snippet on the page in a `<pre>` or `<code>` block you *must* annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax

- HEEx class attrs support lists, but you must **always** use list `[...]` syntax. You can use the class list syntax to conditionally add classes, **always do this for multiple class values**:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  and **always** wrap `if`'s inside `{...}` expressions with parens, like done above (`if(@other_condition, do: "...", else: "...")`)

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content, instead **always** use `<%= for item <- @collection do %>`
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments (`<%!-- comment --%>`)
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but the `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>
<!-- phoenix:html-end -->

<!-- phoenix:liveview-start -->
## Phoenix LiveView guidelines

- **Never** use the deprecated `live_redirect` and `live_patch` functions, instead **always** use the `<.link navigate={href}>` and  `<.link patch={href}>` in templates, and `push_navigate` and `push_patch` functions LiveViews
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. When you go to add LiveView routes to the router, the default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`

### LiveView streams

- **Always** use LiveView streams for collections for assigning regular lists to avoid memory ballooning and runtime termination with the following operations:
  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: -1)`
  - deleting items - `stream_delete(socket, :messages, msg)`

- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child. For a call like `stream(socket, :messages, [new_msg])` in the LiveView, the template would be:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- LiveView streams are *not* enumerable, so you cannot use `Enum.filter/2` or `Enum.reject/2` on them. Instead, if you want to filter, prune, or refresh a list of items on the UI, you **must refetch the data and re-stream the entire stream collection, passing reset: true**:

      def handle_event("filter", %{"filter" => filter}, socket) do
        # re-fetch the messages based on the filter
        messages = list_messages(filter)

        {:noreply,
         socket
         |> assign(:messages_empty?, messages == [])
         # reset the stream with the new messages
         |> stream(:messages, messages, reset: true)}
      end

- LiveView streams *do not support counting or empty states*. If you need to display a count, you must track it using a separate assign. For empty states, you can use Tailwind classes:

      <div id="tasks" phx-update="stream">
        <div class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @stream.tasks} id={id}>
          {task.name}
        </div>
      </div>

  The above only works if the empty state is the only HTML block alongside the stream for-comprehension.

- When updating an assign that should change content inside any streamed item(s), you MUST re-stream the items
  along with the updated assign:

      def handle_event("edit_message", %{"message_id" => message_id}, socket) do
        message = Chat.get_message!(message_id)
        edit_form = to_form(Chat.change_message(message, %{content: message.content}))

        # re-insert message so @editing_message_id toggle logic takes effect for that stream item
        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign(:editing_message_id, String.to_integer(message_id))
         |> assign(:edit_form, edit_form)}
      end

  And in the template:

      <div id="messages" phx-update="stream">
        <div :for={{id, message} <- @streams.messages} id={id} class="flex group">
          {message.username}
          <%= if @editing_message_id == message.id do %>
            <%!-- Edit mode --%>
            <.form for={@edit_form} id="edit-form-#{message.id}" phx-submit="save_edit">
              ...
            </.form>
          <% end %>
        </div>
      </div>

- **Never** use the deprecated `phx-update="append"` or `phx-update="prepend"` for collections

### LiveView JavaScript interop

- Remember anytime you use `phx-hook="MyHook"` and that JS hook manages its own DOM, you **must** also set the `phx-update="ignore"` attribute
- **Always** provide an unique DOM id alongside `phx-hook` otherwise a compiler error will be raised

LiveView hooks come in two flavors, 1) colocated js hooks for "inline" scripts defined inside HEEx,
and 2) external `phx-hook` annotations where JavaScript object literals are defined and passed to the `LiveSocket` constructor.

#### Inline colocated js hooks

**Never** write raw embedded `<script>` tags in heex as they are incompatible with LiveView.
Instead, **always use a colocated js hook script tag (`:type={Phoenix.LiveView.ColocatedHook}`)
when writing scripts inside the template**:

    <input type="text" name="user[phone_number]" id="user-phone-number" phx-hook=".PhoneNumber" />
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
      export default {
        mounted() {
          this.el.addEventListener("input", e => {
            let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
            if(match) {
              this.el.value = `${match[1]}-${match[2]}-${match[3]}`
            }
          })
        }
      }
    </script>

- colocated hooks are automatically integrated into the app.js bundle
- colocated hooks names **MUST ALWAYS** start with a `.` prefix, i.e. `.PhoneNumber`

#### External phx-hook

External JS hooks (`<div id="myhook" phx-hook="MyHook">`) must be placed in `assets/js/` and passed to the
LiveSocket constructor:

    const MyHook = {
      mounted() { ... }
    }
    let liveSocket = new LiveSocket("/live", Socket, {
      hooks: { MyHook }
    });

#### Pushing events between client and server

Use LiveView's `push_event/3` when you need to push events/data to the client for a phx-hook to handle.
**Always** return or rebind the socket on `push_event/3` when pushing events:

    # re-bind socket so we maintain event state to be pushed
    socket = push_event(socket, "my_event", %{...})

    # or return the modified socket directly:
    def handle_event("some_event", _, socket) do
      {:noreply, push_event(socket, "my_event", %{...})}
    end

Pushed events can then be picked up in a JS hook with `this.handleEvent`:

    mounted() {
      this.handleEvent("my_event", data => console.log("from server:", data));
    }

Clients can also push an event to the server and receive a reply with `this.pushEvent`:

    mounted() {
      this.el.addEventListener("click", e => {
        this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply from server:", reply));
      })
    }

Where the server handled it via:

    def handle_event("my_event", %{"one" => 1}, socket) do
      {:reply, %{two: 2}, socket}
    end

### LiveView tests

- `Phoenix.LiveViewTest` module and `LazyHTML` (included) for making your assertions
- Form tests are driven by `Phoenix.LiveViewTest`'s `render_submit/2` and `render_change/2` functions
- Come up with a step-by-step test plan that splits major test cases into small, isolated files. You may start with simpler tests that verify content exists, gradually add interaction tests
- **Always reference the key element IDs you added in the LiveView templates in your tests** for `Phoenix.LiveViewTest` functions like `element/2`, `has_element/2`, selectors, etc
- **Never** tests again raw HTML, **always** use `element/2`, `has_element/2`, and similar: `assert has_element?(view, "#my-form")`
- Instead of relying on testing text content, which can change, favor testing for the presence of key elements
- Focus on testing outcomes rather than implementation details
- Be aware that `Phoenix.Component` functions like `<.form>` might produce different HTML than expected. Test against the output HTML structure, not your mental model of what you expect it to be
- When facing test failures with element selectors, add debug statements to print the actual HTML, but use `LazyHTML` selectors to limit the output, ie:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### Form handling

#### Creating a form from params

If you want to create a form based on `handle_event` params:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains the form params, which are expected to have string keys.

You can also specify a name to nest the params:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### Creating a form from changesets

When using changesets, the underlying data, form params, and errors are retrieved from it. The `:as` option is automatically computed too. E.g. if you have a user schema:

    defmodule MyApp.Users.User do
      use Ecto.Schema
      ...
    end

And then you create a changeset that you pass to `to_form`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Once the form is submitted, the params will be available under `%{"user" => user_params}`.

In the template, the form form assign can be passed to the `<.form>` function component:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID, like `id="todo-form"`.

#### Avoiding form errors

**Always** use a form assigned via `to_form/2` in the LiveView, and the `<.input>` component in the template. In the template **always access forms this**:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

And **never** do this:

    <%!-- NEVER do this (invalid) --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- You are FORBIDDEN from accessing the changeset in the template as it will cause errors
- **Never** use `<.form let={f} ...>` in the template, instead **always use `<.form for={@form} ...>`**, then drive all form references from the form assign as in `@form[:field]`. The UI should **always** be driven by a `to_form/2` assigned in the LiveView module that is derived from a changeset
<!-- phoenix:liveview-end -->

<!-- usage-rules-end -->