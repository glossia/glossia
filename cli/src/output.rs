pub struct OutputValues {
    pub lang: String,
    pub relpath: String,
    pub basename: String,
    pub ext: String,
}

/// Expand output template with placeholders.
/// Always uses forward slashes in the result (for lock file storage).
pub fn expand_output(template: &str, values: &OutputValues) -> String {
    let out = template
        .replace("{lang}", &values.lang)
        .replace("{relpath}", &values.relpath.replace('\\', "/"))
        .replace("{basename}", &values.basename)
        .replace("{ext}", &values.ext);
    // Normalize multiple slashes
    normalize_slashes(&out)
}

fn normalize_slashes(path: &str) -> String {
    let mut result = String::with_capacity(path.len());
    let mut last_was_slash = false;
    for ch in path.chars() {
        if ch == '/' || ch == '\\' {
            if !last_was_slash {
                result.push('/');
            }
            last_was_slash = true;
        } else {
            result.push(ch);
            last_was_slash = false;
        }
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn expands_all_placeholders() {
        let result = expand_output(
            "i18n/{lang}/{relpath}",
            &OutputValues {
                lang: "es".to_string(),
                relpath: "docs/guide.md".to_string(),
                basename: "guide".to_string(),
                ext: "md".to_string(),
            },
        );
        assert!(result.contains("es"));
        assert!(result.contains("guide.md"));
    }

    #[test]
    fn expands_basename_and_ext() {
        let result = expand_output(
            "out/{lang}/{basename}.{ext}",
            &OutputValues {
                lang: "de".to_string(),
                relpath: "guide.md".to_string(),
                basename: "guide".to_string(),
                ext: "md".to_string(),
            },
        );
        assert!(result.contains("de"));
        assert!(result.contains("guide.md"));
    }
}
