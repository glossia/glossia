# Glossia - AI-Native Translation Platform

## Vision

Glossia reimagines software translation for the AI era by treating Git as the single source of truth and making translation quality decisions transparent and collaborative.

### The Problem

Traditional translation workflows block developers and frustrate linguists:
- Developers wait days/weeks for translations, blocking releases
- Linguists use disconnected tools requiring manual syncing
- Translation memories are static databases, not learning systems
- Quality checks run only in CI, giving delayed feedback
- Context and decisions are lost in proprietary tools

### The Solution

**For Developers: Unblocked by AI**
- `glossia translate` CLI translates changes locally using AI
- Works directly in Git working directory - no syncing
- Accepts "good enough" quality to unblock development
- Linguists review and refine later

**For Linguists: Web-Based Review Editor**
- Web app that's a "review editor" not a "translation tool"
- Click badge → instant ephemeral environment (no installation)
- Git branching/PRs abstracted away - just "start review" → "save review"
- AI copilot assists with questions and suggestions
- Validation runs in environment with instant feedback (no CI wait)
- Works on any device with a browser

**Decision Capture Over Translation Memory**
Translation memory (source → target mappings) doesn't fit AI workflows. Instead:
- Capture *why* translations were chosen, not just *what*
- Store decisions as structured data in Git (repo or org-wide `.l10n` repo)
- Minimize merge conflicts through thoughtful data structures
- Decisions include: terminology rules, style preferences, context, corrections

## Core Principles

1. **Git is the Source of Truth**: No syncing. Translations live in repos.
2. **AI-First, Human-Refined**: AI unblocks, humans perfect
3. **Decisions Over Memories**: Capture reasoning, not just mappings
4. **Local Validation**: Run checks before commit, not after CI fails
5. **Review-Oriented UX**: Linguists review translations, don't create from scratch
6. **Marketplace of Checks**: Reusable validation (like GitHub Actions)

## Architecture

### Components

**CLI (`glossia`)**
- Reads `glossia.toml` config in repository
- Detects changed strings in source files
- Translates via server API (auth + AI proxy + billing)
- Writes translations to target files in working directory
- Works with any standard format (JSON, XLIFF, PO, ARB, .strings, etc.)

**Server (Phoenix)**
- Authentication & authorization (GitHub/GitLab OAuth)
- AI provider proxy (OpenAI, Anthropic, etc.)
- Billing & usage tracking
- Organization/team management
- API for CLI and web editor
- Ephemeral environment orchestration

**Web Editor (Phoenix LiveView)**
- Review-oriented translation editor in browser
- Click badge → spin up ephemeral environment
- Repository cloned in isolated container using user's OAuth token
- Git integration (branches/PRs abstracted)
- "Start Review" → creates branch
- "Save Review" → creates PR/MR with link
- AI copilot panel for assistance
- Server-side check execution (instant feedback)
- Local text buffer for instant typing (debounced sync)

**Ephemeral Environments (Firecracker microVMs)**
- Short-lived containers per review session
- Repository cloned with user's GitHub/GitLab credentials
- Git operations run as authenticated user
- Check execution in sandboxed environment
- Auto-shutdown on idle, spin up on demand

**Shared Core (`glossia-core`)**
- Config parsing (`glossia.toml`)
- Translation file format handlers
- Decision data structures
- Check runtime integration

### Decision Storage

**Two-Tier System:**

1. **Repository-Level** (`.glossia/` directory in project)
   - Project-specific terminology
   - Context for specific strings
   - Local style preferences
   - Format: Conflict-resistant (append-only logs? Event sourcing?)

2. **Organization-Level** (`.l10n` repository)
   - Company-wide terminology database
   - Brand voice guidelines
   - Cross-project consistency rules
   - Shared glossaries

**Data Structure Considerations:**
- Append-only event log to minimize conflicts
- Decisions reference commit SHAs for context
- Structured as code (reviewable, diffable)
- Machine-readable (JSON/TOML) but human-friendly

### Check System

**Marketplace Model** (inspired by GitHub Actions):
- One check = one repository
- Reference checks like: `uses: glossia/terminology-check@v1`
- Checks run in sandboxed Node.js runtime
- Bundled runtime in desktop app
- Same checks run locally and in CI

**Check Types:**
- Variable/placeholder validation
- Length constraints
- Terminology compliance
- Style guide enforcement
- Grammar/spelling
- Custom business rules

**Safety:**
- Sandboxed execution (Deno runtime? VM2?)
- Declared permissions (file access, network)
- Resource limits (time, memory)
- Signature verification for marketplace checks

## Workflows

### Developer Workflow

```bash
# Make changes to source strings
vim src/locales/en.json

# Translate to all target languages
glossia translate

# Translations written to working directory
git add .
git commit -m "Add new welcome message"
git push
```

### Linguist Workflow

1. Click "Translate" badge on GitHub repo
2. Opens Glossia web editor (no installation)
3. Authenticate with GitHub (if not logged in)
4. Ephemeral environment spins up (~125ms cold start)
5. Repository cloned using user's credentials
6. Editor shows untranslated/flagged strings
7. Start Review → branch created automatically
8. Review translations with AI copilot assistance
9. Run checks in environment (instant feedback)
10. Save Review → PR created with link
11. Environment shuts down after idle timeout
12. Team reviews in GitHub, merges

### Configuration (`glossia.toml`)

```toml
[glossia]
source_locale = "en"
target_locales = ["es", "fr", "de", "ja"]

[formats]
json = { source = "locales/en.json", target = "locales/{locale}.json" }

[ai]
provider = "anthropic"
model = "claude-sonnet-4"
temperature = 0.3

[checks]
uses = [
  "glossia/variable-check@v1",
  "glossia/length-check@v1",
  "acme-corp/brand-terminology@v2"
]

[decisions]
repository = ".glossia"  # Local decisions
organization = "acme-corp/.l10n"  # Org-wide decisions
```

## Technical Decisions

### Why Phoenix?
- Excellent for real-time features (LiveView for web editor)
- Strong AI/ML integration patterns
- Robust background job processing (translation queues)
- Can orchestrate ephemeral environments
- WebSocket support for instant editor updates

### Why Web Over Desktop?
- Zero installation - click badge and start
- Works on any device (tablets, Chromebooks)
- No cross-platform builds or distribution
- Instant updates
- Easier collaborative editing (future)
- Cost: we pay for compute (part of subscription)

### Why Firecracker?
- Ultra-fast cold starts (~125ms vs. Docker's 1-3s)
- Minimal overhead for ephemeral workloads
- Perfect for short-lived review sessions
- Cost-effective: only pay for active time
- Available via Fly.io Machines or AWS

### Why Phoenix LiveView for Editor?
- Real-time updates without JavaScript frameworks
- Server-rendered, SEO-friendly
- Local text buffer for instant typing
- Debounced sync (300ms) for changes
- Built-in Presence for collaborative features

### Why Git for Everything?
- Developers already use it
- Built-in conflict resolution
- Audit trail and rollback
- Collaborative review via PRs
- No syncing infrastructure needed
- User OAuth tokens for seamless git operations

## Success Metrics

**For Developers:**
- Time from code change to translated build < 5 minutes
- Zero translation-caused release delays
- CLI adoption rate in repos

**For Linguists:**
- Translation review time reduced by 60%
- Translation quality score (human evaluation)
- PR cycle time for translations
- Web editor daily active users
- Time from badge click to first edit < 5 seconds

**For Organizations:**
- Cost per translated word (vs. traditional agencies)
- Translation consistency score across projects
- Time to add new language to product
- % of translations requiring human correction

## Future Possibilities

- **Collaborative Editing**: Multiple linguists in real-time (Phoenix Presence)
- **Translation Analytics**: Quality trends, AI vs. human corrections
- **Context Screenshots**: Auto-capture UI where strings appear in microVM
- **Version Control for Decisions**: "Revert to terminology from Q2 2024"
- **Federated Learning**: AI learns from corrections across customers (privacy-preserving)
- **Integration Marketplace**: Plugins for Figma, Xcode, VS Code
- **Automated Testing**: Generate i18n tests in ephemeral environment
- **Mobile Editor**: Responsive web editor for on-the-go reviews

## Open Questions

1. **Decision data structure**: Event sourcing? CRDT? Append-only log?
2. **Environment lifecycle**: Timeout after how long? Pre-warm pool?
3. **Conflict resolution**: How do we help linguists resolve translation conflicts?
4. **AI provider abstraction**: Support multiple providers with fallback?
5. **Offline mode**: Cache decisions locally? Limit CLI functionality?
6. **Badge implementation**: GitHub Action? Static badge service? Browser extension?
7. **Environment security**: Network isolation? Resource limits? Secrets handling?
8. **Cost optimization**: Spot instances? Container pooling? Aggressive timeouts?

---

**Next Steps**: See PLAN.md for execution roadmap.
