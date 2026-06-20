use anyhow::Result;
use serde::Deserialize;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(default)]
pub struct RuntimeConfig {
    pub llm: RuntimeLlmConfig,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(default)]
pub struct RuntimeLlmConfig {
    pub provider: Option<String>,
    pub base_url: Option<String>,
    pub chat_completions_path: Option<String>,
    pub api_key: Option<String>,
    pub api_key_env: Option<String>,
    pub temperature: Option<f64>,
    pub max_tokens: Option<u32>,
    pub timeout_seconds: Option<u64>,
}

pub fn load_runtime_config(root: &Path) -> Result<RuntimeConfig> {
    let path = path(root);
    if !path.exists() {
        return Ok(RuntimeConfig::default());
    }

    let raw = fs::read_to_string(path)?;
    Ok(toml::from_str(&raw)?)
}

pub fn path(root: &Path) -> PathBuf {
    root.join("glossia.toml")
}

#[cfg(test)]
mod tests {
    use super::{load_runtime_config, path, RuntimeConfig, RuntimeLlmConfig};
    use std::fs;

    #[test]
    fn missing_runtime_config_is_empty() {
        let root = tempfile::tempdir().unwrap();
        assert_eq!(
            load_runtime_config(root.path()).unwrap(),
            RuntimeConfig::default()
        );
    }

    #[test]
    fn parses_llm_runtime_config() {
        let root = tempfile::tempdir().unwrap();
        fs::write(
            path(root.path()),
            r#"[llm]
provider = "fireworks"
base_url = "https://api.fireworks.ai/inference/v1"
api_key_env = "FIREWORKS_API_KEY"
timeout_seconds = 42
"#,
        )
        .unwrap();

        assert_eq!(
            load_runtime_config(root.path()).unwrap(),
            RuntimeConfig {
                llm: RuntimeLlmConfig {
                    provider: Some("fireworks".into()),
                    base_url: Some("https://api.fireworks.ai/inference/v1".into()),
                    chat_completions_path: None,
                    api_key: None,
                    api_key_env: Some("FIREWORKS_API_KEY".into()),
                    temperature: None,
                    max_tokens: None,
                    timeout_seconds: Some(42),
                },
            }
        );
    }
}
