use anyhow::{anyhow, Result};

use crate::config::Frontmatter;
use crate::runtime_config::RuntimeLlmConfig;

/// The provider/model a document resolves to.
///
/// The CLI no longer calls LLM providers itself — translation runs server-side.
/// This retains just enough model resolution for `status` to report per-scope
/// model selection and to compute cache keys.
#[derive(Debug, Clone)]
pub struct LlmConfig {
    pub provider: String,
    pub model: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct ResolvedModelIdentifier {
    provider: String,
    request_model: String,
}

impl LlmConfig {
    pub fn from_frontmatter(frontmatter: &Frontmatter, runtime: &RuntimeLlmConfig) -> Result<Self> {
        // Per-document frontmatter model wins; the runtime model only fills in
        // when the document omits one.
        let declared_model = frontmatter
            .model
            .clone()
            .or_else(|| runtime.model.clone())
            .filter(|value| !value.trim().is_empty())
            .ok_or_else(|| anyhow!("frontmatter model is required"))?;
        let resolved = resolve_model_identifier(
            &declared_model,
            runtime
                .provider
                .as_deref()
                .or(frontmatter.provider.as_deref()),
        )?;

        Ok(Self {
            provider: resolved.provider,
            model: resolved.request_model,
        })
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
    fn qualified_model_conflicts_with_configured_provider() {
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
        assert_eq!(resolved.request_model, "accounts/fireworks/models/deepseek-v3p1");
    }

    #[test]
    fn infers_provider_from_model_name() {
        assert_eq!(
            resolve_model_identifier("claude-sonnet-4", None)
                .unwrap()
                .provider,
            "anthropic"
        );
    }

    #[test]
    fn frontmatter_model_takes_precedence_over_runtime_model() {
        let config = LlmConfig::from_frontmatter(
            &Frontmatter {
                model: Some("openai/gpt-5".into()),
                ..Frontmatter::default()
            },
            &RuntimeLlmConfig {
                model: Some("openai/gpt-4o".into()),
                ..RuntimeLlmConfig::default()
            },
        )
        .unwrap();

        assert_eq!(config.provider, "openai");
        assert_eq!(config.model, "gpt-5");
    }

    #[test]
    fn runtime_model_fills_in_when_frontmatter_omits_it() {
        let config = LlmConfig::from_frontmatter(
            &Frontmatter::default(),
            &RuntimeLlmConfig {
                model: Some("gpt-5-mini".into()),
                provider: Some("openai".into()),
                ..RuntimeLlmConfig::default()
            },
        )
        .unwrap();

        assert_eq!(config.provider, "openai");
        assert_eq!(config.model, "gpt-5-mini");
    }
}
