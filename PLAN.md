# Glossia Execution Plan

## Phase 0: Foundation (Current → Week 4)

**Goal**: Validate core hypothesis with minimal viable product

### Week 1-2: Core Infrastructure

**Server (Phoenix)**
- [ ] User authentication (GitHub OAuth)
- [ ] Organization/team model
- [ ] API authentication (API keys for CLI)
- [ ] Basic AI proxy (OpenAI/Anthropic integration)
- [ ] Usage tracking (for future billing)

**Shared Core (`glossia-core`)**
- [ ] `glossia.toml` parser
- [ ] JSON format handler (most common)
- [ ] Translation diff detector (what changed in source)
- [ ] Basic decision data structure (JSON schema)

**CLI**
- [ ] Config file loading
- [ ] Server authentication
- [ ] Detect changed strings in JSON files
- [ ] Send to server for translation
- [ ] Write translated strings back to files
- [ ] Basic error handling

### Week 3-4: Desktop App MVP

**Desktop App (Tauri)**
- [ ] Authentication with GitHub
- [ ] Load repository (local directory picker)
- [ ] Parse `glossia.toml`
- [ ] Display untranslated strings
- [ ] Simple text editor for translations
- [ ] Save translations to files
- [ ] Git operations: create branch, commit, push
- [ ] GitHub PR creation via API

**Testing**
- [ ] Test with real repository (create demo repo)
- [ ] Validate full workflow: CLI → review → PR
- [ ] Document setup for early testers

## Phase 1: Quality & Usability (Week 5-8)

### Week 5-6: Decision Capture

**Decision System**
- [ ] Design decision data structure (likely event log)
  - Decision events: terminology choice, correction, style rule
  - References: string key, commit SHA, timestamp
  - Scopes: repository vs. organization
- [ ] Implement `.glossia/decisions.jsonl` (append-only log)
- [ ] CLI: read decisions before translating
- [ ] Desktop app: capture corrections as decisions
- [ ] Server: decision sync to org `.l10n` repo

**AI Copilot (Desktop)**
- [ ] Chat panel in desktop app
- [ ] Context: current string, source language, target language
- [ ] Actions: "Why this translation?", "Suggest alternatives"
- [ ] Apply suggestion directly to editor

### Week 7-8: Local Checks

**Check Runtime**
- [ ] Research sandboxing: Deno vs. isolated-vm vs. vm2
- [ ] Implement check runner in `glossia-core`
- [ ] Define check interface (inputs, outputs)
- [ ] Bundle Node/Deno runtime in desktop app
- [ ] CLI: run checks before committing

**First Checks**
- [ ] Variable/placeholder consistency check
- [ ] Length constraint check
- [ ] Basic check marketplace repo structure

**Desktop Integration**
- [ ] Run checks on save
- [ ] Display check errors inline
- [ ] Prevent "Save Review" if checks fail (optional)

## Phase 2: Scale & Polish (Week 9-12)

### Week 9-10: Multiple Formats

**Format Support**
- [ ] XLIFF handler
- [ ] Gettext PO handler
- [ ] ARB handler (Flutter)
- [ ] iOS .strings handler
- [ ] Android XML handler
- [ ] Format auto-detection

**Improvement**
- [ ] Bulk operations (translate all, accept all)
- [ ] Search/filter strings
- [ ] Progress indicators
- [ ] Better error messages

### Week 11-12: Repository Badge & Onboarding

**Deep Linking**
- [ ] Custom protocol handler (`glossia://`)
- [ ] Badge service (static badge + deep link)
- [ ] Install detection (redirect to download if app not present)
- [ ] Repository clone/open flow in app

**Documentation**
- [ ] Getting started guide (for developers)
- [ ] Linguist onboarding guide
- [ ] `glossia.toml` reference
- [ ] Check development guide

**CI Integration**
- [ ] GitHub Action for running checks
- [ ] Example CI workflow
- [ ] Badge status based on CI

## Phase 3: Production Ready (Week 13-16)

### Week 13-14: Billing & Operations

**Server**
- [ ] Stripe integration
- [ ] Usage-based billing (per translated word)
- [ ] Team/org subscription management
- [ ] Admin dashboard

**Reliability**
- [ ] Error tracking (Sentry/Rollbar)
- [ ] Performance monitoring
- [ ] Rate limiting
- [ ] Backup strategy for user data

### Week 15-16: Launch Prep

**Security**
- [ ] Security audit
- [ ] Check sandbox penetration testing
- [ ] OAuth flow security review
- [ ] API rate limiting

**Legal**
- [ ] Terms of Service
- [ ] Privacy Policy
- [ ] GDPR compliance review
- [ ] AI provider terms compliance

**Marketing**
- [ ] Landing page
- [ ] Demo video
- [ ] Launch blog post
- [ ] Early access program

## Phase 4: Growth Features (Month 5+)

### Check Marketplace
- [ ] Marketplace website
- [ ] Check discovery and search
- [ ] Check versioning and updates
- [ ] Community check contributions
- [ ] Official check library

### Advanced AI Features
- [ ] Context screenshots (auto-capture from apps)
- [ ] Multi-modal translation (images + text)
- [ ] Learning from corrections (per-org models)
- [ ] Translation quality scoring

### Collaboration
- [ ] Real-time collaborative editing (LiveView)
- [ ] Comments and discussions on translations
- [ ] Review workflows (approval gates)
- [ ] Translation suggestions from community

### Developer Experience
- [ ] VS Code extension
- [ ] Figma plugin
- [ ] Xcode integration
- [ ] Automated i18n test generation

### Analytics
- [ ] Translation quality dashboard
- [ ] Cost per language analytics
- [ ] AI vs. human correction rates
- [ ] Consistency scores across repos

## Decision Points

### After Phase 0 (Week 4)
**Question**: Does the core workflow (CLI + desktop review) solve the problem?
- **Success**: 3+ teams using it, qualitative feedback positive
- **Pivot**: If workflow doesn't fit, iterate on UX
- **Kill**: If fundamental tech choices (Git-based) don't work

### After Phase 1 (Week 8)
**Question**: Do decisions capture enough context? Are checks valuable?
- **Success**: Decisions reduce AI errors by 40%+, checks prevent CI failures
- **Pivot**: Redesign decision structure if merge conflicts are common
- **Expand**: Add more check types if developers ask for them

### After Phase 2 (Week 12)
**Question**: Is the product ready for broader beta?
- **Success**: 10+ repos using it, <5% bug rate, positive NPS
- **Pivot**: Focus on most-used format/platform if spreading too thin
- **Delay**: Polish more if quality isn't there

### After Phase 3 (Week 16)
**Question**: Is the business model validated?
- **Success**: 50+ paying users, healthy unit economics
- **Pivot**: Adjust pricing if conversion is low
- **Focus**: Double down on enterprise if that's where traction is

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| AI translation quality too low | High | Medium | Focus on review workflow, not perfect automation |
| Git merge conflicts too frequent | High | Medium | Design conflict-resistant decision format (event log) |
| Check sandboxing insecure | High | Low | Thorough security audit, bug bounty |
| Developers won't adopt CLI | High | Medium | Make it ridiculously easy (one command setup) |
| Linguists prefer existing tools | Medium | Medium | Focus on features they lack (local checks, AI assist) |
| Multiple format support too complex | Medium | High | Start with JSON, add formats based on demand |
| Server costs too high (AI API) | Medium | Medium | Cache translations, offer BYO API key tier |

## Success Criteria by Phase

**Phase 0 (MVP)**
- 5 repositories actively using CLI
- 3 linguists using desktop app
- 1 complete workflow (change → translate → review → merge)

**Phase 1 (Quality)**
- 80% of AI translations approved without changes
- 90% reduction in CI failures due to translation errors
- Decision system preventing repeated mistakes

**Phase 2 (Scale)**
- Support 3+ translation formats
- 25+ repositories using badges
- <30 second onboarding for new linguist

**Phase 3 (Production)**
- 100+ paying users
- 99.9% uptime
- <1% critical bug rate

**Phase 4 (Growth)**
- 1000+ active repositories
- 50+ community-contributed checks
- 10+ integrations/plugins

## Team & Resources

**Phase 0-1** (Solo founder)
- Full-stack development
- Product design
- Early user support

**Phase 2-3** (Hire 1-2 engineers)
- Frontend specialist (desktop app)
- Backend specialist (Phoenix/AI)
- Or: Full-stack generalists

**Phase 4** (Grow team)
- DevRel for marketplace
- Designer for polish
- Support engineer

## Open Source Strategy

**Core Open Source**
- CLI (Rust)
- Desktop app (Tauri/Rust)
- Shared core library
- Check runtime
- Official checks

**Closed Source (Competitive Moat)**
- Server (Phoenix) - auth, billing, AI proxy
- Decision learning algorithms
- Enterprise features (SSO, audit logs)

**Why?**
- Community can build checks/integrations
- Transparent security (check runtime)
- Developer trust (see how CLI works)
- Moat is in service/intelligence, not tools

---

**Next Action**: Begin Phase 0, Week 1 - Server authentication
