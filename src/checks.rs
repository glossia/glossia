use anyhow::Result;
use regex::Regex;
use std::collections::{HashMap, HashSet};
use std::path::Path;
use thiserror::Error;
use tokio::fs;

use crate::format::Format;
use crate::reporter::{Reporter, Verb};

#[derive(Error, Debug)]
#[error("{tool} tool failed: {message}")]
pub struct ToolError {
    pub tool: String,
    pub message: String,
}

impl ToolError {
    pub fn new(tool: &str, msg: &str) -> Self {
        Self {
            tool: tool.to_string(),
            message: msg.to_string(),
        }
    }
}

pub struct CheckOptions<'a> {
    pub preserve: &'a [String],
    pub check_cmd: Option<&'a str>,
    pub check_cmds: Option<&'a HashMap<String, String>>,
    pub reporter: Option<&'a dyn Reporter>,
    pub label: Option<&'a str>,
    pub current: usize,
    pub total: usize,
}

const DEFAULT_PRESERVE: &[&str] = &["code_blocks", "inline_code", "urls", "placeholders"];

pub async fn validate(
    root: &str,
    format: Format,
    output: &str,
    source: &str,
    opts: &CheckOptions<'_>,
) -> Result<()> {
    if let (Some(reporter), Some(label)) = (opts.reporter, opts.label)
        && !label.trim().is_empty()
    {
        reporter.step(Verb::Validating, opts.current, opts.total, label);
    }

    // Syntax validation
    if let Some(reporter) = opts.reporter {
        reporter.log(
            Verb::Checking,
            &format!("syntax-validator: parse {}", format.label()),
        );
    }
    if let Some(err) = validate_syntax(format, output) {
        return Err(ToolError::new("syntax-validator", &err).into());
    }

    // Preserve checks
    let preserve_kinds = resolve_preserve(opts.preserve);
    if !preserve_kinds.is_empty() {
        if let Some(reporter) = opts.reporter {
            reporter.log(Verb::Checking, "preserve-check: verify preserved tokens");
        }
        if let Some(err) = validate_preserve(output, source, &preserve_kinds) {
            return Err(ToolError::new("preserve-check", &err).into());
        }
    }

    // Custom command
    let cmd = select_check_cmd(format, opts.check_cmd, opts.check_cmds);
    if !cmd.is_empty() {
        if let Some(reporter) = opts.reporter {
            reporter.log(Verb::Checking, "custom-command: run check_cmd");
        }
        run_external(root, &cmd, output).await?;
    }

    Ok(())
}

pub fn validate_syntax(format: Format, output: &str) -> Option<String> {
    match format {
        Format::Json => {
            if let Err(e) = serde_json::from_str::<serde_json::Value>(output) {
                return Some(format!("json invalid: {}", e));
            }
        }
        Format::Yaml => {
            if let Err(e) = serde_yaml::from_str::<serde_yaml::Value>(output) {
                return Some(format!("yaml invalid: {}", e));
            }
        }
        Format::Po => return validate_po(output),
        Format::Markdown => return validate_markdown(output),
        Format::Text => {}
    }
    None
}

fn validate_markdown(content: &str) -> Option<String> {
    let lines: Vec<&str> = content.split('\n').collect();
    if lines.is_empty() {
        return None;
    }
    let first = lines[0].trim();
    if first != "---" && first != "+++" {
        return None;
    }

    let mut end = None;
    for (i, line) in lines.iter().enumerate().skip(1) {
        if line.trim() == first {
            end = Some(i);
            break;
        }
    }
    let end = match end {
        Some(e) => e,
        None => return Some(format!("markdown frontmatter missing closing {}", first)),
    };

    let frontmatter = lines[1..end].join("\n");
    if first == "---" {
        if let Err(e) = serde_yaml::from_str::<serde_yaml::Value>(&frontmatter) {
            return Some(format!("markdown frontmatter invalid yaml: {}", e));
        }
        return None;
    }

    if let Err(e) = frontmatter.parse::<toml::Value>() {
        return Some(format!("markdown frontmatter invalid toml: {}", e));
    }
    None
}

fn validate_po(content: &str) -> Option<String> {
    let lines: Vec<&str> = content.split('\n').collect();
    let mut state = "";
    let mut has_msgid = false;
    let mut has_msgstr = false;

    for raw_line in &lines {
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }

        if line.starts_with("msgid ") {
            if has_msgid && !has_msgstr {
                return Some("po entry missing msgstr".to_string());
            }
            has_msgid = true;
            has_msgstr = false;
            state = "msgid";
            if !has_quoted_string(line) {
                return Some("po msgid missing quoted string".to_string());
            }
        } else if line.starts_with("msgid_plural ") {
            if state != "msgid" {
                return Some("po msgid_plural without msgid".to_string());
            }
            if !has_quoted_string(line) {
                return Some("po msgid_plural missing quoted string".to_string());
            }
        } else if line.starts_with("msgstr") {
            if !has_msgid {
                return Some("po msgstr without msgid".to_string());
            }
            has_msgstr = true;
            state = "msgstr";
            if !has_quoted_string(line) {
                return Some("po msgstr missing quoted string".to_string());
            }
        } else if line.starts_with('"') {
            if state.is_empty() {
                return Some("po stray quoted string".to_string());
            }
        } else {
            return Some(format!("po invalid line: {}", line));
        }
    }
    if has_msgid && !has_msgstr {
        return Some("po entry missing msgstr".to_string());
    }
    None
}

fn has_quoted_string(line: &str) -> bool {
    let mut count = 0;
    let mut escaped = false;
    for ch in line.chars() {
        if ch == '\\' && !escaped {
            escaped = true;
            continue;
        }
        if ch == '"' && !escaped {
            count += 1;
        }
        escaped = false;
    }
    count >= 2
}

pub fn resolve_preserve(preserve: &[String]) -> HashSet<String> {
    if preserve.is_empty() {
        return DEFAULT_PRESERVE.iter().map(|s| s.to_string()).collect();
    }
    for v in preserve {
        if v.trim().to_lowercase() == "none" {
            return HashSet::new();
        }
    }
    preserve.iter().map(|k| k.trim().to_lowercase()).collect()
}

pub fn extract_preservables(source: &str, kinds: &HashSet<String>) -> Vec<String> {
    let mut tokens = Vec::new();
    let mut seen = HashSet::new();
    let mut text = source.to_string();

    let code_block_re = Regex::new(r"```[\s\S]*?```").unwrap();
    let inline_code_re = Regex::new(r"`[^`\n]+`").unwrap();
    let url_re = Regex::new(r#"https?://[^\s)"'<>]+"#).unwrap();
    let placeholder_re = Regex::new(r"\{[^\s{}]+\}").unwrap();

    if kinds.contains("code_blocks") {
        for mat in code_block_re.find_iter(&text) {
            let s = mat.as_str().to_string();
            if seen.insert(s.clone()) {
                tokens.push(s);
            }
        }
        text = code_block_re.replace_all(&text, "").to_string();
    }
    if kinds.contains("inline_code") {
        for mat in inline_code_re.find_iter(&text) {
            let s = mat.as_str().to_string();
            if seen.insert(s.clone()) {
                tokens.push(s);
            }
        }
    }
    if kinds.contains("urls") {
        for mat in url_re.find_iter(&text) {
            let s = mat.as_str().to_string();
            if seen.insert(s.clone()) {
                tokens.push(s);
            }
        }
    }
    if kinds.contains("placeholders") {
        for mat in placeholder_re.find_iter(&text) {
            let s = mat.as_str().to_string();
            if seen.insert(s.clone()) {
                tokens.push(s);
            }
        }
    }
    tokens
}

pub fn validate_preserve(output: &str, source: &str, kinds: &HashSet<String>) -> Option<String> {
    let preservables = extract_preservables(source, kinds);
    let mut missing = Vec::new();
    for token in &preservables {
        if !output.contains(token.as_str()) {
            missing.push(token.clone());
            if missing.len() >= 5 {
                break;
            }
        }
    }
    if !missing.is_empty() {
        return Some(format!(
            "preserved tokens missing from output: {:?}",
            missing
        ));
    }
    None
}

fn select_check_cmd(
    format: Format,
    fallback: Option<&str>,
    cmds: Option<&HashMap<String, String>>,
) -> String {
    if let Some(cmds) = cmds
        && let Some(value) = cmds.get(format.as_str())
        && !value.trim().is_empty()
    {
        return value.clone();
    }
    fallback.unwrap_or("").trim().to_string()
}

pub async fn run_external(root: &str, cmd_template: &str, content: &str) -> Result<()> {
    if root.is_empty() {
        anyhow::bail!("external check requires root path");
    }

    let tmp_dir = Path::new(root).join(".l10n").join("tmp");
    fs::create_dir_all(&tmp_dir).await?;

    let tmp_file = tmp_dir.join(format!(
        "check-{}-{}.tmp",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis(),
        rand_suffix()
    ));

    fs::write(&tmp_file, content).await?;

    let cmd_text = cmd_template.replace("{path}", &tmp_file.to_string_lossy());

    let result = tokio::process::Command::new("sh")
        .arg("-c")
        .arg(&cmd_text)
        .current_dir(root)
        .output()
        .await;

    let _ = fs::remove_file(&tmp_file).await;

    match result {
        Ok(output) => {
            if !output.status.success() {
                let stderr = String::from_utf8_lossy(&output.stderr);
                let stdout = String::from_utf8_lossy(&output.stdout);
                let combined = format!("{}\n{}", stderr, stdout).trim().to_string();
                anyhow::bail!(
                    "external check failed: exit {}\n{}",
                    output.status,
                    combined
                );
            }
            Ok(())
        }
        Err(e) => anyhow::bail!("external check failed: {}", e),
    }
}

pub fn validate_po_thorough(content: &str, source: Option<&str>) -> Option<String> {
    // Run basic structural checks first
    if let Some(err) = validate_po(content) {
        return Some(err);
    }

    let entries = parse_po_entries(content);

    // Check for PO header entry (msgid "" with Content-Type)
    let has_header = entries.iter().any(|e| e.msgid.is_empty() && !e.msgstr.is_empty());
    if !has_header && !entries.is_empty() {
        return Some("po file missing header entry (msgid \"\" with Content-Type)".to_string());
    }

    // Validate plural forms consistency
    if let Some(header_entry) = entries.iter().find(|e| e.msgid.is_empty()) {
        let header_text = &header_entry.msgstr;
        let plural_forms_n = extract_plural_forms_count(header_text);
        if let Some(n) = plural_forms_n {
            for entry in &entries {
                if entry.has_plural && !entry.msgid.is_empty() {
                    let max_idx = entry.plural_msgstrs.keys().max().copied().unwrap_or(0);
                    if max_idx + 1 != n {
                        return Some(format!(
                            "po plural forms mismatch: header declares nplurals={} but entry for \"{}\" has {} forms",
                            n,
                            truncate_str(&entry.msgid, 40),
                            max_idx + 1
                        ));
                    }
                }
            }
        }
    }

    // Format string preservation check (if source provided)
    if let Some(src) = source {
        let src_entries = parse_po_entries(src);
        let format_re = Regex::new(r"%[sdfiu%]|%\([^)]+\)[sdfiu]|\{[0-9]+\}|\{[a-zA-Z_][a-zA-Z0-9_]*\}").unwrap();

        for src_entry in &src_entries {
            if src_entry.msgid.is_empty() {
                continue;
            }
            // Find matching entry in translated content
            if let Some(translated) = entries.iter().find(|e| e.msgid == src_entry.msgid) {
                let src_formats: Vec<&str> = format_re
                    .find_iter(&src_entry.msgstr)
                    .map(|m| m.as_str())
                    .collect();

                if !src_formats.is_empty() && !translated.msgstr.is_empty() {
                    for fmt in &src_formats {
                        if !translated.msgstr.contains(fmt) {
                            return Some(format!(
                                "po format string \"{}\" in source msgstr for \"{}\" missing from translation",
                                fmt,
                                truncate_str(&src_entry.msgid, 40)
                            ));
                        }
                    }
                }
            }
        }
    }

    // Count untranslated entries
    let untranslated: Vec<&PoEntry> = entries
        .iter()
        .filter(|e| !e.msgid.is_empty() && e.msgstr.is_empty() && e.plural_msgstrs.is_empty())
        .collect();
    if !untranslated.is_empty() {
        return Some(format!(
            "po has {} untranslated entries (first: \"{}\")",
            untranslated.len(),
            truncate_str(&untranslated[0].msgid, 40)
        ));
    }

    None
}

struct PoEntry {
    msgid: String,
    msgstr: String,
    has_plural: bool,
    plural_msgstrs: HashMap<usize, String>,
}

fn parse_po_entries(content: &str) -> Vec<PoEntry> {
    let mut entries = Vec::new();
    let mut current_msgid = String::new();
    let mut current_msgstr = String::new();
    let mut current_plural_msgstrs: HashMap<usize, String> = HashMap::new();
    let mut has_plural = false;
    let mut state = "";
    let mut current_plural_idx: Option<usize> = None;
    let mut in_entry = false;

    for raw_line in content.split('\n') {
        let line = raw_line.trim();

        if line.is_empty() || line.starts_with('#') {
            if in_entry {
                entries.push(PoEntry {
                    msgid: current_msgid.clone(),
                    msgstr: current_msgstr.clone(),
                    has_plural,
                    plural_msgstrs: current_plural_msgstrs.clone(),
                });
                current_msgid.clear();
                current_msgstr.clear();
                current_plural_msgstrs.clear();
                has_plural = false;
                state = "";
                current_plural_idx = None;
                in_entry = false;
            }
            continue;
        }

        if line.starts_with("msgid ") {
            if in_entry {
                entries.push(PoEntry {
                    msgid: current_msgid.clone(),
                    msgstr: current_msgstr.clone(),
                    has_plural,
                    plural_msgstrs: current_plural_msgstrs.clone(),
                });
                current_msgid.clear();
                current_msgstr.clear();
                current_plural_msgstrs.clear();
                has_plural = false;
                current_plural_idx = None;
            }
            in_entry = true;
            state = "msgid";
            current_msgid = extract_quoted(line);
        } else if line.starts_with("msgid_plural ") {
            has_plural = true;
            state = "msgid_plural";
        } else if line.starts_with("msgstr[") {
            let idx = line
                .chars()
                .skip(7)
                .take_while(|c| c.is_ascii_digit())
                .collect::<String>()
                .parse::<usize>()
                .unwrap_or(0);
            current_plural_idx = Some(idx);
            state = "msgstr_plural";
            let val = extract_quoted(line);
            current_plural_msgstrs.insert(idx, val);
        } else if line.starts_with("msgstr ") {
            state = "msgstr";
            current_msgstr = extract_quoted(line);
        } else if line.starts_with('"') {
            let continuation = extract_quoted_raw(line);
            match state {
                "msgid" => current_msgid.push_str(&continuation),
                "msgstr" => current_msgstr.push_str(&continuation),
                "msgstr_plural" => {
                    if let Some(idx) = current_plural_idx {
                        current_plural_msgstrs
                            .entry(idx)
                            .or_default()
                            .push_str(&continuation);
                    }
                }
                _ => {}
            }
        }
    }

    if in_entry {
        entries.push(PoEntry {
            msgid: current_msgid,
            msgstr: current_msgstr,
            has_plural,
            plural_msgstrs: current_plural_msgstrs,
        });
    }

    entries
}

fn extract_quoted(line: &str) -> String {
    if let Some(start) = line.find('"') {
        extract_quoted_raw(&line[start..])
    } else {
        String::new()
    }
}

fn extract_quoted_raw(line: &str) -> String {
    let trimmed = line.trim();
    if trimmed.len() < 2 || !trimmed.starts_with('"') || !trimmed.ends_with('"') {
        return String::new();
    }
    let inner = &trimmed[1..trimmed.len() - 1];
    inner
        .replace("\\n", "\n")
        .replace("\\t", "\t")
        .replace("\\\"", "\"")
        .replace("\\\\", "\\")
}

fn extract_plural_forms_count(header: &str) -> Option<usize> {
    for line in header.split("\\n").chain(header.split('\n')) {
        let trimmed = line.trim().to_lowercase();
        if trimmed.starts_with("plural-forms:")
            && let Some(nplurals_pos) = trimmed.find("nplurals=")
        {
            let after = &trimmed[nplurals_pos + 9..];
            let num_str: String = after.chars().take_while(|c| c.is_ascii_digit()).collect();
            return num_str.parse().ok();
        }
    }
    None
}

fn truncate_str(s: &str, max: usize) -> String {
    if s.len() <= max {
        s.to_string()
    } else {
        format!("{}...", &s[..max])
    }
}

fn rand_suffix() -> String {
    use std::time::SystemTime;
    let nanos = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap_or_default()
        .subsec_nanos();
    format!("{:x}", nanos)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn validates_valid_json() {
        let opts = CheckOptions {
            preserve: &["none".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let result = validate("/tmp", Format::Json, r#"{"key": "value"}"#, "", &opts).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn rejects_invalid_json() {
        let opts = CheckOptions {
            preserve: &["none".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let result = validate("/tmp", Format::Json, "not json", "", &opts).await;
        assert!(result.is_err());
        let err = result.unwrap_err().to_string();
        assert!(err.contains("syntax-validator"));
    }

    #[tokio::test]
    async fn validates_valid_yaml() {
        let opts = CheckOptions {
            preserve: &["none".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let result = validate("/tmp", Format::Yaml, "key: value\n", "", &opts).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn validates_valid_po() {
        let opts = CheckOptions {
            preserve: &["none".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let po = "msgid \"hello\"\nmsgstr \"hola\"\n";
        let result = validate("/tmp", Format::Po, po, "", &opts).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn rejects_po_with_missing_msgstr() {
        let opts = CheckOptions {
            preserve: &["none".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let po = "msgid \"hello\"\nmsgid \"world\"\n";
        let result = validate("/tmp", Format::Po, po, "", &opts).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn validates_markdown_frontmatter() {
        let opts = CheckOptions {
            preserve: &["none".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let md = "---\ntitle: Test\n---\nContent here";
        let result = validate("/tmp", Format::Markdown, md, "", &opts).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn rejects_broken_markdown_frontmatter() {
        let opts = CheckOptions {
            preserve: &["none".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let md = "---\ntitle: [invalid\n---\nContent";
        let result = validate("/tmp", Format::Markdown, md, "", &opts).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn passes_when_all_tokens_preserved() {
        let opts = CheckOptions {
            preserve: &["inline_code".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let result = validate(
            "/tmp",
            Format::Text,
            "Hola `code` mundo",
            "Hello `code` world",
            &opts,
        )
        .await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn fails_when_tokens_missing() {
        let opts = CheckOptions {
            preserve: &["inline_code".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let result = validate(
            "/tmp",
            Format::Text,
            "Hola mundo",
            "Hello `code` world",
            &opts,
        )
        .await;
        assert!(result.is_err());
        let err = result.unwrap_err().to_string();
        assert!(err.contains("preserve-check"));
    }

    #[tokio::test]
    async fn skips_preserve_check_with_none() {
        let opts = CheckOptions {
            preserve: &["none".to_string()],
            check_cmd: None,
            check_cmds: None,
            reporter: None,
            label: None,
            current: 0,
            total: 0,
        };
        let result = validate(
            "/tmp",
            Format::Text,
            "Hola mundo",
            "Hello `code` world",
            &opts,
        )
        .await;
        assert!(result.is_ok());
    }
}
