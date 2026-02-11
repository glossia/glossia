use anyhow::{Result, bail};
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::Duration;

use crate::config::AgentConfig;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Serialize)]
struct OpenAIChatRequest {
    model: String,
    messages: Vec<ChatMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    temperature: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    max_tokens: Option<u32>,
}

#[derive(Debug, Deserialize)]
struct OpenAIChatResponse {
    choices: Option<Vec<OpenAIChoice>>,
    error: Option<APIError>,
}

#[derive(Debug, Deserialize)]
struct OpenAIChoice {
    message: ChatMessage,
}

#[derive(Debug, Deserialize)]
struct APIError {
    message: String,
}

#[derive(Debug, Serialize)]
struct AnthropicMessage {
    role: String,
    content: String,
}

#[derive(Debug, Serialize)]
struct AnthropicRequest {
    model: String,
    max_tokens: u32,
    messages: Vec<AnthropicMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    temperature: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct AnthropicResponse {
    content: Option<Vec<AnthropicContent>>,
    error: Option<APIError>,
}

#[derive(Debug, Deserialize)]
struct AnthropicContent {
    #[serde(rename = "type")]
    content_type: String,
    text: Option<String>,
}

const DEFAULT_ANTHROPIC_VERSION: &str = "2023-06-01";
const DEFAULT_ANTHROPIC_MAX_TOKENS: u32 = 1024;
const DEFAULT_TIMEOUT_SECS: u64 = 60;

fn expand_env_templates(value: &str) -> String {
    let re = Regex::new(r"\{\{\s*env\.([A-Za-z_][A-Za-z0-9_]*)\s*\}\}").unwrap();
    re.replace_all(value, |caps: &regex::Captures| {
        let name = &caps[1];
        std::env::var(name).unwrap_or_default()
    })
    .to_string()
}

fn expand_env(value: &str) -> String {
    let expanded = expand_env_templates(value);
    if let Some(stripped) = expanded.strip_prefix("env.") {
        return std::env::var(stripped).unwrap_or_default();
    }
    let parts: Vec<&str> = expanded.splitn(2, "env:").collect();
    if parts.len() == 1 {
        return expanded;
    }

    // Handle env: prefixed values
    let mut out = parts[0].to_string();
    let mut remaining = &expanded[parts[0].len()..];

    while let Some(idx) = remaining.find("env:") {
        out.push_str(&remaining[..idx]);
        let after = &remaining[idx + 4..];
        let end = after.find(['/', ' ', '\t']).unwrap_or(after.len());
        let name = &after[..end];
        out.push_str(&std::env::var(name).unwrap_or_default());
        out.push_str(&after[end..]);
        remaining = "";
    }
    if !remaining.is_empty() {
        out.push_str(remaining);
    }

    out
}

fn has_header(headers: &HashMap<String, String>, name: &str) -> bool {
    let lower = name.to_lowercase();
    headers.keys().any(|k| k.to_lowercase() == lower)
}

fn resolve_headers(cfg: &AgentConfig) -> HashMap<String, String> {
    let mut headers = HashMap::new();
    for (k, v) in &cfg.headers {
        headers.insert(k.clone(), expand_env(v));
    }

    let provider = cfg.provider.to_lowercase();
    let provider = provider.trim();

    match provider {
        "anthropic" => {
            if !has_header(&headers, "x-api-key") {
                let mut key = expand_env(&cfg.api_key).trim().to_string();
                if key.is_empty() && !cfg.api_key_env.is_empty() {
                    key = std::env::var(&cfg.api_key_env).unwrap_or_default();
                }
                if !key.is_empty() {
                    headers.insert("x-api-key".to_string(), key);
                }
            }
            if !has_header(&headers, "anthropic-version") {
                headers.insert(
                    "anthropic-version".to_string(),
                    DEFAULT_ANTHROPIC_VERSION.to_string(),
                );
            }
        }
        _ => {
            if !has_header(&headers, "authorization") {
                let mut key = expand_env(&cfg.api_key).trim().to_string();
                if key.is_empty() && !cfg.api_key_env.is_empty() {
                    key = std::env::var(&cfg.api_key_env).unwrap_or_default();
                }
                if !key.is_empty() {
                    headers.insert("Authorization".to_string(), format!("Bearer {}", key));
                }
            }
        }
    }

    headers
}

pub async fn chat(cfg: &AgentConfig, model: &str, messages: &[ChatMessage]) -> Result<String> {
    let provider = cfg.provider.to_lowercase();
    let provider = provider.trim();
    if provider == "anthropic" {
        return chat_anthropic(cfg, model, messages).await;
    }
    chat_openai(cfg, model, messages).await
}

async fn chat_openai(cfg: &AgentConfig, model: &str, messages: &[ChatMessage]) -> Result<String> {
    if cfg.base_url.trim().is_empty() {
        bail!("llm base_url is required");
    }
    if model.trim().is_empty() {
        bail!("llm model is required");
    }

    let url = format!(
        "{}{}",
        cfg.base_url.trim_end_matches('/'),
        cfg.chat_completions_path
    );

    let body = OpenAIChatRequest {
        model: model.to_string(),
        messages: messages.to_vec(),
        temperature: cfg.temperature,
        max_tokens: cfg.max_tokens,
    };

    let mut headers_map = resolve_headers(cfg);
    headers_map
        .entry("Content-Type".to_string())
        .or_insert_with(|| "application/json".to_string());
    headers_map
        .entry("User-Agent".to_string())
        .or_insert_with(|| "l10n".to_string());

    let timeout = if cfg.timeout_seconds > 0 {
        cfg.timeout_seconds
    } else {
        DEFAULT_TIMEOUT_SECS
    };

    let client = reqwest::Client::new();
    let mut req = client.post(&url).timeout(Duration::from_secs(timeout));

    for (k, v) in &headers_map {
        req = req.header(k, v);
    }

    let resp = req.json(&body).send().await?;
    let status = resp.status();
    let parsed: OpenAIChatResponse = resp.json().await?;

    if status.as_u16() >= 400 {
        if let Some(err) = parsed.error {
            bail!("llm error: {}", err.message);
        }
        bail!("llm error: status {}", status);
    }

    let choices = parsed.choices.unwrap_or_default();
    if choices.is_empty() {
        bail!("llm response missing choices");
    }
    Ok(choices[0].message.content.clone())
}

async fn chat_anthropic(
    cfg: &AgentConfig,
    model: &str,
    messages: &[ChatMessage],
) -> Result<String> {
    if cfg.base_url.trim().is_empty() {
        bail!("llm base_url is required");
    }
    if model.trim().is_empty() {
        bail!("llm model is required");
    }

    let url = format!(
        "{}{}",
        cfg.base_url.trim_end_matches('/'),
        cfg.chat_completions_path
    );

    let mut system_parts = Vec::new();
    let mut anth_messages = Vec::new();
    for msg in messages {
        let role = msg.role.to_lowercase();
        let role = role.trim();
        match role {
            "system" => {
                if !msg.content.trim().is_empty() {
                    system_parts.push(msg.content.clone());
                }
            }
            "user" | "assistant" => {
                anth_messages.push(AnthropicMessage {
                    role: role.to_string(),
                    content: msg.content.clone(),
                });
            }
            _ => bail!("unsupported message role \"{}\" for anthropic", msg.role),
        }
    }
    if anth_messages.is_empty() {
        bail!("llm request requires user messages");
    }

    let max_tokens = if let Some(mt) = cfg.max_tokens {
        if mt > 0 {
            mt
        } else {
            DEFAULT_ANTHROPIC_MAX_TOKENS
        }
    } else {
        DEFAULT_ANTHROPIC_MAX_TOKENS
    };

    let req_body = AnthropicRequest {
        model: model.to_string(),
        max_tokens,
        messages: anth_messages,
        system: if system_parts.is_empty() {
            None
        } else {
            Some(system_parts.join("\n\n"))
        },
        temperature: cfg.temperature,
    };

    let mut headers_map = resolve_headers(cfg);
    headers_map
        .entry("Content-Type".to_string())
        .or_insert_with(|| "application/json".to_string());
    headers_map
        .entry("User-Agent".to_string())
        .or_insert_with(|| "l10n".to_string());

    let timeout = if cfg.timeout_seconds > 0 {
        cfg.timeout_seconds
    } else {
        DEFAULT_TIMEOUT_SECS
    };

    let client = reqwest::Client::new();
    let mut req = client.post(&url).timeout(Duration::from_secs(timeout));

    for (k, v) in &headers_map {
        req = req.header(k, v);
    }

    let resp = req.json(&req_body).send().await?;
    let status = resp.status();
    let parsed: AnthropicResponse = resp.json().await?;

    if status.as_u16() >= 400 {
        if let Some(err) = parsed.error {
            bail!("llm error: {}", err.message);
        }
        bail!("llm error: status {}", status);
    }

    let content = parsed.content.unwrap_or_default();
    if content.is_empty() {
        bail!("llm response missing content");
    }
    let text: String = content
        .iter()
        .filter(|b| b.content_type == "text")
        .filter_map(|b| b.text.as_ref())
        .cloned()
        .collect::<Vec<_>>()
        .join("");

    if text.is_empty() {
        bail!("llm response missing text");
    }
    Ok(text)
}
