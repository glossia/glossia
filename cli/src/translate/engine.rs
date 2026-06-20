use anyhow::{anyhow, Result};

use crate::config::split_markdown_frontmatter;
use crate::format::Format;
use crate::llm::{chat, ChatMessage, TokenUsage};
use crate::translate::prompt::{build_system_prompt, build_user_prompt, SystemPromptInput};
use crate::validate::{validate_output, CheckOptions};

use super::plan::WorkItem;

#[derive(Debug, Clone)]
pub struct TranslationResult {
    pub text: String,
    pub usage: TokenUsage,
}

pub fn translate_item(
    root: &std::path::Path,
    item: &WorkItem,
    source_text: &str,
) -> Result<TranslationResult> {
    let mut usage = TokenUsage::default();
    let mut content = source_text.to_string();
    let mut frontmatter = None;

    if item.format == Format::Markdown
        && item.frontmatter_mode == crate::config::FrontmatterMode::Preserve
    {
        let split = split_markdown_frontmatter(source_text);
        if split.ok {
            frontmatter = Some(split.frontmatter);
            content = split.body;
        }
    }

    let context_body = item.context_body();
    let locale_override_body = item.locale_override_body();
    let system_prompt = build_system_prompt(SystemPromptInput {
        format: item.format,
        source_language: &item.source_language,
        locale: &item.locale,
        language: &item.language,
        context_body: &context_body,
        locale_override_body: &locale_override_body,
        frontmatter_preserved: frontmatter.is_some(),
        custom_prompt: item.prompt.as_deref(),
    });

    let attempts = item.retries.max(1);
    let mut last_error = None;

    for _ in 0..=attempts {
        let user_prompt = build_user_prompt(
            &item.source_language,
            &item.locale,
            &item.language,
            &content,
            last_error.as_deref(),
        );
        let (raw_text, call_usage) = chat(
            &item.llm,
            &[
                ChatMessage {
                    role: "system".into(),
                    content: system_prompt.clone(),
                },
                ChatMessage {
                    role: "user".into(),
                    content: user_prompt,
                },
            ],
        )?;
        usage = usage.add(call_usage);

        let stripped = strip_structured_code_fence(item.format, raw_text.trim_end());
        let final_text = match &frontmatter {
            Some(frontmatter) if !stripped.trim().is_empty() => {
                format!("{frontmatter}\n{stripped}")
            }
            Some(frontmatter) => format!("{frontmatter}\n"),
            None => stripped,
        };

        let check_options = CheckOptions {
            preserve: item.preserve.clone(),
            check_cmd: item.check_cmd.clone(),
            check_cmds: item.check_cmds.clone(),
            validation: item.validation.clone(),
            validation_cwd: item.validation_cwd.clone(),
            validation_doc_abs: item.validation_doc_abs.clone(),
            source_abs: Some(item.source_abs.clone()),
            target_abs: Some(item.output_abs.clone()),
            locale: Some(item.locale.clone()),
        };

        match validate_output(root, item.format, &final_text, source_text, &check_options) {
            Ok(()) => {
                return Ok(TranslationResult {
                    text: final_text,
                    usage,
                })
            }
            Err(error) => last_error = Some(error.to_string()),
        }
    }

    Err(anyhow!(
        "{}",
        last_error.unwrap_or_else(|| "translation failed".into())
    ))
}

fn strip_structured_code_fence(format: Format, text: &str) -> String {
    if !format.is_structured() {
        return text.to_string();
    }

    let trimmed = text.trim();
    if !trimmed.starts_with("```") || !trimmed.ends_with("```") {
        return text.to_string();
    }

    let mut lines = trimmed.lines();
    let _opening = lines.next();
    let mut collected = lines.collect::<Vec<_>>();
    if collected.last().copied() != Some("```") {
        return text.to_string();
    }
    let _ = collected.pop();
    collected.join("\n")
}
