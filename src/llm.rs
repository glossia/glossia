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

// Tool-use types (provider-agnostic)

#[derive(Debug, Clone, Serialize)]
pub struct ToolDefinition {
    pub name: String,
    pub description: String,
    pub input_schema: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum ContentBlock {
    #[serde(rename = "text")]
    Text { text: String },
    #[serde(rename = "tool_use")]
    ToolUse {
        id: String,
        name: String,
        input: serde_json::Value,
    },
    #[serde(rename = "tool_result")]
    ToolResult {
        tool_use_id: String,
        content: String,
        #[serde(skip_serializing_if = "Option::is_none")]
        is_error: Option<bool>,
    },
}

#[derive(Debug, Clone)]
pub enum ToolMessageContent {
    Text(String),
    Blocks(Vec<ContentBlock>),
}

#[derive(Debug, Clone)]
pub struct ToolMessage {
    pub role: String,
    pub content: ToolMessageContent,
}

#[derive(Debug, Clone)]
pub struct ToolCall {
    pub id: String,
    pub name: String,
    pub input: serde_json::Value,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StopReason {
    EndTurn,
    ToolUse,
    MaxTokens,
}

#[derive(Debug, Clone)]
pub enum ChatResponse {
    Text(String),
    ToolCalls(Vec<ToolCall>),
}

#[derive(Debug, Clone)]
pub struct ChatResult {
    pub response: ChatResponse,
    pub stop_reason: StopReason,
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

// --- Tool-use API ---

const DEFAULT_TOOL_TIMEOUT_SECS: u64 = 120;

pub async fn chat_with_tools(
    cfg: &AgentConfig,
    model: &str,
    messages: &[ToolMessage],
    tools: &[ToolDefinition],
) -> Result<ChatResult> {
    let provider = cfg.provider.to_lowercase();
    let provider = provider.trim();
    if provider == "anthropic" {
        return chat_with_tools_anthropic(cfg, model, messages, tools).await;
    }
    chat_with_tools_openai(cfg, model, messages, tools).await
}

// --- Anthropic tool-use wire types ---

#[derive(Debug, Serialize)]
struct AnthropicToolDef {
    name: String,
    description: String,
    input_schema: serde_json::Value,
}

#[derive(Debug, Serialize)]
struct AnthropicToolRequest {
    model: String,
    max_tokens: u32,
    messages: Vec<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    temperature: Option<f64>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    tools: Vec<AnthropicToolDef>,
}

#[derive(Debug, Deserialize)]
struct AnthropicToolResponse {
    content: Option<Vec<serde_json::Value>>,
    stop_reason: Option<String>,
    error: Option<APIError>,
}

async fn chat_with_tools_anthropic(
    cfg: &AgentConfig,
    model: &str,
    messages: &[ToolMessage],
    tools: &[ToolDefinition],
) -> Result<ChatResult> {
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
                if let ToolMessageContent::Text(ref t) = msg.content
                    && !t.trim().is_empty()
                {
                    system_parts.push(t.clone());
                }
            }
            "user" => {
                let content = match &msg.content {
                    ToolMessageContent::Text(t) => serde_json::json!(t),
                    ToolMessageContent::Blocks(blocks) => {
                        let arr: Vec<serde_json::Value> = blocks
                            .iter()
                            .map(|b| match b {
                                ContentBlock::Text { text } => {
                                    serde_json::json!({"type": "text", "text": text})
                                }
                                ContentBlock::ToolResult {
                                    tool_use_id,
                                    content,
                                    is_error,
                                } => {
                                    let mut v = serde_json::json!({
                                        "type": "tool_result",
                                        "tool_use_id": tool_use_id,
                                        "content": content
                                    });
                                    if let Some(true) = is_error {
                                        v["is_error"] = serde_json::json!(true);
                                    }
                                    v
                                }
                                ContentBlock::ToolUse { id, name, input } => {
                                    serde_json::json!({
                                        "type": "tool_use",
                                        "id": id,
                                        "name": name,
                                        "input": input
                                    })
                                }
                            })
                            .collect();
                        serde_json::json!(arr)
                    }
                };
                anth_messages.push(serde_json::json!({"role": "user", "content": content}));
            }
            "assistant" => {
                let content = match &msg.content {
                    ToolMessageContent::Text(t) => serde_json::json!(t),
                    ToolMessageContent::Blocks(blocks) => {
                        let arr: Vec<serde_json::Value> = blocks
                            .iter()
                            .map(|b| match b {
                                ContentBlock::Text { text } => {
                                    serde_json::json!({"type": "text", "text": text})
                                }
                                ContentBlock::ToolUse { id, name, input } => {
                                    serde_json::json!({
                                        "type": "tool_use",
                                        "id": id,
                                        "name": name,
                                        "input": input
                                    })
                                }
                                ContentBlock::ToolResult {
                                    tool_use_id,
                                    content,
                                    is_error,
                                } => {
                                    let mut v = serde_json::json!({
                                        "type": "tool_result",
                                        "tool_use_id": tool_use_id,
                                        "content": content
                                    });
                                    if let Some(true) = is_error {
                                        v["is_error"] = serde_json::json!(true);
                                    }
                                    v
                                }
                            })
                            .collect();
                        serde_json::json!(arr)
                    }
                };
                anth_messages.push(serde_json::json!({"role": "assistant", "content": content}));
            }
            _ => bail!("unsupported message role \"{}\" for anthropic", msg.role),
        }
    }

    if anth_messages.is_empty() {
        bail!("llm request requires user messages");
    }

    let max_tokens = cfg.max_tokens.filter(|&mt| mt > 0).unwrap_or(4096);

    let anth_tools: Vec<AnthropicToolDef> = tools
        .iter()
        .map(|t| AnthropicToolDef {
            name: t.name.clone(),
            description: t.description.clone(),
            input_schema: t.input_schema.clone(),
        })
        .collect();

    let req_body = AnthropicToolRequest {
        model: model.to_string(),
        max_tokens,
        messages: anth_messages,
        system: if system_parts.is_empty() {
            None
        } else {
            Some(system_parts.join("\n\n"))
        },
        temperature: cfg.temperature,
        tools: anth_tools,
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
        DEFAULT_TOOL_TIMEOUT_SECS
    };

    let client = reqwest::Client::new();
    let mut req = client.post(&url).timeout(Duration::from_secs(timeout));
    for (k, v) in &headers_map {
        req = req.header(k, v);
    }

    let resp = req.json(&req_body).send().await?;
    let status = resp.status();
    let parsed: AnthropicToolResponse = resp.json().await?;

    if status.as_u16() >= 400 {
        if let Some(err) = parsed.error {
            bail!("llm error: {}", err.message);
        }
        bail!("llm error: status {}", status);
    }

    let content = parsed.content.unwrap_or_default();
    let stop = parsed.stop_reason.as_deref().unwrap_or("end_turn");

    let stop_reason = match stop {
        "tool_use" => StopReason::ToolUse,
        "max_tokens" => StopReason::MaxTokens,
        _ => StopReason::EndTurn,
    };

    let mut tool_calls = Vec::new();
    let mut text_parts = Vec::new();

    for block in &content {
        let btype = block.get("type").and_then(|v| v.as_str()).unwrap_or("");
        match btype {
            "tool_use" => {
                let id = block
                    .get("id")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string();
                let name = block
                    .get("name")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string();
                let input = block
                    .get("input")
                    .cloned()
                    .unwrap_or(serde_json::json!({}));
                tool_calls.push(ToolCall { id, name, input });
            }
            "text" => {
                if let Some(t) = block.get("text").and_then(|v| v.as_str()) {
                    text_parts.push(t.to_string());
                }
            }
            _ => {}
        }
    }

    if stop_reason == StopReason::ToolUse && !tool_calls.is_empty() {
        return Ok(ChatResult {
            response: ChatResponse::ToolCalls(tool_calls),
            stop_reason,
        });
    }

    let text = text_parts.join("");
    if text.is_empty() && tool_calls.is_empty() {
        bail!("llm response missing content");
    }

    Ok(ChatResult {
        response: ChatResponse::Text(text),
        stop_reason,
    })
}

// --- OpenAI tool-use wire types ---

#[derive(Debug, Serialize)]
struct OpenAIToolDef {
    #[serde(rename = "type")]
    tool_type: String,
    function: OpenAIFunctionDef,
}

#[derive(Debug, Serialize)]
struct OpenAIFunctionDef {
    name: String,
    description: String,
    parameters: serde_json::Value,
}

#[derive(Debug, Serialize)]
struct OpenAIToolRequest {
    model: String,
    messages: Vec<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    temperature: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    max_tokens: Option<u32>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    tools: Vec<OpenAIToolDef>,
}

#[derive(Debug, Deserialize)]
struct OpenAIToolResponse {
    choices: Option<Vec<OpenAIToolChoice>>,
    error: Option<APIError>,
}

#[derive(Debug, Deserialize)]
struct OpenAIToolChoice {
    message: OpenAIToolMessage,
    finish_reason: Option<String>,
}

#[derive(Debug, Deserialize)]
struct OpenAIToolMessage {
    role: Option<String>,
    content: Option<String>,
    #[serde(default)]
    tool_calls: Vec<OpenAIToolCallWire>,
}

#[derive(Debug, Deserialize)]
struct OpenAIToolCallWire {
    id: String,
    function: OpenAIFunctionCall,
}

#[derive(Debug, Deserialize)]
struct OpenAIFunctionCall {
    name: String,
    arguments: String,
}

async fn chat_with_tools_openai(
    cfg: &AgentConfig,
    model: &str,
    messages: &[ToolMessage],
    tools: &[ToolDefinition],
) -> Result<ChatResult> {
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

    let mut oai_messages: Vec<serde_json::Value> = Vec::new();

    for msg in messages {
        let role = msg.role.to_lowercase();
        let role = role.trim();
        match role {
            "system" | "user" => {
                let text = match &msg.content {
                    ToolMessageContent::Text(t) => t.clone(),
                    ToolMessageContent::Blocks(_) => {
                        bail!("OpenAI system/user messages must be text")
                    }
                };
                oai_messages.push(serde_json::json!({"role": role, "content": text}));
            }
            "assistant" => match &msg.content {
                ToolMessageContent::Text(t) => {
                    oai_messages.push(serde_json::json!({"role": "assistant", "content": t}));
                }
                ToolMessageContent::Blocks(blocks) => {
                    let mut tool_calls_arr = Vec::new();
                    let mut text_content = String::new();
                    for b in blocks {
                        match b {
                            ContentBlock::ToolUse { id, name, input } => {
                                tool_calls_arr.push(serde_json::json!({
                                    "id": id,
                                    "type": "function",
                                    "function": {
                                        "name": name,
                                        "arguments": serde_json::to_string(input).unwrap_or_default()
                                    }
                                }));
                            }
                            ContentBlock::Text { text } => {
                                text_content.push_str(text);
                            }
                            _ => {}
                        }
                    }
                    let mut msg_obj =
                        serde_json::json!({"role": "assistant", "content": text_content});
                    if !tool_calls_arr.is_empty() {
                        msg_obj["tool_calls"] = serde_json::json!(tool_calls_arr);
                    }
                    oai_messages.push(msg_obj);
                }
            },
            "tool" => {
                if let ToolMessageContent::Blocks(blocks) = &msg.content {
                    for b in blocks {
                        if let ContentBlock::ToolResult {
                            tool_use_id,
                            content,
                            ..
                        } = b
                        {
                            oai_messages.push(serde_json::json!({
                                "role": "tool",
                                "tool_call_id": tool_use_id,
                                "content": content
                            }));
                        }
                    }
                }
            }
            _ => bail!("unsupported message role \"{}\" for openai", msg.role),
        }
    }

    let oai_tools: Vec<OpenAIToolDef> = tools
        .iter()
        .map(|t| OpenAIToolDef {
            tool_type: "function".to_string(),
            function: OpenAIFunctionDef {
                name: t.name.clone(),
                description: t.description.clone(),
                parameters: t.input_schema.clone(),
            },
        })
        .collect();

    let req_body = OpenAIToolRequest {
        model: model.to_string(),
        messages: oai_messages,
        temperature: cfg.temperature,
        max_tokens: cfg.max_tokens,
        tools: oai_tools,
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
        DEFAULT_TOOL_TIMEOUT_SECS
    };

    let client = reqwest::Client::new();
    let mut req = client.post(&url).timeout(Duration::from_secs(timeout));
    for (k, v) in &headers_map {
        req = req.header(k, v);
    }

    let resp = req.json(&req_body).send().await?;
    let status = resp.status();
    let parsed: OpenAIToolResponse = resp.json().await?;

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

    let choice = &choices[0];
    let finish = choice.finish_reason.as_deref().unwrap_or("stop");

    let stop_reason = match finish {
        "tool_calls" => StopReason::ToolUse,
        "length" => StopReason::MaxTokens,
        _ => StopReason::EndTurn,
    };

    if !choice.message.tool_calls.is_empty() {
        let tool_calls: Vec<ToolCall> = choice
            .message
            .tool_calls
            .iter()
            .map(|tc| {
                let input: serde_json::Value =
                    serde_json::from_str(&tc.function.arguments).unwrap_or(serde_json::json!({}));
                ToolCall {
                    id: tc.id.clone(),
                    name: tc.function.name.clone(),
                    input,
                }
            })
            .collect();
        return Ok(ChatResult {
            response: ChatResponse::ToolCalls(tool_calls),
            stop_reason,
        });
    }

    let text = choice.message.content.clone().unwrap_or_default();
    Ok(ChatResult {
        response: ChatResponse::Text(text),
        stop_reason,
    })
}
