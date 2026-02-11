use anyhow::{Result, bail};
use std::collections::HashMap;

use crate::checks::{CheckOptions, validate};
use crate::config::{AgentConfig, FRONTMATTER_PRESERVE};
use crate::format::Format;
use crate::llm::{ChatMessage, chat};
use crate::reporter::Reporter;
use crate::tools::tools_summary;

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
