use anyhow::{anyhow, Result};
use regex::Regex;
use std::collections::BTreeMap;

pub fn validate_po(content: &str, source: &str) -> Result<()> {
    validate_po_structure(content)?;

    let entries = parse_po_entries(content);
    let Some(header) = entries.iter().find(|entry| entry.msgid.is_empty()) else {
        return Err(anyhow!(
            r#"po file missing header entry (msgid "" with Content-Type)"#
        ));
    };

    let plural_count = extract_plural_forms_count(&header.msgstr);
    if plural_count > 0 {
        for entry in &entries {
            if !entry.has_plural || entry.msgid.is_empty() {
                continue;
            }

            let max_plural = entry
                .plural_msgstr
                .keys()
                .max()
                .copied()
                .unwrap_or(usize::MAX);
            if max_plural == usize::MAX || max_plural + 1 != plural_count {
                return Err(anyhow!(
                    r#"po plural forms mismatch: header declares nplurals={} but entry for "{}" has {} forms"#,
                    plural_count,
                    truncate(&entry.msgid, 40),
                    if max_plural == usize::MAX {
                        0
                    } else {
                        max_plural + 1
                    }
                ));
            }
        }
    }

    if !source.trim().is_empty() {
        validate_format_strings(source, &entries)?;
    }

    let untranslated = entries
        .iter()
        .filter(|entry| {
            entry.msgid.is_empty() && entry.msgstr.is_empty() && entry.plural_msgstr.is_empty()
        })
        .count();
    if untranslated > 0 {
        return Err(anyhow!("po has {untranslated} untranslated entries"));
    }

    Ok(())
}

fn validate_po_structure(content: &str) -> Result<()> {
    let mut state = "";
    let mut has_msgid = false;
    let mut has_msgstr = false;

    for raw_line in content.lines() {
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }

        if line.starts_with("msgid ") {
            if has_msgid && !has_msgstr {
                return Err(anyhow!("po entry missing msgstr"));
            }
            has_msgid = true;
            has_msgstr = false;
            state = "msgid";
            ensure_quoted(line, "po msgid missing quoted string")?;
            continue;
        }

        if line.starts_with("msgid_plural ") {
            if state != "msgid" {
                return Err(anyhow!("po msgid_plural without msgid"));
            }
            ensure_quoted(line, "po msgid_plural missing quoted string")?;
            continue;
        }

        if line.starts_with("msgstr") {
            if !has_msgid {
                return Err(anyhow!("po msgstr without msgid"));
            }
            has_msgstr = true;
            state = "msgstr";
            ensure_quoted(line, "po msgstr missing quoted string")?;
            continue;
        }

        if line.starts_with('"') {
            if state.is_empty() {
                return Err(anyhow!("po stray quoted string"));
            }
            continue;
        }

        return Err(anyhow!("po invalid line: {line}"));
    }

    if has_msgid && !has_msgstr {
        return Err(anyhow!("po entry missing msgstr"));
    }

    Ok(())
}

#[derive(Debug, Clone, Default)]
struct PoEntry {
    msgid: String,
    msgstr: String,
    has_plural: bool,
    plural_msgstr: BTreeMap<usize, String>,
}

fn parse_po_entries(content: &str) -> Vec<PoEntry> {
    let mut entries = Vec::new();
    let mut current = PoEntry::default();
    let mut state = String::new();
    let mut plural_index = None;
    let mut in_entry = false;

    let push_current = |entries: &mut Vec<PoEntry>,
                        current: &mut PoEntry,
                        state: &mut String,
                        plural_index: &mut Option<usize>,
                        in_entry: &mut bool| {
        if !*in_entry {
            return;
        }
        entries.push(current.clone());
        *current = PoEntry::default();
        state.clear();
        *plural_index = None;
        *in_entry = false;
    };

    for raw_line in content.lines() {
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') {
            push_current(
                &mut entries,
                &mut current,
                &mut state,
                &mut plural_index,
                &mut in_entry,
            );
            continue;
        }

        if line.starts_with("msgid ") {
            push_current(
                &mut entries,
                &mut current,
                &mut state,
                &mut plural_index,
                &mut in_entry,
            );
            in_entry = true;
            state = "msgid".into();
            current.msgid = extract_quoted(line);
            continue;
        }

        if line.starts_with("msgid_plural ") {
            current.has_plural = true;
            state = "msgid_plural".into();
            continue;
        }

        if line.starts_with("msgstr[") {
            let closing = line.find(']').unwrap_or(7);
            let index = line[7..closing].parse::<usize>().unwrap_or(0);
            plural_index = Some(index);
            state = "msgstr_plural".into();
            current.plural_msgstr.insert(index, extract_quoted(line));
            continue;
        }

        if line.starts_with("msgstr ") {
            state = "msgstr".into();
            current.msgstr = extract_quoted(line);
            continue;
        }

        if line.starts_with('"') {
            let continuation = extract_quoted_raw(line);
            match state.as_str() {
                "msgid" => current.msgid.push_str(&continuation),
                "msgstr" => current.msgstr.push_str(&continuation),
                "msgstr_plural" => {
                    if let Some(index) = plural_index {
                        current
                            .plural_msgstr
                            .entry(index)
                            .and_modify(|value| value.push_str(&continuation));
                    }
                }
                _ => {}
            }
        }
    }

    push_current(
        &mut entries,
        &mut current,
        &mut state,
        &mut plural_index,
        &mut in_entry,
    );

    entries
}

fn validate_format_strings(source: &str, translated_entries: &[PoEntry]) -> Result<()> {
    let source_entries = parse_po_entries(source);
    let format_regex =
        Regex::new(r"%[sdfiu%]|%\([^)]+\)[sdfiu]|\{[0-9]+\}|\{[a-zA-Z_][a-zA-Z0-9_]*\}").unwrap();

    for source_entry in source_entries {
        if source_entry.msgid.trim().is_empty() {
            continue;
        }

        let Some(translated) = translated_entries
            .iter()
            .find(|entry| entry.msgid == source_entry.msgid)
        else {
            continue;
        };

        if translated.msgstr.trim().is_empty() {
            continue;
        }

        for format_string in format_regex.find_iter(&source_entry.msgstr) {
            let format_string = format_string.as_str();
            if !translated.msgstr.contains(format_string) {
                return Err(anyhow!(
                    r#"po format string "{}" in source msgstr for "{}" missing from translation"#,
                    format_string,
                    truncate(&source_entry.msgid, 40)
                ));
            }
        }
    }

    Ok(())
}

fn ensure_quoted(line: &str, message: &str) -> Result<()> {
    if line.matches('"').count() >= 2 {
        Ok(())
    } else {
        Err(anyhow!(message.to_string()))
    }
}

fn extract_quoted(line: &str) -> String {
    let Some(first) = line.find('"') else {
        return String::new();
    };
    extract_quoted_raw(&line[first..])
}

fn extract_quoted_raw(line: &str) -> String {
    serde_json::from_str::<String>(line).unwrap_or_default()
}

fn extract_plural_forms_count(header: &str) -> usize {
    let regex = Regex::new(r"(?m)^Plural-Forms:\s*nplurals=(\d+);").unwrap();
    regex
        .captures(header)
        .and_then(|captures| captures.get(1))
        .and_then(|match_| match_.as_str().parse::<usize>().ok())
        .unwrap_or(0)
}

fn truncate(input: &str, max_len: usize) -> String {
    if input.chars().count() <= max_len {
        return input.to_string();
    }
    input.chars().take(max_len).collect::<String>() + "..."
}

#[cfg(test)]
mod tests {
    use super::validate_po;

    #[test]
    fn validates_valid_po() {
        let source = r#"msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"
"Plural-Forms: nplurals=2; plural=n != 1;\n"

msgid "Hello"
msgstr "Hello"
"#;

        validate_po(source, source).unwrap();
    }
}
