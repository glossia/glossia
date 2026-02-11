use std::path::Path;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Format {
    Markdown,
    Json,
    Yaml,
    Po,
    Text,
}

impl Format {
    pub fn as_str(&self) -> &'static str {
        match self {
            Format::Markdown => "markdown",
            Format::Json => "json",
            Format::Yaml => "yaml",
            Format::Po => "po",
            Format::Text => "text",
        }
    }

    pub fn label(&self) -> &'static str {
        match self {
            Format::Json => "JSON",
            Format::Yaml => "YAML",
            Format::Po => "PO",
            Format::Markdown => "Markdown frontmatter",
            Format::Text => "text",
        }
    }
}

impl std::fmt::Display for Format {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

pub fn detect_format(path: &str) -> Format {
    let ext = Path::new(path)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();

    match ext.as_str() {
        "md" | "markdown" => Format::Markdown,
        "json" => Format::Json,
        "yaml" | "yml" => Format::Yaml,
        "po" | "pot" => Format::Po,
        _ => Format::Text,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_markdown() {
        assert_eq!(detect_format("docs/guide.md"), Format::Markdown);
        assert_eq!(detect_format("readme.markdown"), Format::Markdown);
    }

    #[test]
    fn detects_json() {
        assert_eq!(detect_format("data.json"), Format::Json);
    }

    #[test]
    fn detects_yaml() {
        assert_eq!(detect_format("config.yaml"), Format::Yaml);
        assert_eq!(detect_format("config.yml"), Format::Yaml);
    }

    #[test]
    fn detects_po() {
        assert_eq!(detect_format("messages.po"), Format::Po);
        assert_eq!(detect_format("messages.pot"), Format::Po);
    }

    #[test]
    fn defaults_to_text() {
        assert_eq!(detect_format("readme.txt"), Format::Text);
        assert_eq!(detect_format("file.unknown"), Format::Text);
    }
}
