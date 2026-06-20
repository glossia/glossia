use anyhow::{anyhow, Result};

use crate::config::parse_content;
use crate::format::Format;

use super::validate_po;

pub fn validate_syntax(format: Format, output: &str, source: &str) -> Result<()> {
    match format {
        Format::JSON => {
            serde_json::from_str::<serde_json::Value>(output)?;
            Ok(())
        }
        Format::YAML => {
            serde_yaml::from_str::<serde_yaml::Value>(output)?;
            Ok(())
        }
        Format::PO => validate_po(output, source),
        Format::Markdown => validate_markdown(output),
        Format::Text => Ok(()),
    }
}

fn validate_markdown(content: &str) -> Result<()> {
    let Some(first_line) = content.lines().next() else {
        return Ok(());
    };

    let marker = first_line.trim();
    if marker != "---" && marker != "+++" {
        return Ok(());
    }

    parse_content(content)
        .map(|_| ())
        .map_err(|error| anyhow!("markdown frontmatter invalid: {error}"))
}
