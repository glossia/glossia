use anyhow::{anyhow, Result};
use reqwest::blocking::Client;
use reqwest::header::{
    HeaderMap, HeaderName, HeaderValue, AUTHORIZATION, CONTENT_TYPE, USER_AGENT,
};
use reqwest::StatusCode;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::thread;
use std::time::Duration;

use crate::config::Frontmatter;
use crate::runtime_config::RuntimeLlmConfig;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Clone, Copy, Default)]
pub struct TokenUsage {
    pub prompt_tokens: usize,
    pub completion_tokens: usize,
    pub total_tokens: usize,
}

impl TokenUsage {
    pub fn add(self, next: Self) -> Self {
        Self {
            prompt_tokens: self.prompt_tokens + next.prompt_tokens,
            completion_tokens: self.completion_tokens + next.completion_tokens,
            total_tokens: self.total_tokens + next.total_tokens,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Transport {
    OpenAi,
    Anthropic,
}

#[derive(Debug, Clone)]
pub struct LlmConfig {
    pub provider: String,
    transport: Transport,
    pub base_url: String,
    pub chat_path: String,
    pub api_key: Option<String>,
    pub api_key_env: Option<String>,
    pub model: String,
    pub temperature: Option<f64>,
    pub max_tokens: Option<u32>,
    pub timeout_seconds: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct ResolvedModelIdentifier {
    provider: String,
    request_model: String,
}

impl LlmConfig {
    pub fn from_frontmatter(frontmatter: &Frontmatter, runtime: &RuntimeLlmConfig) -> Result<Self> {
        let declared_model = frontmatter
            .model
            .clone()
            .filter(|value| !value.trim().is_empty())
            .ok_or_else(|| anyhow!("frontmatter model is required"))?;
        let resolved_model = resolve_model_identifier(
            &declared_model,
            runtime
                .provider
                .as_deref()
                .or(frontmatter.provider.as_deref()),
        )?;

        let mut resolved = Self {
            provider: resolved_model.provider.clone(),
            transport: Transport::OpenAi,
            base_url: runtime
                .base_url
                .clone()
                .or_else(|| frontmatter.base_url.clone())
                .unwrap_or_default(),
            chat_path: runtime
                .chat_completions_path
                .clone()
                .or_else(|| {
                    frontmatter
                        .chat_completions_path
                        .clone()
                        .filter(|value| !value.trim().is_empty())
                })
                .unwrap_or_default(),
            api_key: runtime
                .api_key
                .clone()
                .or_else(|| frontmatter.api_key.clone()),
            api_key_env: runtime
                .api_key_env
                .clone()
                .or_else(|| frontmatter.api_key_env.clone()),
            model: resolved_model.request_model,
            temperature: runtime.temperature.or(frontmatter.temperature),
            max_tokens: runtime.max_tokens.or(frontmatter.max_tokens),
            timeout_seconds: runtime
                .timeout_seconds
                .or(frontmatter.timeout_seconds)
                .unwrap_or(300),
        };

        match resolved.provider.as_str() {
            "openai" => {
                resolved.transport = Transport::OpenAi;
                if resolved.base_url.trim().is_empty() {
                    resolved.base_url = "https://api.openai.com/v1".into();
                }
                if resolved.chat_path.trim().is_empty() {
                    resolved.chat_path = "/chat/completions".into();
                }
                if resolved.api_key_env.is_none() {
                    resolved.api_key_env = Some("OPENAI_API_KEY".into());
                }
            }
            "gemini" => {
                resolved.transport = Transport::OpenAi;
                if resolved.base_url.trim().is_empty() {
                    resolved.base_url =
                        "https://generativelanguage.googleapis.com/v1beta/openai".into();
                }
                if resolved.chat_path.trim().is_empty() {
                    resolved.chat_path = "/chat/completions".into();
                }
                if resolved.api_key_env.is_none() {
                    resolved.api_key_env = Some("GEMINI_API_KEY".into());
                }
            }
            "ollama" => {
                resolved.transport = Transport::OpenAi;
                if resolved.base_url.trim().is_empty() {
                    resolved.base_url = "http://localhost:11434/v1".into();
                }
                if resolved.chat_path.trim().is_empty() {
                    resolved.chat_path = "/chat/completions".into();
                }
            }
            "anthropic" => {
                resolved.transport = Transport::Anthropic;
                if resolved.base_url.trim().is_empty() {
                    resolved.base_url = "https://api.anthropic.com".into();
                }
                if resolved.chat_path.trim().is_empty() {
                    resolved.chat_path = "/v1/messages".into();
                }
                if resolved.api_key_env.is_none() {
                    resolved.api_key_env = Some("ANTHROPIC_API_KEY".into());
                }
            }
            "glossia" => {
                resolved.transport = Transport::OpenAi;
                if resolved.chat_path.trim().is_empty() {
                    resolved.chat_path = "/chat/completions".into();
                }
                if resolved.api_key_env.is_none() {
                    resolved.api_key_env = Some("GLOSSIA_API_KEY".into());
                }
            }
            _ => {
                resolved.transport = Transport::OpenAi;
                if resolved.chat_path.trim().is_empty() {
                    resolved.chat_path = "/chat/completions".into();
                }
            }
        }

        if resolved.base_url.trim().is_empty() {
            return Err(anyhow!(
                "frontmatter base_url is required for provider {}",
                resolved.provider
            ));
        }

        Ok(resolved)
    }

    fn resolved_api_key(&self) -> Result<Option<String>> {
        if let Some(api_key) = &self.api_key {
            return Ok(Some(api_key.clone()));
        }

        if let Some(env_name) = &self.api_key_env {
            match std::env::var(env_name) {
                Ok(value) if !value.trim().is_empty() => Ok(Some(value)),
                Ok(_) => Err(anyhow!("environment variable {env_name} is empty")),
                Err(_) if self.provider == "ollama" => Ok(None),
                Err(_) => Err(anyhow!("missing environment variable {env_name}")),
            }
        } else {
            Ok(None)
        }
    }
}

fn resolve_model_identifier(
    model: &str,
    explicit_provider: Option<&str>,
) -> Result<ResolvedModelIdentifier> {
    let model = model.trim();
    let explicit_provider = explicit_provider
        .map(str::trim)
        .filter(|value| !value.is_empty());

    if let Some(explicit_provider) = explicit_provider {
        if let Some((qualified_provider, request_model)) = split_legacy_qualified_model(model) {
            if qualified_provider != explicit_provider {
                return Err(anyhow!(
                    "frontmatter model {} conflicts with configured provider {}",
                    model,
                    explicit_provider
                ));
            }

            return Ok(ResolvedModelIdentifier {
                provider: explicit_provider.to_string(),
                request_model: request_model.to_string(),
            });
        }

        return Ok(ResolvedModelIdentifier {
            provider: explicit_provider.to_string(),
            request_model: model.to_string(),
        });
    }

    if let Some((provider, request_model)) = split_legacy_qualified_model(model) {
        return Ok(ResolvedModelIdentifier {
            provider: provider.to_string(),
            request_model: request_model.to_string(),
        });
    }

    Ok(ResolvedModelIdentifier {
        provider: infer_provider_from_model(model),
        request_model: model.to_string(),
    })
}

fn split_legacy_qualified_model(model: &str) -> Option<(&str, &str)> {
    let (provider, request_model) = model.split_once('/')?;
    let provider = provider.trim();
    let request_model = request_model.trim();
    if provider.is_empty() || request_model.is_empty() {
        return None;
    }
    if !is_known_provider(provider) {
        return None;
    }
    Some((provider, request_model))
}

fn is_known_provider(provider: &str) -> bool {
    matches!(
        provider,
        "openai" | "anthropic" | "gemini" | "ollama" | "glossia" | "fireworks"
    )
}

pub fn chat(config: &LlmConfig, messages: &[ChatMessage]) -> Result<(String, TokenUsage)> {
    let client = Client::builder()
        .timeout(Duration::from_secs(config.timeout_seconds))
        .build()?;

    let mut last_error = None;
    for attempt in 1..=3 {
        match match config.transport {
            Transport::OpenAi => chat_openai(&client, config, messages),
            Transport::Anthropic => chat_anthropic(&client, config, messages),
        } {
            Ok(result) => return Ok(result),
            Err(error) => {
                let retryable = error
                    .downcast_ref::<HttpError>()
                    .map(|error| error.retryable)
                    .unwrap_or(false);

                if !retryable || attempt == 3 {
                    return Err(error);
                }

                last_error = Some(error);
                thread::sleep(Duration::from_millis(1_000 * (1 << (attempt - 1))));
            }
        }
    }

    Err(last_error.unwrap_or_else(|| anyhow!("llm request failed")))
}

#[derive(Debug)]
struct HttpError {
    message: String,
    retryable: bool,
}

impl std::fmt::Display for HttpError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl std::error::Error for HttpError {}

#[derive(Debug, Deserialize)]
struct OpenAiResponse {
    choices: Vec<OpenAiChoice>,
    #[serde(default)]
    usage: OpenAiUsage,
    #[serde(default)]
    error: Option<OpenAiErrorPayload>,
}

#[derive(Debug, Deserialize)]
struct OpenAiChoice {
    message: OpenAiMessage,
}

#[derive(Debug, Deserialize)]
struct OpenAiMessage {
    content: String,
}

#[derive(Debug, Deserialize, Default)]
struct OpenAiUsage {
    #[serde(default)]
    prompt_tokens: usize,
    #[serde(default)]
    completion_tokens: usize,
    #[serde(default)]
    total_tokens: usize,
}

#[derive(Debug, Deserialize)]
struct OpenAiErrorPayload {
    message: String,
}

fn chat_openai(
    client: &Client,
    config: &LlmConfig,
    messages: &[ChatMessage],
) -> Result<(String, TokenUsage)> {
    let url = format!(
        "{}{}",
        config.base_url.trim_end_matches('/'),
        config.chat_path
    );
    let mut body = json!({
        "model": config.model,
        "messages": messages,
    });

    if let Some(temperature) = config.temperature {
        body["temperature"] = json!(temperature);
    }
    if let Some(max_tokens) = config.max_tokens {
        body["max_tokens"] = json!(max_tokens);
    }

    let response = client
        .post(url)
        .headers(build_headers(config, false)?)
        .json(&body)
        .send()
        .map_err(map_transport_error)?;

    let status = response.status();
    let payload = response.text()?;
    let parsed: OpenAiResponse = serde_json::from_str(&payload)?;

    if status.is_client_error() || status.is_server_error() {
        let message = parsed
            .error
            .map(|error| error.message)
            .unwrap_or_else(|| format!("llm error: status {}", status.as_u16()));
        return Err(http_error(message, retryable_status(status)));
    }

    let text = parsed
        .choices
        .into_iter()
        .next()
        .map(|choice| choice.message.content)
        .filter(|content| !content.trim().is_empty())
        .ok_or_else(|| anyhow!("llm response missing choices"))?;

    Ok((
        text,
        TokenUsage {
            prompt_tokens: parsed.usage.prompt_tokens,
            completion_tokens: parsed.usage.completion_tokens,
            total_tokens: parsed.usage.total_tokens,
        },
    ))
}

#[derive(Debug, Deserialize)]
struct AnthropicResponse {
    #[serde(default)]
    content: Vec<AnthropicBlock>,
    #[serde(default)]
    usage: AnthropicUsage,
    #[serde(default)]
    error: Option<AnthropicErrorPayload>,
}

#[derive(Debug, Deserialize)]
struct AnthropicBlock {
    #[serde(default)]
    r#type: String,
    #[serde(default)]
    text: String,
}

#[derive(Debug, Deserialize, Default)]
struct AnthropicUsage {
    #[serde(default)]
    input_tokens: usize,
    #[serde(default)]
    output_tokens: usize,
}

#[derive(Debug, Deserialize)]
struct AnthropicErrorPayload {
    message: String,
}

fn chat_anthropic(
    client: &Client,
    config: &LlmConfig,
    messages: &[ChatMessage],
) -> Result<(String, TokenUsage)> {
    let url = format!(
        "{}{}",
        config.base_url.trim_end_matches('/'),
        config.chat_path
    );
    let mut system_parts = Vec::new();
    let mut anthropic_messages = Vec::new();

    for message in messages {
        if message.role == "system" {
            if !message.content.trim().is_empty() {
                system_parts.push(message.content.clone());
            }
            continue;
        }

        anthropic_messages.push(json!({
            "role": message.role,
            "content": message.content,
        }));
    }

    if anthropic_messages.is_empty() {
        return Err(anyhow!("llm request requires user messages"));
    }

    let mut body = json!({
        "model": config.model,
        "messages": anthropic_messages,
        "max_tokens": config.max_tokens.unwrap_or(1024),
    });

    if let Some(temperature) = config.temperature {
        body["temperature"] = json!(temperature);
    }
    if !system_parts.is_empty() {
        body["system"] = json!(system_parts.join("\n\n"));
    }

    let response = client
        .post(url)
        .headers(build_headers(config, true)?)
        .json(&body)
        .send()
        .map_err(map_transport_error)?;

    let status = response.status();
    let payload = response.text()?;
    let parsed: AnthropicResponse = serde_json::from_str(&payload)?;

    if status.is_client_error() || status.is_server_error() {
        let message = parsed
            .error
            .map(|error| error.message)
            .unwrap_or_else(|| format!("llm error: status {}", status.as_u16()));
        return Err(http_error(message, retryable_status(status)));
    }

    let text = parsed
        .content
        .into_iter()
        .filter(|block| block.r#type == "text" && !block.text.trim().is_empty())
        .map(|block| block.text)
        .collect::<Vec<_>>()
        .join("\n");

    if text.trim().is_empty() {
        return Err(anyhow!("llm response missing content"));
    }

    Ok((
        text,
        TokenUsage {
            prompt_tokens: parsed.usage.input_tokens,
            completion_tokens: parsed.usage.output_tokens,
            total_tokens: parsed.usage.input_tokens + parsed.usage.output_tokens,
        },
    ))
}

fn build_headers(config: &LlmConfig, anthropic: bool) -> Result<HeaderMap> {
    let mut headers = HeaderMap::new();
    headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    headers.insert(USER_AGENT, HeaderValue::from_static("glossia"));

    if let Some(api_key) = config.resolved_api_key()? {
        if anthropic {
            headers.insert(
                HeaderName::from_static("x-api-key"),
                HeaderValue::from_str(&api_key)?,
            );
            headers.insert(
                HeaderName::from_static("anthropic-version"),
                HeaderValue::from_static("2023-06-01"),
            );
        } else {
            headers.insert(
                AUTHORIZATION,
                HeaderValue::from_str(&format!("Bearer {api_key}"))?,
            );
        }
    }

    Ok(headers)
}

fn infer_provider_from_model(model: &str) -> String {
    let normalized = model.trim().to_ascii_lowercase();
    if normalized.starts_with("claude") {
        return "anthropic".into();
    }
    if normalized.starts_with("gemini") {
        return "gemini".into();
    }
    if normalized.starts_with("ollama:") {
        return "ollama".into();
    }
    "openai".into()
}

fn retryable_status(status: StatusCode) -> bool {
    matches!(
        status,
        StatusCode::TOO_MANY_REQUESTS
            | StatusCode::INTERNAL_SERVER_ERROR
            | StatusCode::BAD_GATEWAY
            | StatusCode::SERVICE_UNAVAILABLE
            | StatusCode::GATEWAY_TIMEOUT
    )
}

fn map_transport_error(error: reqwest::Error) -> anyhow::Error {
    if error.is_timeout() || error.is_connect() {
        return http_error(error.to_string(), true);
    }
    anyhow!(error)
}

fn http_error(message: String, retryable: bool) -> anyhow::Error {
    HttpError { message, retryable }.into()
}

#[cfg(test)]
mod tests {
    use super::{resolve_model_identifier, LlmConfig};
    use crate::config::Frontmatter;
    use crate::runtime_config::RuntimeLlmConfig;

    #[test]
    fn parses_qualified_model_identifier() {
        let resolved = resolve_model_identifier("openai/gpt-5", None).unwrap();
        assert_eq!(resolved.provider, "openai");
        assert_eq!(resolved.request_model, "gpt-5");
    }

    #[test]
    fn qualified_model_takes_precedence_over_provider_extension() {
        let error =
            resolve_model_identifier("anthropic/claude-sonnet-4", Some("openai")).unwrap_err();
        assert_eq!(
            error.to_string(),
            "frontmatter model anthropic/claude-sonnet-4 conflicts with configured provider openai"
        );
    }

    #[test]
    fn explicit_provider_uses_model_verbatim() {
        let resolved =
            resolve_model_identifier("accounts/fireworks/models/deepseek-v3p1", Some("fireworks"))
                .unwrap();
        assert_eq!(resolved.provider, "fireworks");
        assert_eq!(
            resolved.request_model,
            "accounts/fireworks/models/deepseek-v3p1"
        );
    }

    #[test]
    fn builds_llm_config_from_runtime_provider_and_plain_model() {
        let config = LlmConfig::from_frontmatter(
            &Frontmatter {
                model: Some("gpt-5".into()),
                ..Frontmatter::default()
            },
            &RuntimeLlmConfig {
                provider: Some("openai".into()),
                ..RuntimeLlmConfig::default()
            },
        )
        .unwrap();

        assert_eq!(config.provider, "openai");
        assert_eq!(config.model, "gpt-5");
        assert_eq!(config.base_url, "https://api.openai.com/v1");
    }

    #[test]
    fn builds_llm_config_from_qualified_model_without_runtime_provider() {
        let config = LlmConfig::from_frontmatter(
            &Frontmatter {
                model: Some("openai/gpt-5".into()),
                ..Frontmatter::default()
            },
            &RuntimeLlmConfig::default(),
        )
        .unwrap();

        assert_eq!(config.provider, "openai");
        assert_eq!(config.model, "gpt-5");
        assert_eq!(config.base_url, "https://api.openai.com/v1");
    }

    #[test]
    fn honors_legacy_unqualified_model_with_explicit_provider() {
        let config = LlmConfig::from_frontmatter(
            &Frontmatter {
                provider: Some("ollama".into()),
                model: Some("llama3.1".into()),
                ..Frontmatter::default()
            },
            &RuntimeLlmConfig::default(),
        )
        .unwrap();

        assert_eq!(config.provider, "ollama");
        assert_eq!(config.model, "llama3.1");
        assert_eq!(config.base_url, "http://localhost:11434/v1");
    }

    #[test]
    fn runtime_config_overrides_frontmatter_connection_settings() {
        let config = LlmConfig::from_frontmatter(
            &Frontmatter {
                provider: Some("openai".into()),
                model: Some("gpt-5".into()),
                base_url: Some("https://wrong.example/v1".into()),
                api_key_env: Some("WRONG_KEY".into()),
                ..Frontmatter::default()
            },
            &RuntimeLlmConfig {
                provider: Some("fireworks".into()),
                base_url: Some("https://api.fireworks.ai/inference/v1".into()),
                api_key_env: Some("FIREWORKS_API_KEY".into()),
                ..RuntimeLlmConfig::default()
            },
        )
        .unwrap();

        assert_eq!(config.provider, "fireworks");
        assert_eq!(config.model, "gpt-5");
        assert_eq!(config.base_url, "https://api.fireworks.ai/inference/v1");
        assert_eq!(config.api_key_env.as_deref(), Some("FIREWORKS_API_KEY"));
    }
}
