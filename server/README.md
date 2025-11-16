# GlossiaServer

The Phoenix backend server for Glossia, providing AI-powered translation API and web editor.

## Quick Start

1. **Setup environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env and add your ANTHROPIC_API_KEY
   export ANTHROPIC_API_KEY="sk-ant-api03-..."
   ```

2. **Install and setup dependencies**:
   ```bash
   mix setup
   ```

3. **Start the Phoenix server**:
   ```bash
   mix phx.server
   ```

   Or inside IEx:
   ```bash
   iex -S mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## API Endpoints

### POST /api/translate

Translates text using AI.

**Example:**
```bash
curl -X POST http://localhost:4000/api/translate \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, world!",
    "source_locale": "en",
    "target_locale": "es"
  }'
```

## Development

Run tests:
```bash
mix test
```

Run precommit checks (compile, format, test):
```bash
mix precommit
```

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
