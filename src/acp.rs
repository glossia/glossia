use acp::Agent as _;
use agent_client_protocol as acp;
use anyhow::{Result, bail};
use std::path::{Path, PathBuf};
use tokio_util::compat::{TokioAsyncReadCompatExt, TokioAsyncWriteCompatExt};

use crate::locales::locales_list_string;
use crate::reporter::Reporter;

// ---------------------------------------------------------------------------
// Agent registry
// ---------------------------------------------------------------------------

pub struct AgentEntry {
    pub name: &'static str,
    pub binary: &'static str,
    pub args: &'static [&'static str],
    pub install: &'static str,
}

const KNOWN_AGENTS: &[AgentEntry] = &[
    AgentEntry {
        name: "Claude Code",
        binary: "claude-code-acp",
        args: &[],
        install: "npm i -g @anthropic-ai/claude-code-acp",
    },
    AgentEntry {
        name: "Codex CLI",
        binary: "codex-acp",
        args: &[],
        install: "npm i -g @openai/codex-acp",
    },
    AgentEntry {
        name: "Gemini CLI",
        binary: "gemini",
        args: &["--experimental-acp"],
        install: "npm i -g @google/gemini-cli",
    },
    AgentEntry {
        name: "Goose",
        binary: "goose",
        args: &["acp"],
        install: "https://block.github.io/goose",
    },
    AgentEntry {
        name: "OpenCode",
        binary: "opencode",
        args: &["acp"],
        install: "https://opencode.ai",
    },
];

pub struct DetectedAgent {
    pub name: &'static str,
    pub path: PathBuf,
    pub args: &'static [&'static str],
}

pub fn detect_agents() -> Vec<DetectedAgent> {
    KNOWN_AGENTS
        .iter()
        .filter_map(|entry| {
            which::which(entry.binary).ok().map(|path| DetectedAgent {
                name: entry.name,
                path,
                args: entry.args,
            })
        })
        .collect()
}

pub fn install_recommendations() -> String {
    KNOWN_AGENTS
        .iter()
        .map(|a| format!("  - {} ({}): {}", a.name, a.binary, a.install))
        .collect::<Vec<_>>()
        .join("\n")
}

// ---------------------------------------------------------------------------
// ACP Client
// ---------------------------------------------------------------------------

struct L10nInitClient {
    root: PathBuf,
}

impl L10nInitClient {
    fn validate_path(&self, raw: &Path) -> Result<PathBuf, acp::Error> {
        let requested = if raw.is_absolute() {
            raw.to_path_buf()
        } else {
            self.root.join(raw)
        };
        let resolved = requested
            .canonicalize()
            .or_else(|_| {
                // File may not exist yet (write case). Canonicalize the parent instead.
                if let Some(parent) = requested.parent() {
                    std::fs::create_dir_all(parent).ok();
                    parent
                        .canonicalize()
                        .map(|p| p.join(requested.file_name().unwrap_or_default()))
                } else {
                    Err(std::io::Error::new(
                        std::io::ErrorKind::NotFound,
                        "cannot resolve path",
                    ))
                }
            })
            .map_err(|e| acp::Error::new(-32602, format!("cannot resolve path: {e}")))?;

        let canon_root = self
            .root
            .canonicalize()
            .map_err(|e| acp::Error::new(-32602, format!("cannot resolve root: {e}")))?;

        if !resolved.starts_with(&canon_root) {
            return Err(acp::Error::new(
                -32602,
                format!("path {} is outside the project root", raw.display()),
            ));
        }
        Ok(resolved)
    }
}

#[async_trait::async_trait(?Send)]
impl acp::Client for L10nInitClient {
    async fn request_permission(
        &self,
        args: acp::RequestPermissionRequest,
    ) -> acp::Result<acp::RequestPermissionResponse> {
        // Auto-approve: the first option is typically "allow"
        if let Some(option) = args.options.first() {
            Ok(acp::RequestPermissionResponse::new(
                acp::RequestPermissionOutcome::Selected(acp::SelectedPermissionOutcome::new(
                    option.option_id.clone(),
                )),
            ))
        } else {
            Ok(acp::RequestPermissionResponse::new(
                acp::RequestPermissionOutcome::Cancelled,
            ))
        }
    }

    async fn session_notification(&self, _args: acp::SessionNotification) -> acp::Result<()> {
        // Agent output goes to stderr (inherited), so we don't need to print here.
        Ok(())
    }

    async fn read_text_file(
        &self,
        args: acp::ReadTextFileRequest,
    ) -> acp::Result<acp::ReadTextFileResponse> {
        let path = self.validate_path(&args.path)?;
        let content = std::fs::read_to_string(&path)
            .map_err(|e| acp::Error::new(-32602, format!("read error: {e}")))?;
        Ok(acp::ReadTextFileResponse::new(content))
    }

    async fn write_text_file(
        &self,
        args: acp::WriteTextFileRequest,
    ) -> acp::Result<acp::WriteTextFileResponse> {
        let path = self.validate_path(&args.path)?;
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)
                .map_err(|e| acp::Error::new(-32602, format!("mkdir error: {e}")))?;
        }
        std::fs::write(&path, &args.content)
            .map_err(|e| acp::Error::new(-32602, format!("write error: {e}")))?;
        Ok(acp::WriteTextFileResponse::new())
    }
}

// ---------------------------------------------------------------------------
// Prompt builder
// ---------------------------------------------------------------------------

fn build_init_prompt(root: &Path) -> String {
    let locales = locales_list_string();
    let root_display = root.display();

    format!(
        r#"You are helping set up l10n, a CLI tool for LLM-powered localization.

The project root is: {root_display}

Your task:
1. Scan the project directory to understand its structure and find localizable files (markdown docs, JSON, YAML, PO, text files, etc.)
2. Ask the user which source language they use and which target languages they want
3. Ask the user which files/directories they want to localize
4. Generate a complete, working L10N.md configuration file at the project root

## L10N.md Format

L10N.md uses TOML frontmatter between +++ markers, followed by free-text context (product description, tone guidelines, etc.).

### TOML Frontmatter Fields

```toml
+++
[llm]
provider = "openai"           # "openai", "anthropic", or "vertex"
api_key = "{{{{env.OPENAI_API_KEY}}}}"  # Use env var template
# coordinator_model = "gpt-4o-mini"  # Optional: model for coordination
# translator_model = "gpt-4o"        # Optional: model for translation

[[translate]]
source = "docs/**/*.md"       # Glob pattern for source files
targets = ["es", "fr", "de"]  # Target language codes
output = "docs/i18n/{{{{lang}}}}/{{{{relpath}}}}"  # Output path template
# exclude = ["docs/internal/**"]     # Optional: exclude patterns
# preserve = ["code_blocks"]         # Optional: elements to preserve
# frontmatter = "preserve"           # "preserve" (default) or "translate"
# check_cmd = "markdownlint {{{{file}}}}"  # Optional: validation command
+++

Describe your product and translation tone here.
Source language: English.
Target languages: Spanish, French, German.
```

### Output path variables
- `{{{{lang}}}}` - target language code
- `{{{{relpath}}}}` - relative path of the source file
- `{{{{basename}}}}` - filename without extension
- `{{{{ext}}}}` - file extension

### Supported formats
- Markdown (.md) - including frontmatter handling
- JSON (.json) - structured key-value translations
- YAML (.yaml, .yml) - structured key-value translations
- PO (.po) - gettext translation files
- Text (.txt) - plain text

### Supported locale codes
{locales}

## Instructions

1. Use the file system tools to explore the project structure
2. Look for existing localizable content (docs, strings files, etc.)
3. Ask the user about their preferences (source language, targets, which files)
4. Write the L10N.md file to: {root_display}/L10N.md
5. Also ensure .gitignore contains /.l10n/tmp and .gitattributes contains ".l10n/locks/** linguist-generated=true"

Generate a practical, ready-to-use configuration. Do not use commented-out examples. The file should work immediately with `l10n translate`."#
    )
}

// ---------------------------------------------------------------------------
// Run ACP init
// ---------------------------------------------------------------------------

pub async fn run_acp_init(
    root: &str,
    agent: &DetectedAgent,
    reporter: &dyn Reporter,
) -> Result<()> {
    let root_path = std::fs::canonicalize(root).unwrap_or_else(|_| PathBuf::from(root));

    reporter.log(
        crate::reporter::Verb::Info,
        &format!("Starting {} to configure l10n...", agent.name),
    );

    let mut cmd = tokio::process::Command::new(&agent.path);
    for arg in agent.args {
        cmd.arg(arg);
    }
    cmd.stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::inherit())
        .kill_on_drop(true);

    let mut child = cmd.spawn()?;
    let stdin = child
        .stdin
        .take()
        .ok_or_else(|| anyhow::anyhow!("failed to capture agent stdin"))?;
    let stdout = child
        .stdout
        .take()
        .ok_or_else(|| anyhow::anyhow!("failed to capture agent stdout"))?;

    let outgoing = stdin.compat_write();
    let incoming = stdout.compat();

    let client = L10nInitClient {
        root: root_path.clone(),
    };

    let local_set = tokio::task::LocalSet::new();
    let prompt_text = build_init_prompt(&root_path);

    let result = local_set
        .run_until(async move {
            let (conn, handle_io) =
                acp::ClientSideConnection::new(client, outgoing, incoming, |fut| {
                    tokio::task::spawn_local(fut);
                });

            tokio::task::spawn_local(async move {
                if let Err(e) = handle_io.await {
                    eprintln!("ACP I/O error: {e}");
                }
            });

            conn.initialize(
                acp::InitializeRequest::new(acp::ProtocolVersion::LATEST)
                    .client_capabilities(
                        acp::ClientCapabilities::new().fs(acp::FileSystemCapability::new()
                            .read_text_file(true)
                            .write_text_file(true)),
                    )
                    .client_info(
                        acp::Implementation::new("l10n", env!("CARGO_PKG_VERSION")).title("l10n"),
                    ),
            )
            .await
            .map_err(|e| anyhow::anyhow!("ACP initialize failed: {e}"))?;

            let session = conn
                .new_session(acp::NewSessionRequest::new(&root_path))
                .await
                .map_err(|e| anyhow::anyhow!("ACP new_session failed: {e}"))?;

            let response = conn
                .prompt(acp::PromptRequest::new(
                    session.session_id,
                    vec![prompt_text.into()],
                ))
                .await
                .map_err(|e| anyhow::anyhow!("ACP prompt failed: {e}"))?;

            match response.stop_reason {
                acp::StopReason::EndTurn => Ok(()),
                other => bail!("Agent stopped unexpectedly: {:?}", other),
            }
        })
        .await;

    // Wait for the child to finish
    let _ = child.wait().await;

    result
}
