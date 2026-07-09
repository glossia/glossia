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
    pub model: Option<String>,
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

    let config = if path.exists() {
        let raw = fs::read_to_string(path)?;
        toml::from_str(&raw)?
    } else {
        RuntimeConfig::default()
    };

    with_env_overrides(config)
}

pub fn path(root: &Path) -> PathBuf {
    root.join("glossia.toml")
}

fn with_env_overrides(mut config: RuntimeConfig) -> Result<RuntimeConfig> {
    override_string(&mut config.llm.model, "GLOSSIA_LLM_MODEL");
    override_string(&mut config.llm.provider, "GLOSSIA_LLM_PROVIDER");
    override_string(&mut config.llm.base_url, "GLOSSIA_LLM_BASE_URL");
    override_string(
        &mut config.llm.chat_completions_path,
        "GLOSSIA_LLM_CHAT_COMPLETIONS_PATH",
    );
    override_string(&mut config.llm.api_key, "GLOSSIA_LLM_API_KEY");
    override_string(&mut config.llm.api_key_env, "GLOSSIA_LLM_API_KEY_ENV");
    override_f64(&mut config.llm.temperature, "GLOSSIA_LLM_TEMPERATURE")?;
    override_u32(&mut config.llm.max_tokens, "GLOSSIA_LLM_MAX_TOKENS")?;
    override_u64(
        &mut config.llm.timeout_seconds,
        "GLOSSIA_LLM_TIMEOUT_SECONDS",
    )?;

    Ok(config)
}

fn override_string(target: &mut Option<String>, env_name: &str) {
    if let Some(value) = env_value(env_name) {
        *target = Some(value);
    }
}

fn override_f64(target: &mut Option<f64>, env_name: &str) -> Result<()> {
    if let Some(value) = env_value(env_name) {
        *target = Some(value.parse()?);
    }

    Ok(())
}

fn override_u32(target: &mut Option<u32>, env_name: &str) -> Result<()> {
    if let Some(value) = env_value(env_name) {
        *target = Some(value.parse()?);
    }

    Ok(())
}

fn override_u64(target: &mut Option<u64>, env_name: &str) -> Result<()> {
    if let Some(value) = env_value(env_name) {
        *target = Some(value.parse()?);
    }

    Ok(())
}

fn env_value(env_name: &str) -> Option<String> {
    std::env::var(env_name)
        .ok()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
}

#[cfg(test)]
mod tests {
    use super::{load_runtime_config, path, RuntimeConfig, RuntimeLlmConfig};
    use std::fs;
    use std::sync::{Mutex, MutexGuard};

    static ENV_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn missing_runtime_config_is_empty() {
        let _guard = EnvGuard::set(&[]);
        let root = tempfile::tempdir().unwrap();

        assert_eq!(
            load_runtime_config(root.path()).unwrap(),
            RuntimeConfig::default()
        );
    }

    #[test]
    fn parses_llm_runtime_config() {
        let _guard = EnvGuard::set(&[]);
        let root = tempfile::tempdir().unwrap();

        fs::write(
            path(root.path()),
            r#"[llm]
model = "gpt-5"
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
                    model: Some("gpt-5".into()),
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

    #[test]
    fn environment_overrides_runtime_config() {
        let _guard = EnvGuard::set(&[
            ("GLOSSIA_LLM_MODEL", "gpt-5-mini"),
            ("GLOSSIA_LLM_PROVIDER", "openai"),
            ("GLOSSIA_LLM_BASE_URL", "https://example.test/v1"),
            ("GLOSSIA_LLM_API_KEY", "test-key"),
            ("GLOSSIA_LLM_TIMEOUT_SECONDS", "7"),
        ]);
        let root = tempfile::tempdir().unwrap();

        assert_eq!(
            load_runtime_config(root.path()).unwrap(),
            RuntimeConfig {
                llm: RuntimeLlmConfig {
                    model: Some("gpt-5-mini".into()),
                    provider: Some("openai".into()),
                    base_url: Some("https://example.test/v1".into()),
                    api_key: Some("test-key".into()),
                    timeout_seconds: Some(7),
                    ..RuntimeLlmConfig::default()
                },
            }
        );
    }

    struct EnvGuard {
        previous: Vec<(&'static str, Option<String>)>,
        _lock: MutexGuard<'static, ()>,
    }

    impl EnvGuard {
        fn set(values: &[(&'static str, &'static str)]) -> Self {
            let lock = ENV_LOCK.lock().unwrap();
            let names = [
                "GLOSSIA_LLM_MODEL",
                "GLOSSIA_LLM_PROVIDER",
                "GLOSSIA_LLM_BASE_URL",
                "GLOSSIA_LLM_CHAT_COMPLETIONS_PATH",
                "GLOSSIA_LLM_API_KEY",
                "GLOSSIA_LLM_API_KEY_ENV",
                "GLOSSIA_LLM_TEMPERATURE",
                "GLOSSIA_LLM_MAX_TOKENS",
                "GLOSSIA_LLM_TIMEOUT_SECONDS",
            ];
            let previous = names
                .into_iter()
                .map(|name| {
                    let previous = std::env::var(name).ok();
                    std::env::remove_var(name);
                    (name, previous)
                })
                .collect::<Vec<_>>();

            for (name, value) in values {
                std::env::set_var(name, value);
            }

            Self {
                previous,
                _lock: lock,
            }
        }
    }

    impl Drop for EnvGuard {
        fn drop(&mut self) {
            for (name, value) in &self.previous {
                match value {
                    Some(value) => std::env::set_var(name, value),
                    None => std::env::remove_var(name),
                }
            }
        }
    }
}
