use anyhow::{anyhow, Result};
use regex::Regex;
use std::collections::BTreeSet;
use std::sync::LazyLock;

use super::{Frontmatter, SourceSpec, TargetSpec};

static LOCALE_IDENTIFIER_REGEX: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$").expect("valid locale regex")
});

#[derive(Debug, Clone, PartialEq, Eq)]
enum DocumentKind {
    Global,
    Scoped,
    LocaleOverlay { filename_locale: String },
}

pub(super) fn validate_document(relative_path: &str, frontmatter: &Frontmatter) -> Result<()> {
    match classify_document(relative_path)? {
        DocumentKind::Global => validate_global_document(frontmatter),
        DocumentKind::Scoped => validate_scoped_document(frontmatter),
        DocumentKind::LocaleOverlay { filename_locale } => {
            validate_locale_overlay(frontmatter, &filename_locale)
        }
    }
}

fn validate_global_document(frontmatter: &Frontmatter) -> Result<()> {
    let source_language = frontmatter
        .source_language
        .as_deref()
        .ok_or_else(|| anyhow!("L10N.md must declare source_language"))?;
    validate_locale_identifier("source_language", source_language)?;
    validate_shared_fields(frontmatter)
}

fn validate_scoped_document(frontmatter: &Frontmatter) -> Result<()> {
    validate_shared_fields(frontmatter)
}

fn validate_locale_overlay(frontmatter: &Frontmatter, filename_locale: &str) -> Result<()> {
    if let Some(locale) = frontmatter.locale.as_deref() {
        validate_locale_identifier("locale", locale)?;
        if locale != filename_locale {
            return Err(anyhow!(
                "locale overlay declares locale {}, expected {}",
                locale,
                filename_locale
            ));
        }
    }

    validate_model_identifier(frontmatter.model.as_deref())?;
    validate_validation(frontmatter.validation.as_deref())?;
    Ok(())
}

fn validate_shared_fields(frontmatter: &Frontmatter) -> Result<()> {
    validate_model_identifier(frontmatter.model.as_deref())?;
    validate_validation(frontmatter.validation.as_deref())?;
    validate_sources(frontmatter.sources.as_ref())?;
    validate_targets(frontmatter.targets.as_ref())
}

fn validate_sources(sources: Option<&SourceSpec>) -> Result<()> {
    let Some(sources) = sources else {
        return Ok(());
    };

    match sources {
        SourceSpec::Map(entries) => {
            if entries.is_empty() {
                return Err(anyhow!("sources must contain at least one mapping"));
            }
            for (pattern, target) in entries {
                if pattern.trim().is_empty() {
                    return Err(anyhow!("source patterns must be non-empty"));
                }
                if target.trim().is_empty() {
                    return Err(anyhow!("target path templates must be non-empty"));
                }
            }
            Ok(())
        }
        SourceSpec::List(_) => Err(anyhow!(
            "sources must be a mapping of source patterns to target path templates"
        )),
    }
}

fn validate_targets(targets: Option<&TargetSpec>) -> Result<()> {
    let Some(targets) = targets else {
        return Ok(());
    };

    match targets {
        TargetSpec::List(locales) => {
            if locales.is_empty() {
                return Err(anyhow!("targets must contain at least one locale"));
            }
            let mut seen = BTreeSet::new();
            for locale in locales {
                validate_locale_identifier("targets", locale)?;
                if !seen.insert(locale) {
                    return Err(anyhow!("targets must not contain duplicate locales"));
                }
            }
            Ok(())
        }
        TargetSpec::Map(locales) => {
            for (locale, language) in locales {
                validate_locale_identifier("targets", locale)?;
                if language.trim().is_empty() {
                    return Err(anyhow!("target language labels must be non-empty"));
                }
            }
            Ok(())
        }
    }
}

fn validate_validation(command: Option<&[String]>) -> Result<()> {
    let Some(command) = command else {
        return Ok(());
    };
    if command.is_empty() {
        return Err(anyhow!("validation must contain at least one argument"));
    }
    if command.iter().any(|arg| arg.trim().is_empty()) {
        return Err(anyhow!("validation arguments must be non-empty"));
    }
    Ok(())
}

fn validate_model_identifier(model: Option<&str>) -> Result<()> {
    let Some(model) = model else {
        return Ok(());
    };
    if model.trim().is_empty() {
        return Err(anyhow!("model must be a non-empty model identifier"));
    }
    Ok(())
}

fn validate_locale_identifier(field: &str, locale: &str) -> Result<()> {
    if LOCALE_IDENTIFIER_REGEX.is_match(locale) {
        return Ok(());
    }
    Err(anyhow!("{field} must be a valid locale identifier"))
}

fn classify_document(relative_path: &str) -> Result<DocumentKind> {
    if relative_path == "L10N.md" {
        return Ok(DocumentKind::Global);
    }

    if let Some(filename) = relative_path.strip_prefix("L10N/") {
        return classify_locale_overlay(filename);
    }
    if let Some(filename) = relative_path.strip_prefix("./L10N/") {
        return classify_locale_overlay(filename);
    }
    if let Some((dir, filename)) = relative_path.rsplit_once("/L10N/") {
        if !dir.is_empty() {
            return classify_locale_overlay(filename);
        }
    }

    if relative_path.ends_with("/L10N.md") {
        return Ok(DocumentKind::Scoped);
    }

    Err(anyhow!("unsupported L10N document path {relative_path}"))
}

fn classify_locale_overlay(filename: &str) -> Result<DocumentKind> {
    let locale = filename
        .strip_suffix(".md")
        .ok_or_else(|| anyhow!("unsupported locale overlay path L10N/{filename}"))?;
    if locale.is_empty() {
        return Err(anyhow!("locale overlay file name must not be empty"));
    }
    if locale
        .chars()
        .any(|ch| !ch.is_ascii_alphanumeric() && ch != '-' && ch != '_')
    {
        return Err(anyhow!(
            "locale overlay file name contains invalid characters"
        ));
    }

    Ok(DocumentKind::LocaleOverlay {
        filename_locale: locale.to_string(),
    })
}

#[cfg(test)]
mod tests {
    use super::validate_document;
    use crate::config::{Frontmatter, SourceSpec, TargetSpec};
    use std::collections::BTreeMap;

    #[test]
    fn rejects_root_document_without_source_language() {
        let error = validate_document("L10N.md", &Frontmatter::default()).unwrap_err();
        assert_eq!(error.to_string(), "L10N.md must declare source_language");
    }

    #[test]
    fn rejects_top_level_sources_list_for_spec_documents() {
        let error = validate_document(
            "docs/L10N.md",
            &Frontmatter {
                sources: Some(SourceSpec::List(vec!["docs/*.md".into()])),
                ..Frontmatter::default()
            },
        )
        .unwrap_err();
        assert_eq!(
            error.to_string(),
            "sources must be a mapping of source patterns to target path templates"
        );
    }

    #[test]
    fn rejects_duplicate_targets_in_spec_documents() {
        let error = validate_document(
            "docs/L10N.md",
            &Frontmatter {
                targets: Some(TargetSpec::List(vec!["es".into(), "es".into()])),
                ..Frontmatter::default()
            },
        )
        .unwrap_err();
        assert_eq!(
            error.to_string(),
            "targets must not contain duplicate locales"
        );
    }

    #[test]
    fn accepts_mapped_sources_and_list_targets() {
        let mut sources = BTreeMap::new();
        sources.insert("docs/*.md".into(), "docs/i18n/{locale}/*.md".into());

        validate_document(
            "docs/L10N.md",
            &Frontmatter {
                sources: Some(SourceSpec::Map(sources)),
                targets: Some(TargetSpec::List(vec!["es".into(), "ja".into()])),
                ..Frontmatter::default()
            },
        )
        .unwrap();
    }

    #[test]
    fn accepts_locale_overlay_when_locale_matches_filename() {
        validate_document(
            "docs/L10N/es.md",
            &Frontmatter {
                locale: Some("es".into()),
                model: Some("openai/gpt-5".into()),
                ..Frontmatter::default()
            },
        )
        .unwrap();
    }

    #[test]
    fn rejects_empty_model_identifier() {
        let error = validate_document(
            "docs/L10N.md",
            &Frontmatter {
                model: Some("   ".into()),
                ..Frontmatter::default()
            },
        )
        .unwrap_err();
        assert_eq!(
            error.to_string(),
            "model must be a non-empty model identifier"
        );
    }
}
