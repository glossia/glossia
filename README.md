<p align="center">
    <a href="https://github.com/glossia/glossia">
        <img width="150" src="priv/static/images/logo-mit-shadow.svg" alt="Logo">
    </a>
    <h2 align="center">Glossia</h2>
    <p align="center">
    The open-source AI-powered localization platform.
    <br />
    <a href="https://glossia.ai"><strong>Learn more »</strong></a>
    <br />
    <br />
    <a href="https://discord.gg/zqZxSBXKf8">Discord</a>
    ·
    <a href="https://glossia.ai">Website</a>
    ·
    <a href="https://github.com/glossia/glossia/issues">Issues</a>
    ·
    <a href="https://github.com/glossia/glossia/milestones">Roadmap</a>
  </p>
</p>

<p align="center">

</p>

## Development

### Setup

1. Clone the repository: `git clone git@github.com:glossia/app.git`
2. Install the dependencies: `mix deps.get`
3. Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

### Useful commands

- Open a remote console with production: `flyctl ssh console --pty -C "/app/bin/glossia remote"`
- Generate a graph of dependencies: `mix xref graph`
- Seed data: `mix run priv/repo/seeds.exs`

#### Gettext

- Extract content: `mix gettext.extract`
- It merges the content into the English file: `mix gettext.merge priv/gettext`
- Extract content and merge: `mix gettext.extract --merge`
