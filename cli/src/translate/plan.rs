use anyhow::Result;
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use crate::config::{
    find_translation_roots, load_locale_override, resolve_chain, DeclaredValidation,
    FrontmatterMode,
};
use crate::context::{local_context_snapshot, local_locale_override_snapshot, ContextSnapshot};
use crate::format::Format;
use crate::glob::{glob_base, glob_files, walk_files};
use crate::llm::LlmConfig;
use crate::pathing::{relative_path, relative_to_root};
use crate::runtime_config::RuntimeConfig;
use crate::translate::output_path::build_output_path;

#[derive(Debug, Clone)]
pub struct TranslationPlan {
    pub items: Vec<WorkItem>,
}

// The translate command moved server-side; the remaining commands (status,
// check, clean) read a subset of these fields, and the context accessors below
// are exercised by the planner tests, so keep the full planning model.
#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct WorkItem {
    pub source_abs: PathBuf,
    pub source_path: String,
    pub output_abs: PathBuf,
    pub output_path: String,
    pub locale: String,
    pub language: String,
    pub source_language: String,
    pub format: Format,
    pub frontmatter_mode: FrontmatterMode,
    pub preserve: Vec<String>,
    pub prompt: Option<String>,
    pub check_cmd: Option<String>,
    pub check_cmds: BTreeMap<String, String>,
    pub validation: Option<Vec<String>>,
    pub validation_cwd: Option<PathBuf>,
    pub validation_doc_abs: Option<PathBuf>,
    pub retries: usize,
    pub llm: LlmConfig,
    pub context_snapshots: Vec<ContextSnapshot>,
}

impl WorkItem {
    pub fn label(&self) -> String {
        format!(
            "{} -> {} ({})",
            self.source_path, self.output_path, self.locale
        )
    }

    #[allow(dead_code)]
    pub fn context_body(&self) -> String {
        scope_content(&self.context_snapshots, "project_context")
    }

    #[allow(dead_code)]
    pub fn locale_override_body(&self) -> String {
        scope_content(&self.context_snapshots, "locale_override")
    }
}

pub fn build_plan(
    root: &Path,
    locale_filter: Option<&str>,
    runtime: &RuntimeConfig,
) -> Result<TranslationPlan> {
    let translation_roots = find_translation_roots(root)?;
    let mut items = Vec::new();

    for translation_root in translation_roots {
        let root_resolved = resolve_chain(&translation_root, root)?;
        let rules = root_resolved.merged_frontmatter.translation_rules()?;
        if rules.is_empty() {
            continue;
        }

        let file_list = walk_files(&translation_root)?;
        let mut resolved_cache = BTreeMap::new();
        let mut locale_override_cache = BTreeMap::new();

        for rule in rules {
            let excludes = collect_excludes(&rule.exclude, &file_list)?;
            for source in &rule.sources {
                let pattern_base = glob_base(&source.pattern);
                let matches = glob_files(&source.pattern, &file_list)?;
                for matched in matches {
                    if is_glossia_document(&matched) || excludes.contains(&matched) {
                        continue;
                    }

                    let source_abs = translation_root.join(Path::new(&matched));
                    let source_dir = source_abs
                        .parent()
                        .unwrap_or(&translation_root)
                        .to_path_buf();
                    let source_path = relative_to_root(root, &source_abs);
                    let scoped_rel_source =
                        relative_to_glob_base(&translation_root, &pattern_base, &source_abs)?;
                    let resolved = resolved_cache
                        .entry(source_dir.clone())
                        .or_insert(resolve_chain(&source_dir, root)?)
                        .clone();
                    let project_context_snapshot =
                        local_context_snapshot(&source_dir, root, &resolved);
                    let effective_targets = {
                        let targets = resolved.merged_frontmatter.targets();
                        if targets.is_empty() {
                            rule.targets.clone()
                        } else {
                            targets
                        }
                    };

                    for (locale, language) in &effective_targets {
                        if let Some(filter) = locale_filter {
                            if filter != locale {
                                continue;
                            }
                        }

                        let locale_override = locale_override_cache
                            .entry((source_dir.clone(), locale.clone()))
                            .or_insert(load_locale_override(&source_dir, root, locale)?)
                            .clone();
                        let llm = llm_for_locale(
                            &resolved.merged_frontmatter,
                            &locale_override,
                            runtime,
                        )?;
                        let declared_validation = locale_override
                            .validation
                            .as_ref()
                            .or(resolved.validation.as_ref());
                        let mut context_snapshots = vec![project_context_snapshot.clone()];
                        if let Some(locale_override_snapshot) = local_locale_override_snapshot(
                            &translation_root,
                            root,
                            locale,
                            &locale_override,
                        ) {
                            context_snapshots.push(locale_override_snapshot);
                        }
                        let output_rel = build_output_path(
                            source.target_template.as_deref(),
                            rule.output.as_deref(),
                            rule.target_path.as_deref(),
                            locale,
                            &scoped_rel_source,
                            Path::new(&scoped_rel_source),
                        )?;
                        let output_abs = translation_root.join(Path::new(&output_rel));
                        let output_path = relative_to_root(root, &output_abs);
                        let output_format = Format::detect(&output_rel);

                        items.push(WorkItem {
                            source_abs: source_abs.clone(),
                            source_path: source_path.clone(),
                            output_abs,
                            output_path,
                            locale: locale.clone(),
                            language: language.clone(),
                            source_language: resolved
                                .merged_frontmatter
                                .source_language()
                                .to_string(),
                            format: output_format,
                            frontmatter_mode: rule.frontmatter,
                            preserve: rule.preserve.clone(),
                            prompt: rule.prompt.clone(),
                            check_cmd: rule.check_cmd.clone(),
                            check_cmds: rule.check_cmds.clone(),
                            validation: declared_validation.map(|value| value.argv.clone()),
                            validation_cwd: declared_validation
                                .map(|value| validation_cwd(root, value)),
                            validation_doc_abs: declared_validation
                                .map(|value| root.join(&value.relative_path)),
                            retries: rule.retries,
                            llm: llm.clone(),
                            context_snapshots,
                        });
                    }
                }
            }
        }
    }

    items.sort_by(|left, right| {
        left.source_path
            .cmp(&right.source_path)
            .then(left.locale.cmp(&right.locale))
    });

    Ok(TranslationPlan { items })
}

fn collect_excludes(patterns: &[String], file_list: &[String]) -> Result<Vec<String>> {
    let mut excluded = Vec::new();
    for pattern in patterns {
        excluded.extend(glob_files(pattern, file_list)?);
    }
    excluded.sort();
    excluded.dedup();
    Ok(excluded)
}

fn is_glossia_document(relative_path: &str) -> bool {
    relative_path == "GLOSSIA.md"
        || relative_path.ends_with("/GLOSSIA.md")
        || relative_path.starts_with("GLOSSIA/")
        || relative_path.contains("/GLOSSIA/")
}

fn relative_to_glob_base(
    translation_root: &Path,
    pattern_base: &str,
    source_abs: &Path,
) -> Result<String> {
    if pattern_base == "." {
        return Ok(relative_to_root(translation_root, source_abs));
    }

    let base_abs = translation_root.join(Path::new(pattern_base));
    relative_path(&base_abs, source_abs)
}

fn validation_cwd(root: &Path, validation: &DeclaredValidation) -> PathBuf {
    root.join(&validation.relative_path)
        .parent()
        .unwrap_or(root)
        .to_path_buf()
}

fn llm_for_locale(
    inherited: &crate::config::Frontmatter,
    locale_override: &crate::config::LocaleOverrideContext,
    runtime: &RuntimeConfig,
) -> Result<LlmConfig> {
    let mut frontmatter = inherited.clone();
    if let Some(model) = &locale_override.model {
        frontmatter.model = Some(model.clone());
    }
    LlmConfig::from_frontmatter(&frontmatter, &runtime.llm)
}

#[allow(dead_code)]
fn scope_content(snapshots: &[ContextSnapshot], scope: &str) -> String {
    snapshots
        .iter()
        .filter(|snapshot| snapshot.scope == scope)
        .map(|snapshot| snapshot.content.trim())
        .filter(|content| !content.is_empty())
        .collect::<Vec<_>>()
        .join("\n\n")
}

#[cfg(test)]
mod tests {
    use super::{build_plan, scope_content, WorkItem};
    use crate::config::Frontmatter;
    use crate::context::ContextSnapshot;
    use crate::format::Format;
    use crate::llm::LlmConfig;
    use crate::runtime_config::RuntimeConfig;
    use std::collections::BTreeMap;
    use std::fs;
    use std::path::PathBuf;

    #[test]
    fn target_path_uses_path_relative_to_glob_base() {
        let root = tempfile::tempdir().unwrap();
        fs::write(
            root.path().join("GLOSSIA.md"),
            r#"---
source_language: en
model: openai/gpt-5
sources:
  "docs/*.md": "docs/i18n/{locale}/*.md"
target_path: docs/i18n/{locale}
targets:
  es: Spanish
---
Global context
"#,
        )
        .unwrap();
        fs::create_dir_all(root.path().join("docs")).unwrap();
        fs::write(root.path().join("docs").join("guide.md"), "# Guide\n").unwrap();

        let plan = build_plan(root.path(), Some("es"), &RuntimeConfig::default()).unwrap();
        assert_eq!(plan.items.len(), 1);
        assert_eq!(plan.items[0].output_path, "docs/i18n/es/guide.md");
    }

    #[test]
    fn resolves_context_per_matched_source_directory() {
        let root = tempfile::tempdir().unwrap();
        fs::write(
            root.path().join("GLOSSIA.md"),
            r#"---
source_language: en
model: gpt-5
sources:
  "docs/**/*.md": "docs/i18n/{locale}/**"
targets:
  - es
---
Root context
"#,
        )
        .unwrap();
        fs::create_dir_all(root.path().join("docs").join("admin").join("GLOSSIA")).unwrap();
        fs::write(
            root.path().join("docs").join("GLOSSIA.md"),
            "Docs context\n",
        )
        .unwrap();
        fs::write(
            root.path().join("docs").join("admin").join("GLOSSIA.md"),
            "Admin context\n",
        )
        .unwrap();
        fs::write(
            root.path()
                .join("docs")
                .join("admin")
                .join("GLOSSIA")
                .join("es.md"),
            "---\nmodel: gpt-5-mini\n---\nAdmin Spanish\n",
        )
        .unwrap();
        fs::write(
            root.path().join("docs").join("admin").join("guide.md"),
            "# Guide\n",
        )
        .unwrap();

        let plan = build_plan(
            root.path(),
            Some("es"),
            &RuntimeConfig {
                llm: crate::runtime_config::RuntimeLlmConfig {
                    provider: Some("fireworks".into()),
                    base_url: Some("https://api.fireworks.ai/inference/v1".into()),
                    api_key: Some("test-key".into()),
                    ..crate::runtime_config::RuntimeLlmConfig::default()
                },
            },
        )
        .unwrap();
        assert_eq!(plan.items.len(), 1);
        assert_eq!(
            plan.items[0].context_body(),
            "Root context\n\nDocs context\n\nAdmin context"
        );
        assert_eq!(plan.items[0].locale_override_body(), "Admin Spanish");
        assert_eq!(plan.items[0].output_path, "docs/i18n/es/admin/guide.md");
        assert_eq!(plan.items[0].llm.provider, "fireworks");
        assert_eq!(plan.items[0].llm.model, "gpt-5-mini");
    }

    #[test]
    fn scope_content_joins_matching_snapshots_only() {
        let snapshots = vec![
            ContextSnapshot {
                provider: "local_glossia".into(),
                scope: "project_context".into(),
                request_fingerprint: "a".into(),
                snapshot_id: None,
                metadata: BTreeMap::new(),
                content: "Project".into(),
                entries: Vec::new(),
            },
            ContextSnapshot {
                provider: "local_glossia".into(),
                scope: "locale_override".into(),
                request_fingerprint: "b".into(),
                snapshot_id: None,
                metadata: BTreeMap::new(),
                content: "Locale".into(),
                entries: Vec::new(),
            },
            ContextSnapshot {
                provider: "glossia".into(),
                scope: "project_context".into(),
                request_fingerprint: "c".into(),
                snapshot_id: Some("remote".into()),
                metadata: BTreeMap::new(),
                content: "Remote".into(),
                entries: Vec::new(),
            },
        ];

        assert_eq!(
            scope_content(&snapshots, "project_context"),
            "Project\n\nRemote"
        );
        assert_eq!(scope_content(&snapshots, "locale_override"), "Locale");
    }

    #[test]
    fn work_item_derives_prompt_context_from_snapshots() {
        let llm = LlmConfig::from_frontmatter(
            &Frontmatter {
                model: Some("fake-model".into()),
                base_url: Some("http://localhost".into()),
                api_key: Some("test".into()),
                timeout_seconds: Some(1),
                ..Frontmatter::default()
            },
            &RuntimeConfig::default().llm,
        )
        .unwrap();
        let item = WorkItem {
            source_abs: PathBuf::from("docs/guide.md"),
            source_path: "docs/guide.md".into(),
            output_abs: PathBuf::from("docs/i18n/es/guide.md"),
            output_path: "docs/i18n/es/guide.md".into(),
            locale: "es".into(),
            language: "Spanish".into(),
            source_language: "en".into(),
            format: Format::Markdown,
            frontmatter_mode: crate::config::FrontmatterMode::Preserve,
            preserve: Vec::new(),
            prompt: None,
            check_cmd: None,
            check_cmds: BTreeMap::new(),
            validation: None,
            validation_cwd: None,
            validation_doc_abs: None,
            retries: 1,
            llm,
            context_snapshots: vec![
                ContextSnapshot {
                    provider: "local_glossia".into(),
                    scope: "project_context".into(),
                    request_fingerprint: "a".into(),
                    snapshot_id: None,
                    metadata: BTreeMap::new(),
                    content: "Project".into(),
                    entries: Vec::new(),
                },
                ContextSnapshot {
                    provider: "local_glossia".into(),
                    scope: "locale_override".into(),
                    request_fingerprint: "b".into(),
                    snapshot_id: None,
                    metadata: BTreeMap::new(),
                    content: "Locale".into(),
                    entries: Vec::new(),
                },
            ],
        };

        assert_eq!(item.context_body(), "Project");
        assert_eq!(item.locale_override_body(), "Locale");
    }
}
