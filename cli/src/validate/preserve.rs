use anyhow::{anyhow, Result};
use regex::Regex;

pub fn resolve_preserve(kinds: &[String]) -> Vec<String> {
    if kinds.is_empty() {
        return vec![
            "code_blocks".into(),
            "inline_code".into(),
            "urls".into(),
            "placeholders".into(),
        ];
    }

    if kinds
        .iter()
        .any(|kind| kind.trim().eq_ignore_ascii_case("none"))
    {
        return Vec::new();
    }

    kinds
        .iter()
        .map(|kind| kind.trim().to_ascii_lowercase())
        .filter(|kind| !kind.is_empty())
        .collect()
}

pub fn validate_preserve(output: &str, source: &str, preserve_kinds: &[String]) -> Result<()> {
    let tokens = extract_preservables(source, preserve_kinds);
    let missing = tokens
        .into_iter()
        .filter(|token| !output.contains(token))
        .take(5)
        .collect::<Vec<_>>();

    if missing.is_empty() {
        return Ok(());
    }

    Err(anyhow!(
        "preserved tokens missing from output: {}",
        serde_json::to_string(&missing)?
    ))
}

fn extract_preservables(source: &str, preserve_kinds: &[String]) -> Vec<String> {
    let mut working = source.to_string();
    let mut output = Vec::new();

    let mut push = |value: String| {
        if !output.contains(&value) {
            output.push(value);
        }
    };

    if preserve_kinds.iter().any(|kind| kind == "code_blocks") {
        let mut stripped = String::new();
        let mut rest = working.as_str();
        while let Some(start) = rest.find("```") {
            stripped.push_str(&rest[..start]);
            let Some(end_relative) = rest[start + 3..].find("```") else {
                stripped.push_str(&rest[start..]);
                rest = "";
                break;
            };
            let end = start + 3 + end_relative + 3;
            push(rest[start..end].to_string());
            rest = &rest[end..];
        }
        stripped.push_str(rest);
        working = stripped;
    }

    if preserve_kinds.iter().any(|kind| kind == "inline_code") {
        let regex = Regex::new(r"`[^`\n]+`").unwrap();
        for value in regex.find_iter(&working) {
            push(value.as_str().to_string());
        }
    }

    if preserve_kinds.iter().any(|kind| kind == "urls") {
        let regex = Regex::new(r#"https?://[^\s\)"'<>]+"#).unwrap();
        for value in regex.find_iter(&working) {
            push(value.as_str().to_string());
        }
    }

    if preserve_kinds.iter().any(|kind| kind == "placeholders") {
        let regex = Regex::new(r"\{[^\s{}]+\}").unwrap();
        for value in regex.find_iter(&working) {
            push(value.as_str().to_string());
        }
    }

    output
}
