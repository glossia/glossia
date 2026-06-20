use anyhow::{anyhow, Result};
use globset::{GlobBuilder, GlobMatcher};
use std::path::Path;
use walkdir::WalkDir;

use crate::pathing::normalize_slashes;

pub fn walk_files(root: &Path) -> Result<Vec<String>> {
    let mut files = Vec::new();
    for entry in WalkDir::new(root)
        .into_iter()
        .filter_entry(|entry| entry.file_name() != ".git")
    {
        let entry = entry?;
        if !entry.file_type().is_file() {
            continue;
        }
        let relative = entry
            .path()
            .strip_prefix(root)
            .map_err(|err| anyhow!(err))?;
        files.push(normalize_slashes(relative.to_string_lossy()));
    }
    Ok(files)
}

fn compile_matcher(pattern: &str) -> Result<GlobMatcher> {
    let normalized = normalize_slashes(pattern);
    Ok(GlobBuilder::new(&normalized)
        .literal_separator(true)
        .build()?
        .compile_matcher())
}

pub fn glob_files(pattern: &str, files: &[String]) -> Result<Vec<String>> {
    let matcher = compile_matcher(pattern)?;
    Ok(files
        .iter()
        .filter(|file| matcher.is_match(file))
        .cloned()
        .collect())
}

pub fn glob_base(pattern: &str) -> String {
    let normalized = normalize_slashes(pattern);
    if let Some(index) = normalized
        .char_indices()
        .find_map(|(index, ch)| matches!(ch, '*' | '?' | '[').then_some(index))
    {
        let prefix = &normalized[..index];
        let trimmed = prefix.trim_end_matches('/');
        if trimmed.is_empty() {
            return ".".into();
        }
        if prefix.ends_with('/') {
            return trimmed.to_string();
        }
        return trimmed
            .rsplit_once('/')
            .map(|(dir, _)| dir.to_string())
            .unwrap_or_else(|| ".".into());
    }

    normalized
        .rsplit_once('/')
        .map(|(dir, _)| dir.to_string())
        .unwrap_or_else(|| ".".into())
}

#[cfg(test)]
mod tests {
    use super::{glob_base, glob_files};

    #[test]
    fn computes_glob_base_from_wildcards() {
        assert_eq!(glob_base("docs/*.md"), "docs");
        assert_eq!(glob_base("docs/**/*.md"), "docs");
        assert_eq!(glob_base("*.md"), ".");
        assert_eq!(glob_base("priv/gettext/errors.pot"), "priv/gettext");
    }

    #[test]
    fn matches_globs_without_custom_regex_translation() {
        let files = vec![
            "docs/guide.md".into(),
            "docs/nested/guide.md".into(),
            "notes.md".into(),
        ];

        assert_eq!(
            glob_files("docs/*.md", &files).unwrap(),
            vec!["docs/guide.md".to_string()]
        );
        assert_eq!(
            glob_files("docs/**/*.md", &files).unwrap(),
            vec![
                "docs/guide.md".to_string(),
                "docs/nested/guide.md".to_string()
            ]
        );
    }
}
