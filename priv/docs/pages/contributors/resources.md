# Contributor resources

Glossia's website and app run on [Elixir](https://elixir-lang.org/) and [Phoenix](https://www.phoenixframework.org/), with [Deno](https://deno.land/) handling one-off tasks in transient Linux environments.

### Local set up

1. Clone the repository: `git clone git@github.com:glossia/app.git`
2. Install the dependencies: `mix deps.get`
3. Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

### Useful commands

- Open a remote console with production: `flyctl ssh console --pty -C "/app/bin/glossia remote"`
- Generate a graph of dependencies: `mix xref graph`
- Seed data: `mix run priv/repo/seeds.exs`
- Generate a diagram from the database schema: `mix ecto.gen.erd && dot -Tpng ecto_erd.dot -o erd.png`

- **Gettext**
  - Extract content: `mix gettext.extract`
  - It merges the content into the English file: `mix gettext.merge priv/gettext`
  - Extract content and merge: `mix gettext.extract --merge`

### Resources

- `Plug.Conn` [status codes](https://hexdocs.pm/plug/Plug.Conn.Status.html#code/1-known-status-codes)
- Elixir [Typespecs](https://hexdocs.pm/elixir/1.12/typespecs.html)
- [Primer Live (Livebook)](https://primer-live.org/)