use anyhow::{anyhow, Result};
use std::path::Path;

use crate::output::{expand_output, normalize_slashes_collapsed, OutputValues};
use crate::pathing::normalize_slashes;

pub fn build_output_path(
    source_target_template: Option<&str>,
    output_template: Option<&str>,
    target_path_template: Option<&str>,
    locale: &str,
    rel_source: &str,
    rel_source_path: &Path,
) -> Result<String> {
    let basename = rel_source_path
        .file_stem()
        .and_then(|value| value.to_str())
        .unwrap_or_default()
        .to_string();
    let ext = rel_source_path
        .extension()
        .and_then(|value| value.to_str())
        .unwrap_or_default()
        .to_string();
    let values = OutputValues {
        lang: locale,
        locale,
        relpath: rel_source,
        basename: &basename,
        ext: &ext,
    };

    if let Some(template) = source_target_template {
        return build_mapped_output_path(template, &values, rel_source_path);
    }

    if let Some(template) = output_template {
        return Ok(expand_output(template, &values));
    }

    let target_path = target_path_template
        .ok_or_else(|| anyhow!("frontmatter target_path or output is required"))?;
    let target_dir = expand_output(target_path, &values);
    let source_parent = rel_source_path
        .parent()
        .map(|path| normalize_slashes(path.to_string_lossy()))
        .unwrap_or_default();
    let output_file = default_output_file(rel_source_path);

    let output_path = if source_parent.is_empty() || source_parent == "." {
        format!("{target_dir}/{output_file}")
    } else {
        format!("{target_dir}/{source_parent}/{output_file}")
    };

    Ok(normalize_slashes_collapsed(&output_path))
}

fn build_mapped_output_path(
    template: &str,
    values: &OutputValues<'_>,
    rel_source_path: &Path,
) -> Result<String> {
    let expanded = expand_output(template, values);
    if expanded.contains("**") || expanded.contains('*') {
        return Ok(normalize_slashes_collapsed(
            &expanded
                .replace("**", &values.relpath.replace('\\', "/"))
                .replace('*', values.basename),
        ));
    }

    let path = Path::new(&expanded);
    if path.extension().is_some() {
        return Ok(expanded);
    }

    let output_file = default_output_file(rel_source_path);
    Ok(normalize_slashes_collapsed(&format!(
        "{expanded}/{output_file}"
    )))
}

fn default_output_file(rel_source_path: &Path) -> String {
    let basename = rel_source_path
        .file_stem()
        .and_then(|value| value.to_str())
        .unwrap_or_default();
    let ext = rel_source_path
        .extension()
        .and_then(|value| value.to_str())
        .unwrap_or_default();
    if ext.eq_ignore_ascii_case("pot") {
        return format!("{basename}.po");
    }

    rel_source_path
        .file_name()
        .and_then(|value| value.to_str())
        .unwrap_or_default()
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::build_output_path;
    use std::path::Path;

    #[test]
    fn uses_glob_mapping_template_relative_to_match_base() {
        let output = build_output_path(
            Some("docs/i18n/{locale}/*.md"),
            None,
            None,
            "es",
            "guide.md",
            Path::new("guide.md"),
        )
        .unwrap();
        assert_eq!(output, "docs/i18n/es/guide.md");
    }

    #[test]
    fn appends_default_output_file_for_directory_targets() {
        let output = build_output_path(
            Some("priv/gettext/{locale}/LC_MESSAGES"),
            None,
            None,
            "es",
            "errors.pot",
            Path::new("errors.pot"),
        )
        .unwrap();
        assert_eq!(output, "priv/gettext/es/LC_MESSAGES/errors.po");
    }

    #[test]
    fn falls_back_to_target_path_template() {
        let output = build_output_path(
            None,
            None,
            Some("docs/i18n/{locale}"),
            "de",
            "nested/guide.md",
            Path::new("nested/guide.md"),
        )
        .unwrap();
        assert_eq!(output, "docs/i18n/de/nested/guide.md");
    }
}
