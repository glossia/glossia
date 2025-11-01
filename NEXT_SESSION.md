# Next Session: Phase 0, Week 1 - Server Foundation

## Current Status

✅ Monorepo structure set up
✅ Vision captured in CLAUDE.md
✅ Execution plan in PLAN.md
✅ All code pushed to GitHub

## Starting Point: Option A - Server Foundation

We're beginning with the Phoenix server because both CLI and desktop app need authentication.

## Week 1 Tasks (Server - Phoenix)

### 1. Set up Phoenix Authentication (GitHub OAuth)

**Why GitHub OAuth?**
- Linguists authenticate to access repos
- Developers authenticate for API keys
- Natural fit for Git-based workflow

**Implementation Steps:**
- [ ] Add `ueberauth` and `ueberauth_github` dependencies
- [ ] Configure GitHub OAuth app (need client ID/secret)
- [ ] Create authentication controller
- [ ] Add session management
- [ ] Create login/logout routes
- [ ] Handle OAuth callback

**Files to create/modify:**
- `server/mix.exs` - add dependencies
- `server/config/dev.exs` - GitHub OAuth config
- `server/lib/glossia_server_web/controllers/auth_controller.ex`
- `server/lib/glossia_server_web/router.ex` - auth routes

### 2. Create User/Organization Models

**Database Schema:**

```elixir
# users table
- id (uuid, primary key)
- github_id (integer, unique)
- username (string)
- email (string)
- avatar_url (string)
- github_token (encrypted string) - for API access
- inserted_at, updated_at

# organizations table
- id (uuid, primary key)
- github_id (integer, unique)
- name (string)
- inserted_at, updated_at

# user_organizations (join table)
- user_id (references users)
- organization_id (references organizations)
- role (enum: owner, admin, member)
```

**Implementation:**
- [ ] Generate Ecto migrations
- [ ] Create User schema and context
- [ ] Create Organization schema and context
- [ ] Add association functions
- [ ] Seed development data

**Files to create:**
- `server/priv/repo/migrations/*_create_users.exs`
- `server/priv/repo/migrations/*_create_organizations.exs`
- `server/priv/repo/migrations/*_create_user_organizations.exs`
- `server/lib/glossia_server/accounts.ex` (context)
- `server/lib/glossia_server/accounts/user.ex`
- `server/lib/glossia_server/accounts/organization.ex`

### 3. Build API Key System for CLI

**Purpose:**
- CLI needs to authenticate without browser OAuth
- Users generate API keys in web UI
- Keys scoped to organizations

**Database Schema:**

```elixir
# api_keys table
- id (uuid, primary key)
- user_id (references users)
- organization_id (references organizations, nullable)
- key_hash (string) - bcrypt hash, never store plain
- key_prefix (string) - first 8 chars for display
- name (string) - user-defined name
- last_used_at (datetime)
- expires_at (datetime, nullable)
- inserted_at, updated_at
```

**Implementation:**
- [ ] Generate migration
- [ ] Create ApiKey schema
- [ ] Add key generation function (secure random)
- [ ] Add key validation function
- [ ] Create API key management controller
- [ ] Add Plug for API authentication

**Files to create:**
- `server/priv/repo/migrations/*_create_api_keys.exs`
- `server/lib/glossia_server/accounts/api_key.ex`
- `server/lib/glossia_server_web/plugs/api_auth.ex`
- `server/lib/glossia_server_web/controllers/api_key_controller.ex`

### 4. Add Basic AI Proxy Endpoint

**Purpose:**
- Abstract AI provider (OpenAI, Anthropic, etc.)
- Handle rate limiting and billing
- Provide consistent interface for CLI/app

**API Design:**

```
POST /api/v1/translate
Authorization: Bearer <api_key>

{
  "source_locale": "en",
  "target_locale": "es",
  "strings": [
    {"key": "welcome", "value": "Hello, world!"}
  ],
  "context": {
    "repository": "owner/repo",
    "decisions": [...] // from .glossia/decisions.jsonl
  }
}

Response:
{
  "translations": [
    {"key": "welcome", "value": "¡Hola, mundo!"}
  ],
  "usage": {
    "tokens": 150,
    "cost": 0.0002
  }
}
```

**Implementation:**
- [ ] Add HTTP client dependency (Req or HTTPoison)
- [ ] Create AI provider behaviour (for future providers)
- [ ] Implement OpenAI provider
- [ ] Create translation API controller
- [ ] Add usage tracking
- [ ] Add rate limiting

**Files to create:**
- `server/lib/glossia_server/ai/provider.ex` (behaviour)
- `server/lib/glossia_server/ai/providers/openai.ex`
- `server/lib/glossia_server/ai.ex` (context)
- `server/lib/glossia_server_web/controllers/api/v1/translation_controller.ex`
- `server/config/dev.exs` - add OpenAI API key config

## Environment Setup Needed

Before starting:
1. **GitHub OAuth App**: Create at https://github.com/settings/developers
   - Callback URL: `http://localhost:4000/auth/github/callback`
   - Save Client ID and Secret
2. **OpenAI API Key**: Get from https://platform.openai.com/api-keys
3. **PostgreSQL**: Ensure running locally (Phoenix already configured)

## Commands for Next Session

```bash
# Navigate to server
cd server

# Install dependencies (if not done)
mix deps.get

# Create database
mix ecto.create

# Run migrations (after creating them)
mix ecto.migrate

# Start server
mix phx.server
```

## Success Criteria for Week 1

By end of week 1, we should have:
- ✅ GitHub OAuth login working (can see user info)
- ✅ User/Organization models persisted
- ✅ API key generation endpoint working
- ✅ `/api/v1/translate` endpoint responding (even if basic)
- ✅ Tests for core authentication flows

## Notes

- Focus on working code, not perfect code
- Skip frontend UI polish (use Phoenix LiveView or simple forms)
- Hardcode OpenAI for now, abstract provider later
- Don't worry about billing yet, just track usage
- Keep decisions in mind but don't build decision system yet

## Questions to Resolve

1. Should we use Phoenix LiveView for API key management UI? (faster than building React)
2. Do we need organization creation or just import from GitHub?
3. Should API keys be org-scoped or user-scoped? (suggest org-scoped)
4. Rate limiting strategy: per user? per organization? per API key?

---

**Ready to continue in next session!** 🚀
