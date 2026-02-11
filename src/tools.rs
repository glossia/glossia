use std::collections::HashMap;

use anyhow::Result;

use crate::checks;
use crate::config::AgentConfig;
use crate::format::Format;
use crate::llm::ToolDefinition;
use crate::reporter::Reporter;

pub fn tools_summary() -> &'static str {
    "syntax validators (JSON, YAML, PO, Markdown frontmatter), preserve checks (code blocks, inline code, URLs, placeholders), and optional custom commands"
}

/// Returns the tool definitions available to the coordinator agent.
pub fn coordinator_tools(format: Format, has_check_cmd: bool) -> Vec<ToolDefinition> {
    let mut tools = vec![
        ToolDefinition {
            name: "translate".to_string(),
            description: "Translate the source content to the target language using the translator agent. Returns the translated text.".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "source_content": {
                        "type": "string",
                        "description": "The source content to translate"
                    },
                    "target_lang": {
                        "type": "string",
                        "description": "The target language code or name"
                    },
                    "context": {
                        "type": "string",
                        "description": "Optional context to guide the translation"
                    },
                    "brief": {
                        "type": "string",
                        "description": "Optional instructions for the translator"
                    }
                },
                "required": ["source_content", "target_lang"]
            }),
        },
        ToolDefinition {
            name: "validate_syntax".to_string(),
            description: "Validate the syntax of translated content. Returns 'ok' if valid or an error description.".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "The content to validate"
                    },
                    "format": {
                        "type": "string",
                        "enum": ["json", "yaml", "po", "markdown", "text"],
                        "description": "The format to validate against"
                    }
                },
                "required": ["content", "format"]
            }),
        },
        ToolDefinition {
            name: "validate_preserve".to_string(),
            description: "Check that preserved tokens (code blocks, inline code, URLs, placeholders) from the source appear in the translation. Returns 'ok' or lists missing tokens.".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "translated": {
                        "type": "string",
                        "description": "The translated content"
                    },
                    "source": {
                        "type": "string",
                        "description": "The original source content"
                    },
                    "preserve_kinds": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Optional list of preserve kinds (code_blocks, inline_code, urls, placeholders). Defaults to all."
                    }
                },
                "required": ["translated", "source"]
            }),
        },
    ];

    if format == Format::Po {
        tools.push(ToolDefinition {
            name: "validate_po".to_string(),
            description: "Thorough PO/POT validation: structural checks, header entry, plural forms consistency, format string preservation, untranslated entry detection. Returns 'ok' or error description.".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "The PO content to validate"
                    },
                    "source": {
                        "type": "string",
                        "description": "Optional source PO content for format string comparison"
                    }
                },
                "required": ["content"]
            }),
        });
    }

    if has_check_cmd {
        tools.push(ToolDefinition {
            name: "run_check_command".to_string(),
            description: "Run the configured external check command on the content. The content is written to a temp file and the command is executed. Returns 'ok' or the command's error output.".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "The content to check"
                    },
                    "command": {
                        "type": "string",
                        "description": "The check command template (use {path} for the temp file path)"
                    }
                },
                "required": ["content", "command"]
            }),
        });
    }

    tools
}

/// Context needed to execute tools.
pub struct ToolContext<'a> {
    pub translator: AgentConfig,
    pub format: Format,
    pub root: String,
    pub preserve: Vec<String>,
    pub frontmatter: String,
    pub context: String,
    pub reporter: Option<&'a dyn Reporter>,
    pub check_cmd: String,
    pub check_cmds: HashMap<String, String>,
}

/// Dispatch a tool call by name.
pub async fn execute_tool(
    name: &str,
    input: &serde_json::Value,
    ctx: &ToolContext<'_>,
) -> Result<String> {
    match name {
        "translate" => execute_translate(input, ctx).await,
        "validate_syntax" => execute_validate_syntax(input),
        "validate_preserve" => execute_validate_preserve(input),
        "validate_po" => execute_validate_po(input),
        "run_check_command" => execute_run_check_command(input, ctx).await,
        _ => Ok(format!("unknown tool: {}", name)),
    }
}

async fn execute_translate(input: &serde_json::Value, ctx: &ToolContext<'_>) -> Result<String> {
    let source_content = input
        .get("source_content")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let target_lang = input
        .get("target_lang")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let context = input.get("context").and_then(|v| v.as_str()).unwrap_or("");
    let brief = input.get("brief").and_then(|v| v.as_str()).unwrap_or("");

    if source_content.is_empty() || target_lang.is_empty() {
        return Ok("error: source_content and target_lang are required".to_string());
    }

    let effective_context = if context.is_empty() {
        &ctx.context
    } else {
        context
    };

    match crate::agent::call_translator(
        &ctx.translator,
        target_lang,
        brief,
        effective_context,
        source_content,
    )
    .await
    {
        Ok(translated) => Ok(translated),
        Err(e) => Ok(format!("translation error: {}", e)),
    }
}

fn execute_validate_syntax(input: &serde_json::Value) -> Result<String> {
    let content = input.get("content").and_then(|v| v.as_str()).unwrap_or("");
    let format_str = input
        .get("format")
        .and_then(|v| v.as_str())
        .unwrap_or("text");

    let format = match format_str {
        "json" => Format::Json,
        "yaml" => Format::Yaml,
        "po" => Format::Po,
        "markdown" => Format::Markdown,
        _ => Format::Text,
    };

    match checks::validate_syntax(format, content) {
        Some(err) => Ok(format!("syntax error: {}", err)),
        None => Ok("ok".to_string()),
    }
}

fn execute_validate_preserve(input: &serde_json::Value) -> Result<String> {
    let translated = input
        .get("translated")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let source = input.get("source").and_then(|v| v.as_str()).unwrap_or("");

    let kinds_input: Vec<String> = input
        .get("preserve_kinds")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                .collect()
        })
        .unwrap_or_default();

    let kinds = checks::resolve_preserve(&kinds_input);

    match checks::validate_preserve(translated, source, &kinds) {
        Some(err) => Ok(format!("preserve error: {}", err)),
        None => Ok("ok".to_string()),
    }
}

fn execute_validate_po(input: &serde_json::Value) -> Result<String> {
    let content = input.get("content").and_then(|v| v.as_str()).unwrap_or("");
    let source = input.get("source").and_then(|v| v.as_str());

    match checks::validate_po_thorough(content, source) {
        Some(err) => Ok(format!("po validation error: {}", err)),
        None => Ok("ok".to_string()),
    }
}

async fn execute_run_check_command(
    input: &serde_json::Value,
    ctx: &ToolContext<'_>,
) -> Result<String> {
    let content = input.get("content").and_then(|v| v.as_str()).unwrap_or("");
    let command = input.get("command").and_then(|v| v.as_str()).unwrap_or("");

    if command.is_empty() {
        return Ok("error: command is required".to_string());
    }

    match checks::run_external(&ctx.root, command, content).await {
        Ok(()) => Ok("ok".to_string()),
        Err(e) => Ok(format!("check command error: {}", e)),
    }
}
