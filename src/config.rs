use anyhow::{Result, bail};
use serde::Deserialize;
use std::collections::HashMap;
use std::path::Path;
use tokio::fs;

// Types

#[derive(Debug, Clone)]
pub struct AgentConfig {
    pub role: String,
    pub provider: String,
    pub base_url: String,
    pub chat_completions_path: String,
    pub api_key: String,
    pub api_key_env: String,
    pub model: String,
    pub temperature: Option<f64>,
    pub max_tokens: Option<u32>,
    pub headers: HashMap<String, String>,
    pub timeout_seconds: u64,
}

#[derive(Debug, Clone, Default, Deserialize)]
pub struct TranslateEntry {
    #[serde(default)]
    pub source: String,
    #[serde(default)]
    pub path: String,
    #[serde(default)]
    pub targets: Vec<String>,
    #[serde(default)]
    pub output: String,
    #[serde(default)]
    pub exclude: Vec<String>,
    #[serde(default)]
    pub preserve: Vec<String>,
    #[serde(default)]
    pub frontmatter: String,
    #[serde(default)]
    pub check_cmd: String,
    #[serde(default)]
    pub check_cmds: HashMap<String, String>,
    #[serde(default)]
    pub retries: Option<i32>,
}

#[derive(Debug, Clone, Default, Deserialize)]
pub struct PartialAgentConfig {
    #[serde(default)]
    pub role: Option<String>,
    #[serde(default)]
    pub provider: Option<String>,
    #[serde(default)]
    pub base_url: Option<String>,
    #[serde(default)]
    pub chat_completions_path: Option<String>,
    #[serde(default)]
    pub api_key: Option<String>,
    #[serde(default)]
    pub api_key_env: Option<String>,
    #[serde(default)]
    pub model: Option<String>,
    #[serde(default)]
    pub temperature: Option<f64>,
    #[serde(default)]
    pub max_tokens: Option<u32>,
    #[serde(default)]
    pub headers: Option<HashMap<String, String>>,
    #[serde(default)]
    pub timeout_seconds: Option<u64>,
}

#[derive(Debug, Clone, Default, Deserialize)]
pub struct LLMConfig {
    #[serde(default)]
    pub provider: Option<String>,
    #[serde(default)]
    pub base_url: Option<String>,
    #[serde(default)]
    pub chat_completions_path: Option<String>,
    #[serde(default)]
    pub api_key: Option<String>,
    #[serde(default)]
    pub api_key_env: Option<String>,
    #[serde(default)]
    pub coordinator_model: Option<String>,
    #[serde(default)]
    pub translator_model: Option<String>,
    #[serde(default)]
    pub temperature: Option<f64>,
    #[serde(default)]
    pub max_tokens: Option<u32>,
    #[serde(default)]
    pub headers: Option<HashMap<String, String>>,
    #[serde(default)]
    pub timeout_seconds: Option<u64>,
    #[serde(default)]
    pub agent: Vec<PartialAgentConfig>,
}

#[derive(Debug, Clone, Default, Deserialize)]
pub struct RawConfig {
    #[serde(default)]
    pub llm: Option<LLMConfig>,
    #[serde(default)]
    pub translate: Vec<TranslateEntry>,
}

#[derive(Debug, Clone)]
pub struct L10NConfig {
    pub llm: LLMConfig,
    pub translate: Vec<TranslateEntry>,
}

#[derive(Debug, Clone)]
pub struct L10NFile {
    pub path: String,
    pub dir: String,
    pub depth: usize,
    pub body: String,
    pub config: L10NConfig,
}

#[derive(Debug, Clone)]
pub struct Entry {
    pub source: String,
    pub path: String,
    pub targets: Vec<String>,
    pub output: String,
    pub exclude: Vec<String>,
    pub preserve: Vec<String>,
    pub frontmatter: String,
    pub check_cmd: String,
    pub check_cmds: HashMap<String, String>,
    pub retries: Option<i32>,
    pub origin_path: String,
    pub origin_dir: String,
    pub origin_depth: usize,
    pub index: usize,
}

pub const FRONTMATTER_PRESERVE: &str = "preserve";
pub const FRONTMATTER_TRANSLATE: &str = "translate";

// Parsing

#[derive(Debug)]
pub struct SplitResult {
    pub frontmatter: String,
    pub body: String,
    pub has_frontmatter: bool,
}

pub fn split_toml_frontmatter(contents: &str) -> Result<SplitResult> {
    let lines: Vec<&str> = contents.split('\n').collect();
    if lines.is_empty() || lines[0].trim() != "+++" {
        return Ok(SplitResult {
            frontmatter: String::new(),
            body: contents.to_string(),
            has_frontmatter: false,
        });
    }
    let mut end = None;
    for (i, line) in lines.iter().enumerate().skip(1) {
        if line.trim() == "+++" {
            end = Some(i);
            break;
        }
    }
    let end = match end {
        Some(e) => e,
        None => bail!("frontmatter start found but no closing +++"),
    };

    let frontmatter = lines[1..end].join("\n");
    let body = lines[end + 1..].join("\n");
    Ok(SplitResult {
        frontmatter,
        body,
        has_frontmatter: true,
    })
}

pub async fn parse_file(path: &str) -> Result<L10NFile> {
    let contents = fs::read_to_string(path).await?;
    let split = split_toml_frontmatter(&contents)?;

    let mut config = L10NConfig {
        llm: LLMConfig::default(),
        translate: Vec::new(),
    };

    if split.has_frontmatter {
        let raw: RawConfig = toml::from_str(&split.frontmatter)?;
        config.llm = raw.llm.unwrap_or_default();
        config.translate = raw.translate;
    }

    // Normalize translate entries
    for entry in &mut config.translate {
        if entry.source.is_empty() {
            entry.source = entry.path.clone();
        }
        if entry.frontmatter.is_empty() {
            entry.frontmatter = "preserve".to_string();
        }
    }

    let abs_path = Path::new(path).canonicalize()?;
    let dir = abs_path
        .parent()
        .unwrap_or(Path::new("."))
        .to_string_lossy()
        .to_string();

    Ok(L10NFile {
        path: abs_path.to_string_lossy().to_string(),
        dir,
        depth: 0,
        body: split.body,
        config,
    })
}

pub fn source_path(entry: &TranslateEntry) -> String {
    let s = entry.source.trim();
    if !s.is_empty() {
        return s.to_string();
    }
    entry.path.trim().to_string()
}

// Validation

pub fn validate_translate_entry(entry: &TranslateEntry) -> Result<()> {
    let sp = source_path(entry);
    if sp.is_empty() {
        bail!("translate entry requires source/path");
    }
    if entry.targets.is_empty() {
        bail!("translate entry \"{}\" has no targets", sp);
    }
    if entry.output.trim().is_empty() {
        bail!("translate entry \"{}\" has no output", sp);
    }
    if !entry.frontmatter.is_empty()
        && entry.frontmatter != FRONTMATTER_PRESERVE
        && entry.frontmatter != FRONTMATTER_TRANSLATE
    {
        bail!(
            "translate entry \"{}\" has invalid frontmatter mode \"{}\"",
            sp,
            entry.frontmatter
        );
    }
    Ok(())
}

// Merge

pub fn merge_llm(base: &LLMConfig, over: &LLMConfig) -> LLMConfig {
    let mut out = base.clone();

    if !over.provider.as_deref().unwrap_or("").trim().is_empty() {
        out.provider = over.provider.clone();
    }
    if !over.base_url.as_deref().unwrap_or("").trim().is_empty() {
        out.base_url = over.base_url.clone();
    }
    if !over
        .chat_completions_path
        .as_deref()
        .unwrap_or("")
        .trim()
        .is_empty()
    {
        out.chat_completions_path = over.chat_completions_path.clone();
    }
    if !over.api_key.as_deref().unwrap_or("").trim().is_empty() {
        out.api_key = over.api_key.clone();
    }
    if !over.api_key_env.as_deref().unwrap_or("").trim().is_empty() {
        out.api_key_env = over.api_key_env.clone();
    }
    if !over
        .coordinator_model
        .as_deref()
        .unwrap_or("")
        .trim()
        .is_empty()
    {
        out.coordinator_model = over.coordinator_model.clone();
    }
    if !over
        .translator_model
        .as_deref()
        .unwrap_or("")
        .trim()
        .is_empty()
    {
        out.translator_model = over.translator_model.clone();
    }
    if over.temperature.is_some() {
        out.temperature = over.temperature;
    }
    if over.max_tokens.is_some() {
        out.max_tokens = over.max_tokens;
    }
    if over.timeout_seconds.is_some() && over.timeout_seconds.unwrap_or(0) > 0 {
        out.timeout_seconds = over.timeout_seconds;
    }

    if let Some(ref oh) = over.headers
        && !oh.is_empty()
    {
        let mut merged = out.headers.clone().unwrap_or_default();
        merged.extend(oh.clone());
        out.headers = Some(merged);
    }

    out.agent = merge_agents_list(&out.agent, &over.agent);
    out
}

fn merge_agents_list(
    base: &[PartialAgentConfig],
    over: &[PartialAgentConfig],
) -> Vec<PartialAgentConfig> {
    if over.is_empty() {
        return base.to_vec();
    }
    let mut out: Vec<PartialAgentConfig> = base.to_vec();
    for agent in over {
        let role = agent.role.as_deref().unwrap_or("").to_lowercase();
        let role = role.trim();
        let mut replaced = false;
        if !role.is_empty() {
            for existing in &mut out {
                let existing_role = existing.role.as_deref().unwrap_or("").to_lowercase();
                if existing_role.trim() == role {
                    *existing = agent.clone();
                    replaced = true;
                    break;
                }
            }
        }
        if !replaced {
            out.push(agent.clone());
        }
    }
    out
}

fn empty_agent() -> AgentConfig {
    AgentConfig {
        role: String::new(),
        provider: String::new(),
        base_url: String::new(),
        chat_completions_path: String::new(),
        api_key: String::new(),
        api_key_env: String::new(),
        model: String::new(),
        temperature: None,
        max_tokens: None,
        headers: HashMap::new(),
        timeout_seconds: 0,
    }
}

fn merge_agent_config(base: &AgentConfig, over: &PartialAgentConfig) -> AgentConfig {
    let mut out = base.clone();
    if let Some(ref v) = over.provider
        && !v.trim().is_empty()
    {
        out.provider = v.clone();
    }
    if let Some(ref v) = over.base_url
        && !v.trim().is_empty()
    {
        out.base_url = v.clone();
    }
    if let Some(ref v) = over.chat_completions_path
        && !v.trim().is_empty()
    {
        out.chat_completions_path = v.clone();
    }
    if let Some(ref v) = over.api_key
        && !v.trim().is_empty()
    {
        out.api_key = v.clone();
    }
    if let Some(ref v) = over.api_key_env
        && !v.trim().is_empty()
    {
        out.api_key_env = v.clone();
    }
    if let Some(ref v) = over.model
        && !v.trim().is_empty()
    {
        out.model = v.clone();
    }
    if over.temperature.is_some() {
        out.temperature = over.temperature;
    }
    if over.max_tokens.is_some() {
        out.max_tokens = over.max_tokens;
    }
    if let Some(ts) = over.timeout_seconds
        && ts > 0
    {
        out.timeout_seconds = ts;
    }
    if let Some(ref h) = over.headers
        && !h.is_empty()
    {
        out.headers.extend(h.clone());
    }
    out
}

fn infer_provider_from_model(model: &str) -> Option<&'static str> {
    let m = model.trim().to_lowercase();
    if m.starts_with("gemini") {
        Some("gemini")
    } else if m.starts_with("claude") {
        Some("anthropic")
    } else if m.starts_with("gpt") || m.starts_with("o1") || m.starts_with("o3") || m.starts_with("o4") {
        Some("openai")
    } else {
        None
    }
}

pub fn apply_agent_defaults(cfg: &mut AgentConfig) {
    let provider = if cfg.provider.trim().is_empty() {
        infer_provider_from_model(&cfg.model)
            .unwrap_or("openai")
            .to_string()
    } else {
        cfg.provider.trim().to_string()
    };
    cfg.provider = provider.clone();

    match provider.as_str() {
        "openai" => {
            if cfg.chat_completions_path.trim().is_empty() {
                cfg.chat_completions_path = "/chat/completions".to_string();
            }
            if cfg.base_url.trim().is_empty() {
                cfg.base_url = "https://api.openai.com/v1".to_string();
            }
            if cfg.api_key_env.trim().is_empty() {
                cfg.api_key_env = "OPENAI_API_KEY".to_string();
            }
        }
        "gemini" => {
            if cfg.chat_completions_path.trim().is_empty() {
                cfg.chat_completions_path = "/chat/completions".to_string();
            }
            if cfg.base_url.trim().is_empty() {
                cfg.base_url = "https://generativelanguage.googleapis.com/v1beta/openai".to_string();
            }
            if cfg.api_key_env.trim().is_empty() {
                cfg.api_key_env = "GEMINI_API_KEY".to_string();
            }
            // Gemini uses the OpenAI-compatible protocol
            cfg.provider = "openai".to_string();
        }
        "vertex" => {
            if cfg.chat_completions_path.trim().is_empty() {
                cfg.chat_completions_path = "/chat/completions".to_string();
            }
        }
        "anthropic" => {
            if cfg.chat_completions_path.trim().is_empty() {
                cfg.chat_completions_path = "/v1/messages".to_string();
            }
            if cfg.base_url.trim().is_empty() {
                cfg.base_url = "https://api.anthropic.com".to_string();
            }
            if cfg.api_key_env.trim().is_empty() {
                cfg.api_key_env = "ANTHROPIC_API_KEY".to_string();
            }
        }
        _ => {}
    }
}

pub fn resolve_agents(cfg: &LLMConfig) -> Result<(AgentConfig, AgentConfig)> {
    let mut by_role: HashMap<String, &PartialAgentConfig> = HashMap::new();
    for agent in &cfg.agent {
        let role = agent.role.as_deref().unwrap_or("").to_lowercase();
        let role = role.trim().to_string();
        if role.is_empty() {
            bail!("llm.agent requires role");
        }
        if role != "coordinator" && role != "translator" {
            bail!("unknown llm.agent role \"{}\"", role);
        }
        by_role.insert(role, agent);
    }

    let mut base = empty_agent();
    base.provider = cfg.provider.as_deref().unwrap_or("").to_string();
    base.base_url = cfg.base_url.as_deref().unwrap_or("").to_string();
    base.chat_completions_path = cfg
        .chat_completions_path
        .as_deref()
        .unwrap_or("")
        .to_string();
    base.api_key = cfg.api_key.as_deref().unwrap_or("").to_string();
    base.api_key_env = cfg.api_key_env.as_deref().unwrap_or("").to_string();
    base.temperature = cfg.temperature;
    base.max_tokens = cfg.max_tokens;
    base.headers = cfg.headers.clone().unwrap_or_default();
    base.timeout_seconds = cfg.timeout_seconds.unwrap_or(0);

    let empty_partial = PartialAgentConfig::default();

    let mut coordinator =
        merge_agent_config(&base, by_role.get("coordinator").unwrap_or(&&empty_partial));
    if coordinator.model.trim().is_empty() {
        coordinator.model = cfg.coordinator_model.as_deref().unwrap_or("").to_string();
    }
    apply_agent_defaults(&mut coordinator);

    let mut translator =
        merge_agent_config(&base, by_role.get("translator").unwrap_or(&&empty_partial));
    if translator.model.trim().is_empty() {
        translator.model = cfg.translator_model.as_deref().unwrap_or("").to_string();
    }

    // Fall through from coordinator
    if translator.provider.trim().is_empty() {
        translator.provider = coordinator.provider.clone();
    }
    if translator.base_url.trim().is_empty() {
        translator.base_url = coordinator.base_url.clone();
    }
    if translator.chat_completions_path.trim().is_empty() {
        translator.chat_completions_path = coordinator.chat_completions_path.clone();
    }
    if translator.api_key.trim().is_empty() {
        translator.api_key = coordinator.api_key.clone();
    }
    if translator.api_key_env.trim().is_empty() {
        translator.api_key_env = coordinator.api_key_env.clone();
    }
    if translator.temperature.is_none() {
        translator.temperature = coordinator.temperature;
    }
    if translator.max_tokens.is_none() {
        translator.max_tokens = coordinator.max_tokens;
    }
    if translator.timeout_seconds == 0 {
        translator.timeout_seconds = coordinator.timeout_seconds;
    }
    if translator.headers.is_empty() {
        translator.headers = coordinator.headers.clone();
    } else {
        let mut merged = coordinator.headers.clone();
        merged.extend(translator.headers.clone());
        translator.headers = merged;
    }

    apply_agent_defaults(&mut translator);

    Ok((coordinator, translator))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn split_returns_body_only_when_no_frontmatter() {
        let result = split_toml_frontmatter("hello world").unwrap();
        assert!(!result.has_frontmatter);
        assert_eq!(result.body, "hello world");
    }

    #[test]
    fn split_parses_frontmatter_and_body() {
        let input = "+++\nkey = \"value\"\n+++\nbody content";
        let result = split_toml_frontmatter(input).unwrap();
        assert!(result.has_frontmatter);
        assert_eq!(result.frontmatter, "key = \"value\"");
        assert_eq!(result.body, "body content");
    }

    #[test]
    fn split_throws_when_closing_missing() {
        let result = split_toml_frontmatter("+++\nno closing");
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("no closing +++"));
    }

    #[test]
    fn source_path_returns_source_when_set() {
        let entry = TranslateEntry {
            source: "docs/*.md".to_string(),
            path: String::new(),
            ..Default::default()
        };
        assert_eq!(source_path(&entry), "docs/*.md");
    }

    #[test]
    fn source_path_falls_back_to_path() {
        let entry = TranslateEntry {
            source: String::new(),
            path: "files/*.json".to_string(),
            ..Default::default()
        };
        assert_eq!(source_path(&entry), "files/*.json");
    }

    #[test]
    fn validate_throws_when_source_missing() {
        let entry = TranslateEntry::default();
        assert!(validate_translate_entry(&entry).is_err());
    }

    #[test]
    fn validate_throws_when_targets_empty() {
        let entry = TranslateEntry {
            source: "docs/*.md".to_string(),
            output: "out/{lang}/{relpath}".to_string(),
            ..Default::default()
        };
        assert!(validate_translate_entry(&entry).is_err());
    }

    #[test]
    fn validate_throws_when_output_missing() {
        let entry = TranslateEntry {
            source: "docs/*.md".to_string(),
            targets: vec!["es".to_string()],
            ..Default::default()
        };
        assert!(validate_translate_entry(&entry).is_err());
    }

    #[test]
    fn validate_accepts_valid_entry() {
        let entry = TranslateEntry {
            source: "docs/*.md".to_string(),
            targets: vec!["es".to_string(), "de".to_string()],
            output: "i18n/{lang}/{relpath}".to_string(),
            frontmatter: "preserve".to_string(),
            ..Default::default()
        };
        assert!(validate_translate_entry(&entry).is_ok());
    }

    #[test]
    fn validate_throws_on_invalid_frontmatter_mode() {
        let entry = TranslateEntry {
            source: "docs/*.md".to_string(),
            targets: vec!["es".to_string()],
            output: "out/{lang}/{relpath}".to_string(),
            frontmatter: "invalid".to_string(),
            ..Default::default()
        };
        assert!(validate_translate_entry(&entry).is_err());
    }

    #[test]
    fn merge_llm_override_replaces_base() {
        let base = LLMConfig {
            provider: Some("openai".to_string()),
            base_url: Some("http://old".to_string()),
            ..Default::default()
        };
        let over = LLMConfig {
            provider: Some("anthropic".to_string()),
            ..Default::default()
        };
        let result = merge_llm(&base, &over);
        assert_eq!(result.provider.as_deref(), Some("anthropic"));
        assert_eq!(result.base_url.as_deref(), Some("http://old"));
    }

    #[test]
    fn merge_llm_merges_headers() {
        let base = LLMConfig {
            headers: Some(HashMap::from([("a".to_string(), "1".to_string())])),
            ..Default::default()
        };
        let over = LLMConfig {
            headers: Some(HashMap::from([("b".to_string(), "2".to_string())])),
            ..Default::default()
        };
        let result = merge_llm(&base, &over);
        let headers = result.headers.unwrap();
        assert_eq!(headers.get("a").unwrap(), "1");
        assert_eq!(headers.get("b").unwrap(), "2");
    }

    #[test]
    fn apply_defaults_openai() {
        let mut cfg = empty_agent();
        cfg.model = "gpt-4o".to_string();
        apply_agent_defaults(&mut cfg);
        assert_eq!(cfg.provider, "openai");
        assert_eq!(cfg.base_url, "https://api.openai.com/v1");
        assert_eq!(cfg.chat_completions_path, "/chat/completions");
        assert_eq!(cfg.api_key_env, "OPENAI_API_KEY");
    }

    #[test]
    fn apply_defaults_anthropic() {
        let mut cfg = empty_agent();
        cfg.provider = "anthropic".to_string();
        cfg.model = "claude-opus-4-5-20251101".to_string();
        apply_agent_defaults(&mut cfg);
        assert_eq!(cfg.base_url, "https://api.anthropic.com");
        assert_eq!(cfg.chat_completions_path, "/v1/messages");
        assert_eq!(cfg.api_key_env, "ANTHROPIC_API_KEY");
    }

    #[test]
    fn resolve_agents_from_config() {
        let cfg = LLMConfig {
            provider: Some("openai".to_string()),
            api_key: Some("sk-test".to_string()),
            agent: vec![
                PartialAgentConfig {
                    role: Some("coordinator".to_string()),
                    model: Some("gpt-4o-mini".to_string()),
                    ..Default::default()
                },
                PartialAgentConfig {
                    role: Some("translator".to_string()),
                    model: Some("gpt-4o".to_string()),
                    ..Default::default()
                },
            ],
            ..Default::default()
        };
        let (coordinator, translator) = resolve_agents(&cfg).unwrap();
        assert_eq!(coordinator.model, "gpt-4o-mini");
        assert_eq!(translator.model, "gpt-4o");
        assert_eq!(coordinator.provider, "openai");
        assert_eq!(translator.provider, "openai");
    }

    #[test]
    fn translator_falls_through_from_coordinator() {
        let cfg = LLMConfig {
            provider: Some("anthropic".to_string()),
            base_url: Some("https://api.anthropic.com".to_string()),
            agent: vec![
                PartialAgentConfig {
                    role: Some("coordinator".to_string()),
                    model: Some("claude-3-haiku-20240307".to_string()),
                    ..Default::default()
                },
                PartialAgentConfig {
                    role: Some("translator".to_string()),
                    model: Some("claude-opus-4-5-20251101".to_string()),
                    ..Default::default()
                },
            ],
            ..Default::default()
        };
        let (_coordinator, translator) = resolve_agents(&cfg).unwrap();
        assert_eq!(translator.base_url, "https://api.anthropic.com");
        assert_eq!(translator.provider, "anthropic");
    }
}
