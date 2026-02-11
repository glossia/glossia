use anyhow::{Result, bail};
use std::collections::HashMap;

use crate::checks::{CheckOptions, validate};
use crate::config::{AgentConfig, FRONTMATTER_PRESERVE};
use crate::format::Format;
use crate::llm::{
    ChatMessage, ChatResponse, ChatResult, ContentBlock, ToolMessage, ToolMessageContent, chat,
    chat_with_tools,
};
use crate::reporter::Reporter;
use crate::tools::{self, ToolContext, tools_summary};

pub struct TranslationRequest<'a> {
    pub source: String,
    pub target_lang: String,
    pub format: Format,
    pub context: String,
    pub preserve: Vec<String>,
    pub frontmatter: String,
    pub check_cmd: String,
    pub check_cmds: HashMap<String, String>,
    pub tool_reporter: Option<&'a dyn Reporter>,
    pub progress_label: String,
    pub progress_current: usize,
    pub progress_total: usize,
    pub retries: i32,
    pub coordinator: AgentConfig,
    pub translator: AgentConfig,
    pub root: String,
}

pub async fn translate(req: &TranslationRequest<'_>) -> Result<String> {
    let coordinator_model = req.coordinator.model.trim();
    if coordinator_model.is_empty() {
        return translate_non_agentic(req).await;
    }
    translate_agentic(req).await
}

/// The original non-agentic path: single-shot brief, translate, validate, retry loop.
async fn translate_non_agentic(req: &TranslationRequest<'_>) -> Result<String> {
    let mut content = req.source.clone();
    let mut frontmatter = String::new();

    if req.format == Format::Markdown && req.frontmatter == FRONTMATTER_PRESERVE {
        let split = split_markdown_frontmatter(&req.source);
        if split.ok {
            frontmatter = split.frontmatter;
            content = split.body;
        }
    }

    let brief = build_brief(req).await?;

    let mut attempts = req.retries;
    if attempts < 0 {
        attempts = 0;
    }

    let mut last_err: Option<anyhow::Error> = None;

    for _attempt in 0..=attempts {
        let translation = match translate_once(req, &brief, &content, last_err.as_ref()).await {
            Ok(t) => t,
            Err(e) => {
                last_err = Some(e);
                continue;
            }
        };

        let mut final_text = translation;
        if is_structured_format(req.format) {
            final_text = strip_code_fence(&final_text);
        }
        if !frontmatter.is_empty() {
            if final_text.trim().is_empty() {
                final_text = format!("{}\n", frontmatter);
            } else {
                final_text = format!("{}\n{}", frontmatter, final_text);
            }
        }

        let check_opts = CheckOptions {
            preserve: &req.preserve,
            check_cmd: if req.check_cmd.is_empty() {
                None
            } else {
                Some(&req.check_cmd)
            },
            check_cmds: if req.check_cmds.is_empty() {
                None
            } else {
                Some(&req.check_cmds)
            },
            reporter: req.tool_reporter,
            label: Some(&req.progress_label),
            current: req.progress_current,
            total: req.progress_total,
        };

        match validate(&req.root, req.format, &final_text, &req.source, &check_opts).await {
            Ok(()) => return Ok(final_text),
            Err(e) => {
                last_err = Some(e);
            }
        }
    }

    match last_err {
        Some(e) => Err(e),
        None => bail!("translation failed"),
    }
}

/// Agentic path: the coordinator uses tools to translate, validate, and retry.
async fn translate_agentic(req: &TranslationRequest<'_>) -> Result<String> {
    let mut content = req.source.clone();
    let mut frontmatter = String::new();

    if req.format == Format::Markdown && req.frontmatter == FRONTMATTER_PRESERVE {
        let split = split_markdown_frontmatter(&req.source);
        if split.ok {
            frontmatter = split.frontmatter;
            content = split.body;
        }
    }

    let has_check_cmd = !req.check_cmd.is_empty() || !req.check_cmds.is_empty();
    let tool_defs = tools::coordinator_tools(req.format, has_check_cmd);

    let tool_ctx = ToolContext {
        translator: req.translator.clone(),
        format: req.format,
        root: req.root.clone(),
        preserve: req.preserve.clone(),
        frontmatter: req.frontmatter.clone(),
        context: req.context.clone(),
        reporter: req.tool_reporter,
        check_cmd: req.check_cmd.clone(),
        check_cmds: req.check_cmds.clone(),
    };

    let available_tools: Vec<String> = tool_defs.iter().map(|t| t.name.clone()).collect();

    let mut validation_steps = vec![
        format!("2. Call `validate_syntax` with format=\"{}\"", req.format),
        "3. Call `validate_preserve` with the source and translated content".to_string(),
    ];
    let mut step_num = 4;
    if req.format == Format::Po {
        validation_steps.push(format!(
            "{}. Call `validate_po` to check PO structure, headers, plural forms, and format strings",
            step_num
        ));
        step_num += 1;
    }
    if has_check_cmd {
        validation_steps.push(format!(
            "{}. Call `run_check_command` with the configured command",
            step_num
        ));
        step_num += 1;
    }
    validation_steps.push(format!(
        "{}. If any validation fails, analyze the error, call `translate` again with a corrective brief, and re-validate",
        step_num
    ));
    let _ = step_num;

    let system_prompt = format!(
        "You are a localization coordinator agent. Your job is to produce a high-quality translation.\n\n\
         You have these tools: {}\n\n\
         Follow this process:\n\
         1. Call `translate` with the source content and target language\n\
         {}\n\n\
         When all validations pass, respond with ONLY the final translated text and nothing else.\n\
         Do not wrap the output in markdown fences or add any commentary.\n\
         Do not include any explanation, just the raw translated content.",
        available_tools.join(", "),
        validation_steps.join("\n"),
    );

    let mut user_prompt = format!(
        "Translate the following content to {}.\n\nFormat: {}\nPreserve: {}\nFrontmatter: {}\n",
        req.target_lang,
        req.format,
        if req.preserve.is_empty() {
            "code_blocks, inline_code, urls, placeholders".to_string()
        } else {
            req.preserve.join(", ")
        },
        req.frontmatter,
    );
    if !req.context.is_empty() {
        user_prompt.push_str(&format!("\nContext from L10N.md:\n{}\n", req.context));
    }
    user_prompt.push_str(&format!("\nSource content:\n{}", content));

    let mut messages: Vec<ToolMessage> = vec![
        ToolMessage {
            role: "system".to_string(),
            content: ToolMessageContent::Text(system_prompt),
        },
        ToolMessage {
            role: "user".to_string(),
            content: ToolMessageContent::Text(user_prompt),
        },
    ];

    let coordinator_model = req.coordinator.model.trim().to_string();
    let mut last_translation: Option<String> = None;

    const MAX_ITERATIONS: usize = 20;

    for _iteration in 0..MAX_ITERATIONS {
        let result: ChatResult =
            chat_with_tools(&req.coordinator, &coordinator_model, &messages, &tool_defs).await?;

        match result.response {
            ChatResponse::Text(text) => {
                let final_text = if text.trim().is_empty() {
                    last_translation.unwrap_or(text)
                } else {
                    text
                };

                let mut output = final_text;
                if is_structured_format(req.format) {
                    output = strip_code_fence(&output);
                }
                if !frontmatter.is_empty() {
                    if output.trim().is_empty() {
                        output = format!("{}\n", frontmatter);
                    } else {
                        output = format!("{}\n{}", frontmatter, output);
                    }
                }
                return Ok(output);
            }
            ChatResponse::ToolCalls(tool_calls) => {
                // Build assistant message with the tool calls
                let assistant_blocks: Vec<ContentBlock> = tool_calls
                    .iter()
                    .map(|tc| ContentBlock::ToolUse {
                        id: tc.id.clone(),
                        name: tc.name.clone(),
                        input: tc.input.clone(),
                    })
                    .collect();

                messages.push(ToolMessage {
                    role: "assistant".to_string(),
                    content: ToolMessageContent::Blocks(assistant_blocks),
                });

                // Execute each tool and collect results
                let mut result_blocks = Vec::new();
                let is_anthropic = req.coordinator.provider.to_lowercase().trim() == "anthropic";

                for tc in &tool_calls {
                    if let Some(reporter) = req.tool_reporter {
                        reporter.log(
                            crate::reporter::Verb::Checking,
                            &format!("coordinator: calling tool {}", tc.name),
                        );
                    }

                    let tool_result = tools::execute_tool(&tc.name, &tc.input, &tool_ctx).await?;

                    if let Some(reporter) = req.tool_reporter {
                        let flat = tool_result.replace('\n', " ");
                        let display = if flat.len() > 120 {
                            format!("{}... ({} chars)", &flat[..120], flat.len())
                        } else {
                            flat
                        };
                        reporter.log(
                            crate::reporter::Verb::Info,
                            &format!("  {} -> {}", tc.name, display),
                        );
                    }

                    // Track last successful translation
                    if tc.name == "translate" && !tool_result.starts_with("translation error:") {
                        last_translation = Some(tool_result.clone());
                    }

                    result_blocks.push(ContentBlock::ToolResult {
                        tool_use_id: tc.id.clone(),
                        content: tool_result,
                        is_error: None,
                    });
                }

                // For Anthropic: all tool results in one user message
                // For OpenAI: tool results as separate tool messages
                if is_anthropic {
                    messages.push(ToolMessage {
                        role: "user".to_string(),
                        content: ToolMessageContent::Blocks(result_blocks),
                    });
                } else {
                    for block in result_blocks {
                        messages.push(ToolMessage {
                            role: "tool".to_string(),
                            content: ToolMessageContent::Blocks(vec![block]),
                        });
                    }
                }
            }
        }
    }

    // Exhausted iterations, return last translation if we have one
    match last_translation {
        Some(t) => {
            let mut output = t;
            if is_structured_format(req.format) {
                output = strip_code_fence(&output);
            }
            if !frontmatter.is_empty() {
                if output.trim().is_empty() {
                    output = format!("{}\n", frontmatter);
                } else {
                    output = format!("{}\n{}", frontmatter, output);
                }
            }
            Ok(output)
        }
        None => bail!("coordinator exhausted iterations without producing a translation"),
    }
}

/// Called by the translate tool executor and also usable directly.
pub async fn call_translator(
    cfg: &AgentConfig,
    target_lang: &str,
    brief: &str,
    context: &str,
    content: &str,
) -> Result<String> {
    let model = cfg.model.trim();
    if model.is_empty() {
        bail!("translator model is required");
    }

    let system = if brief.is_empty() {
        "You are a translation engine. Translate faithfully and naturally. Return only the translated content.".to_string()
    } else {
        format!("You are a translation engine. Follow this brief:\n{}", brief)
    };

    let user = format!(
        "Translate to {}.\n\nContext:\n{}\n\nSource:\n{}",
        target_lang, context, content
    );

    let messages = vec![
        ChatMessage {
            role: "system".to_string(),
            content: system,
        },
        ChatMessage {
            role: "user".to_string(),
            content: user,
        },
    ];

    let resp = chat(cfg, model, &messages).await?;
    Ok(resp.trim_end_matches('\n').to_string())
}

async fn build_brief(req: &TranslationRequest<'_>) -> Result<String> {
    let model = req.coordinator.model.trim();
    if model.is_empty() {
        return Ok(default_brief(req));
    }

    let prompt = format!(
        "You are a localization coordinator.\n\
         Create a short translation brief for the translator.\n\
         The brief must be plain text and under 12 lines.\n\n\
         Target language: {}\n\
         Format: {}\n\
         Preserve: {}\n\
         Frontmatter mode: {}\n\
         Tools: {}\n\n\
         Context:\n{}",
        req.target_lang,
        req.format,
        req.preserve.join(", "),
        req.frontmatter,
        tools_summary(),
        req.context,
    );

    let messages = vec![
        ChatMessage {
            role: "system".to_string(),
            content: "You coordinate translations and produce concise briefs.".to_string(),
        },
        ChatMessage {
            role: "user".to_string(),
            content: prompt,
        },
    ];

    let resp = chat(&req.coordinator, model, &messages).await?;
    Ok(resp.trim().to_string())
}

fn default_brief(req: &TranslationRequest) -> String {
    let mut lines = vec![
        "Translate the content faithfully and naturally.".to_string(),
        "Preserve code blocks, inline code, URLs, and placeholders.".to_string(),
        "Keep formatting, lists, and headings intact.".to_string(),
        "Return only the translated content.".to_string(),
    ];
    if is_structured_format(req.format) {
        lines.push(format!(
            "Return valid {} only. Do not wrap in markdown fences.",
            req.format
        ));
    }
    if req.frontmatter == FRONTMATTER_PRESERVE {
        lines.push("Frontmatter is preserved separately; do not add new frontmatter.".to_string());
    }
    lines.push(format!("Tools run after translation: {}.", tools_summary()));
    lines.join("\n")
}

async fn translate_once(
    req: &TranslationRequest<'_>,
    brief: &str,
    content: &str,
    last_err: Option<&anyhow::Error>,
) -> Result<String> {
    let model = req.translator.model.trim();
    if model.is_empty() {
        bail!("translator model is required");
    }

    let mut user = format!(
        "Translate to {}.\n\nContext:\n{}\n\nSource:\n{}",
        req.target_lang, req.context, content
    );
    if let Some(err) = last_err {
        user.push_str(&format!(
            "\n\nPrevious output failed validation: {}\nReturn a corrected full translation.",
            err
        ));
    }

    let messages = vec![
        ChatMessage {
            role: "system".to_string(),
            content: format!(
                "You are a translation engine. Follow this brief:\n{}",
                brief
            ),
        },
        ChatMessage {
            role: "user".to_string(),
            content: user,
        },
    ];

    let resp = chat(&req.translator, model, &messages).await?;
    Ok(resp.trim_end_matches('\n').to_string())
}

struct FrontmatterSplit {
    frontmatter: String,
    body: String,
    ok: bool,
}

fn split_markdown_frontmatter(contents: &str) -> FrontmatterSplit {
    let lines: Vec<&str> = contents.split('\n').collect();
    if lines.is_empty() {
        return FrontmatterSplit {
            frontmatter: String::new(),
            body: contents.to_string(),
            ok: false,
        };
    }
    let marker = lines[0].trim();
    if marker != "---" && marker != "+++" {
        return FrontmatterSplit {
            frontmatter: String::new(),
            body: contents.to_string(),
            ok: false,
        };
    }

    let mut end = None;
    for (i, line) in lines.iter().enumerate().skip(1) {
        if line.trim() == marker {
            end = Some(i);
            break;
        }
    }
    let end = match end {
        Some(e) => e,
        None => {
            return FrontmatterSplit {
                frontmatter: String::new(),
                body: contents.to_string(),
                ok: false,
            };
        }
    };

    let frontmatter = lines[..=end].join("\n");
    let body = lines[end + 1..].join("\n");
    FrontmatterSplit {
        frontmatter,
        body,
        ok: true,
    }
}

fn is_structured_format(format: Format) -> bool {
    matches!(format, Format::Json | Format::Yaml | Format::Po)
}

fn strip_code_fence(content: &str) -> String {
    let trimmed = content.trim();
    if !trimmed.starts_with("```") {
        return content.to_string();
    }
    let lines: Vec<&str> = trimmed.split('\n').collect();
    if lines.len() < 2 {
        return content.to_string();
    }
    if !lines[0].trim().starts_with("```") {
        return content.to_string();
    }
    if lines[lines.len() - 1].trim() != "```" {
        return content.to_string();
    }
    lines[1..lines.len() - 1].join("\n")
}
