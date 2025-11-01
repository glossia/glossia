use serde::{Deserialize, Serialize};

/// Configuration structure shared across Glossia applications
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GlossiaConfig {
    pub app_name: String,
    pub version: String,
}

impl Default for GlossiaConfig {
    fn default() -> Self {
        Self {
            app_name: "Glossia".to_string(),
            version: env!("CARGO_PKG_VERSION").to_string(),
        }
    }
}

/// Greet function shared between CLI and desktop app
pub fn greet(name: &str) -> String {
    format!("Hello, {}! Welcome to Glossia!", name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greet() {
        let result = greet("World");
        assert_eq!(result, "Hello, World! Welcome to Glossia!");
    }

    #[test]
    fn test_config_default() {
        let config = GlossiaConfig::default();
        assert_eq!(config.app_name, "Glossia");
    }
}
