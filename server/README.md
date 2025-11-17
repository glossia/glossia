# Glossia Server

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

### Interactive API Documentation

Visit the Swagger UI at: **http://localhost:4000/api/swagger**

The interactive documentation allows you to:
- Browse all API endpoints
- See request/response schemas
- Try out API calls directly from your browser

### POST /api/translate

Translates content in any supported format using AI.

**Supported Formats:**
- `text` (default) - Plain text
- `json` - JSON translation files
- `yaml` - YAML translation files
- `xliff`, `po`, `properties`, `arb`, `strings` - Coming soon

**Simple Text Example:**
```bash
curl -X POST http://localhost:4000/api/translate \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello, world!",
    "format": "text",
    "source_locale": "en",
    "target_locale": "es"
  }'
```

**JSON File Example:**
```bash
curl -X POST http://localhost:4000/api/translate \
  -H "Content-Type: application/json" \
  -d '{
    "content": "{\"greeting\": \"Hello\", \"farewell\": \"Goodbye\"}",
    "format": "json",
    "source_locale": "en",
    "target_locale": "es"
  }'
```

**Response:**
```json
{
  "content": "¡Hola, mundo!",
  "format": "text",
  "source_locale": "en",
  "target_locale": "es"
}
```

**OpenAPI Spec:** http://localhost:4000/api/openapi

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
