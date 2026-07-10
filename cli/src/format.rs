use std::path::Path;

#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
#[allow(clippy::upper_case_acronyms, non_camel_case_types)]
pub enum Format {
    Markdown,
    JSON,
    YAML,
    PO,
    Text,
}

impl Format {
    pub fn detect(path: &str) -> Self {
        let ext = Path::new(path)
            .extension()
            .and_then(|ext| ext.to_str())
            .unwrap_or_default()
            .to_ascii_lowercase();

        match ext.as_str() {
            "md" | "markdown" => Self::Markdown,
            "json" => Self::JSON,
            "yaml" | "yml" => Self::YAML,
            "po" | "pot" => Self::PO,
            _ => Self::Text,
        }
    }
}

impl std::fmt::Display for Format {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let text = match self {
            Self::Markdown => "markdown",
            Self::JSON => "json",
            Self::YAML => "yaml",
            Self::PO => "po",
            Self::Text => "text",
        };
        write!(f, "{text}")
    }
}

#[cfg(test)]
mod tests {
    use super::Format;

    #[test]
    fn detect_format() {
        assert_eq!(Format::detect("docs/guide.md"), Format::Markdown);
        assert_eq!(Format::detect("readme.markdown"), Format::Markdown);
        assert_eq!(Format::detect("data.json"), Format::JSON);
        assert_eq!(Format::detect("config.yaml"), Format::YAML);
        assert_eq!(Format::detect("messages.po"), Format::PO);
        assert_eq!(Format::detect("notes.txt"), Format::Text);
        assert_eq!(Format::detect("file.POT"), Format::PO);
        assert_eq!(Format::detect("file.YML"), Format::YAML);
    }
}
