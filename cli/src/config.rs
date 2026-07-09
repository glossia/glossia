mod spec;

use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use crate::pathing::{normalize_slashes, relative_to_root};
use spec::validate_document;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FrontmatterMode {
    Preserve,
    Translate,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct Frontmatter {
    pub locale: Option<String>,
    pub source_language: Option<String>,
    pub provider: Option<String>,
    pub model: Option<String>,
    pub base_url: Option<String>,
    pub chat_completions_path: Option<String>,
    pub api_key: Option<String>,
    pub api_key_env: Option<String>,
    pub temperature: Option<f64>,
    pub max_tokens: Option<u32>,
    pub timeout_seconds: Option<u64>,
    pub validation: Option<Vec<String>>,
    pub sources: Option<SourceSpec>,
    pub targets: Option<TargetSpec>,
    pub target_path: Option<String>,
    pub output: Option<String>,
    pub translate: Option<Vec<TranslateRule>>,
    pub exclude: Option<Vec<String>>,
    pub preserve: Option<Vec<String>>,
    pub frontmatter: Option<FrontmatterMode>,
    pub prompt: Option<String>,
    pub check_cmd: Option<String>,
    pub check_cmds: Option<BTreeMap<String, String>>,
    pub retries: Option<u32>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(untagged)]
pub enum TargetSpec {
    Map(BTreeMap<String, String>),
    List(Vec<String>),
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(untagged)]
pub enum SourceSpec {
    Map(BTreeMap<String, String>),
    List(Vec<String>),
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct TranslateRule {
    pub source: Option<String>,
    pub sources: Option<Vec<String>>,
    pub targets: Option<TargetSpec>,
    pub output: Option<String>,
    pub target_path: Option<String>,
    pub exclude: Option<Vec<String>>,
    pub preserve: Option<Vec<String>>,
    pub frontmatter: Option<FrontmatterMode>,
    pub prompt: Option<String>,
    pub check_cmd: Option<String>,
    pub check_cmds: Option<BTreeMap<String, String>>,
    pub retries: Option<u32>,
    pub validation: Option<Vec<String>>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ResolvedSourceMapping {
    pub pattern: String,
    pub target_template: Option<String>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ResolvedTranslateRule {
    pub sources: Vec<ResolvedSourceMapping>,
    pub targets: BTreeMap<String, String>,
    pub output: Option<String>,
    pub target_path: Option<String>,
    pub exclude: Vec<String>,
    pub preserve: Vec<String>,
    pub frontmatter: FrontmatterMode,
    pub prompt: Option<String>,
    pub check_cmd: Option<String>,
    pub check_cmds: BTreeMap<String, String>,
    pub retries: usize,
    pub validation: Option<Vec<String>>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DeclaredValidation {
    pub argv: Vec<String>,
    pub relative_path: String,
}

impl Frontmatter {
    pub fn merge(&mut self, other: &Self) {
        macro_rules! override_if_some {
            ($field:ident) => {
                if other.$field.is_some() {
                    self.$field = other.$field.clone();
                }
            };
        }

        override_if_some!(source_language);
        override_if_some!(provider);
        override_if_some!(model);
        override_if_some!(base_url);
        override_if_some!(chat_completions_path);
        override_if_some!(api_key);
        override_if_some!(api_key_env);
        override_if_some!(temperature);
        override_if_some!(max_tokens);
        override_if_some!(timeout_seconds);
        override_if_some!(validation);
        override_if_some!(sources);
        override_if_some!(targets);
        override_if_some!(target_path);
        override_if_some!(output);
        override_if_some!(translate);
        override_if_some!(exclude);
        override_if_some!(preserve);
        override_if_some!(frontmatter);
        override_if_some!(prompt);
        override_if_some!(check_cmd);
        override_if_some!(check_cmds);
        override_if_some!(retries);
    }

    pub fn has_sources(&self) -> bool {
        self.sources
            .as_ref()
            .map(SourceSpec::is_empty)
            .map(|is_empty| !is_empty)
            .unwrap_or(false)
    }

    pub fn has_translation_rules(&self) -> bool {
        self.translate
            .as_ref()
            .map(|rules| !rules.is_empty())
            .unwrap_or(false)
    }

    pub fn source_language(&self) -> &str {
        self.source_language.as_deref().unwrap_or("en")
    }

    pub fn frontmatter_mode(&self) -> FrontmatterMode {
        self.frontmatter.unwrap_or(FrontmatterMode::Preserve)
    }

    pub fn preserve(&self) -> Vec<String> {
        self.preserve.clone().unwrap_or_default()
    }

    pub fn exclude(&self) -> Vec<String> {
        self.exclude.clone().unwrap_or_default()
    }

    pub fn check_cmds(&self) -> BTreeMap<String, String> {
        self.check_cmds.clone().unwrap_or_default()
    }

    pub fn targets(&self) -> BTreeMap<String, String> {
        self.targets
            .as_ref()
            .map(TargetSpec::as_map)
            .unwrap_or_default()
    }

    fn validation_command(&self) -> Result<Option<Vec<String>>> {
        validate_command_argv(self.validation.clone())
    }

    pub fn translation_rules(&self) -> Result<Vec<ResolvedTranslateRule>> {
        if let Some(rules) = &self.translate {
            let mut resolved = Vec::new();
            for rule in rules {
                resolved.push(self.resolve_rule(rule)?);
            }
            return Ok(resolved);
        }

        let sources = self
            .sources
            .clone()
            .map(SourceSpec::into_mappings)
            .unwrap_or_default();
        if sources.is_empty() {
            return Ok(Vec::new());
        }

        let targets = self.targets();
        if targets.is_empty() {
            return Err(anyhow!(
                "frontmatter targets are required when sources are configured"
            ));
        }

        Ok(vec![ResolvedTranslateRule {
            sources,
            targets,
            output: self.output.clone(),
            target_path: self.target_path.clone(),
            exclude: self.exclude(),
            preserve: self.preserve(),
            frontmatter: self.frontmatter_mode(),
            prompt: self.prompt.clone(),
            check_cmd: self.check_cmd.clone(),
            check_cmds: self.check_cmds(),
            retries: self.retries.unwrap_or(2) as usize,
            validation: self.validation_command()?,
        }])
    }

    fn resolve_rule(&self, rule: &TranslateRule) -> Result<ResolvedTranslateRule> {
        let mut patterns = rule.sources.clone().unwrap_or_default();
        if let Some(source) = &rule.source {
            patterns.push(source.clone());
        }
        if patterns.is_empty() {
            return Err(anyhow!("translate rule requires source or sources"));
        }
        let sources = patterns
            .into_iter()
            .map(|pattern| ResolvedSourceMapping {
                pattern,
                target_template: None,
            })
            .collect::<Vec<_>>();

        let targets = rule
            .targets
            .as_ref()
            .map(TargetSpec::as_map)
            .or_else(|| self.targets.as_ref().map(TargetSpec::as_map))
            .unwrap_or_default();
        if targets.is_empty() {
            return Err(anyhow!("translate rule requires targets"));
        }

        Ok(ResolvedTranslateRule {
            sources,
            targets,
            output: rule.output.clone().or_else(|| self.output.clone()),
            target_path: rule
                .target_path
                .clone()
                .or_else(|| self.target_path.clone()),
            exclude: rule
                .exclude
                .clone()
                .or_else(|| self.exclude.clone())
                .unwrap_or_default(),
            preserve: rule
                .preserve
                .clone()
                .or_else(|| self.preserve.clone())
                .unwrap_or_default(),
            frontmatter: rule.frontmatter.unwrap_or(self.frontmatter_mode()),
            prompt: rule.prompt.clone().or_else(|| self.prompt.clone()),
            check_cmd: rule.check_cmd.clone().or_else(|| self.check_cmd.clone()),
            check_cmds: rule
                .check_cmds
                .clone()
                .or_else(|| self.check_cmds.clone())
                .unwrap_or_default(),
            retries: rule.retries.or(self.retries).unwrap_or(2) as usize,
            validation: validate_command_argv(
                rule.validation.clone().or_else(|| self.validation.clone()),
            )?,
        })
    }
}

impl TargetSpec {
    fn as_map(&self) -> BTreeMap<String, String> {
        match self {
            Self::Map(values) => values.clone(),
            Self::List(values) => values
                .iter()
                .map(|value| (value.clone(), value.clone()))
                .collect(),
        }
    }
}

impl SourceSpec {
    fn is_empty(&self) -> bool {
        match self {
            Self::Map(values) => values.is_empty(),
            Self::List(values) => values.is_empty(),
        }
    }

    fn into_mappings(self) -> Vec<ResolvedSourceMapping> {
        match self {
            Self::Map(values) => values
                .into_iter()
                .map(|(pattern, target_template)| ResolvedSourceMapping {
                    pattern,
                    target_template: Some(target_template),
                })
                .collect(),
            Self::List(values) => values
                .into_iter()
                .map(|pattern| ResolvedSourceMapping {
                    pattern,
                    target_template: None,
                })
                .collect(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct ContextFile {
    pub relative_path: String,
    pub raw_content: String,
    pub body: String,
    pub frontmatter: Frontmatter,
}

#[derive(Debug, Clone)]
pub struct ResolvedContext {
    pub merged_frontmatter: Frontmatter,
    pub merged_body: String,
    pub files: Vec<ContextFile>,
    pub validation: Option<DeclaredValidation>,
}

#[derive(Debug, Clone)]
pub struct LocaleOverrideContext {
    pub merged_body: String,
    pub files: Vec<ContextFile>,
    pub model: Option<String>,
    pub validation: Option<DeclaredValidation>,
}

#[derive(Debug, Clone)]
pub struct ParsedContent {
    pub frontmatter: Frontmatter,
    pub body: String,
}

pub fn parse_glossia_document(path: &Path, repo_root: &Path) -> Result<ContextFile> {
    let raw = fs::read_to_string(path)?;
    let parsed = parse_content(&raw)?;
    let relative_path = relative_to_root(repo_root, path);
    validate_document(&relative_path, &parsed.frontmatter)?;
    Ok(ContextFile {
        relative_path,
        raw_content: raw,
        body: parsed.body,
        frontmatter: parsed.frontmatter,
    })
}

pub fn parse_content(content: &str) -> Result<ParsedContent> {
    let lines: Vec<&str> = content.lines().collect();
    let Some(first) = lines.first().copied() else {
        return Ok(ParsedContent {
            frontmatter: Frontmatter::default(),
            body: String::new(),
        });
    };

    let marker = first.trim();
    if marker != "---" && marker != "+++" {
        return Ok(ParsedContent {
            frontmatter: Frontmatter::default(),
            body: content.trim().to_string(),
        });
    }

    let mut end = None;
    for (index, line) in lines.iter().enumerate().skip(1) {
        if line.trim() == marker {
            end = Some(index);
            break;
        }
    }

    let Some(end) = end else {
        return Err(anyhow!("frontmatter start found but no closing {marker}"));
    };

    let frontmatter_raw = lines[1..end].join("\n");
    let body = lines[end + 1..].join("\n").trim().to_string();
    let frontmatter = if marker == "---" {
        serde_yaml::from_str::<Frontmatter>(&frontmatter_raw)?
    } else {
        toml::from_str::<Frontmatter>(&frontmatter_raw)?
    };

    Ok(ParsedContent { frontmatter, body })
}

pub fn resolve_chain(start_dir: &Path, repo_root: &Path) -> Result<ResolvedContext> {
    let mut files = Vec::new();
    for dir in directories_up_to(start_dir, repo_root)? {
        let path = dir.join("GLOSSIA.md");
        if !path.exists() {
            continue;
        }
        files.push(parse_glossia_document(&path, repo_root)?);
    }

    let mut merged_frontmatter = Frontmatter::default();
    let mut bodies = Vec::new();
    let mut validation = None;

    for file in &files {
        merged_frontmatter.merge(&file.frontmatter);
        if !file.body.trim().is_empty() {
            bodies.push(file.body.clone());
        }
        if let Some(argv) = validate_command_argv(file.frontmatter.validation.clone())? {
            validation = Some(DeclaredValidation {
                argv,
                relative_path: file.relative_path.clone(),
            });
        }
    }

    Ok(ResolvedContext {
        merged_frontmatter,
        merged_body: bodies.join("\n\n"),
        files,
        validation,
    })
}

pub fn load_locale_override(
    start_dir: &Path,
    repo_root: &Path,
    locale: &str,
) -> Result<LocaleOverrideContext> {
    if locale.contains('/') || locale.contains('\\') {
        return Err(anyhow!("invalid locale {locale:?}"));
    }

    let mut files = Vec::new();
    let mut model = None;
    let mut validation = None;
    for dir in directories_up_to(start_dir, repo_root)? {
        let path = dir.join("GLOSSIA").join(format!("{locale}.md"));
        if !path.exists() {
            continue;
        }
        let file = parse_glossia_document(&path, repo_root)?;
        if let Some(declared_locale) = file.frontmatter.locale.as_deref() {
            if declared_locale != locale {
                return Err(anyhow!(
                    "locale overlay {} declares locale {}, expected {}",
                    file.relative_path,
                    declared_locale,
                    locale
                ));
            }
        }
        if let Some(argv) = validate_command_argv(file.frontmatter.validation.clone())? {
            validation = Some(DeclaredValidation {
                argv,
                relative_path: file.relative_path.clone(),
            });
        }
        if let Some(override_model) = file.frontmatter.model.clone() {
            model = Some(override_model);
        }
        files.push(file);
    }

    let merged_body = files
        .iter()
        .map(|file| file.body.trim())
        .filter(|body| !body.is_empty())
        .collect::<Vec<_>>()
        .join("\n\n");

    Ok(LocaleOverrideContext {
        merged_body,
        files,
        model,
        validation,
    })
}

pub fn find_translation_roots(repo_root: &Path) -> Result<Vec<PathBuf>> {
    let mut roots = Vec::new();
    for entry in walkdir::WalkDir::new(repo_root)
        .into_iter()
        .filter_entry(|entry| entry.file_name() != ".git")
    {
        let entry = entry?;
        if !entry.file_type().is_file() || entry.file_name() != "GLOSSIA.md" {
            continue;
        }

        let parsed = parse_glossia_document(entry.path(), repo_root)?;
        if parsed.frontmatter.has_sources() || parsed.frontmatter.has_translation_rules() {
            roots.push(entry.path().parent().unwrap_or(repo_root).to_path_buf());
        }
    }

    roots.sort_by(|left, right| {
        normalize_slashes(left.to_string_lossy()).cmp(&normalize_slashes(right.to_string_lossy()))
    });
    Ok(roots)
}

fn directories_up_to(start_dir: &Path, repo_root: &Path) -> Result<Vec<PathBuf>> {
    let start_dir = start_dir
        .canonicalize()
        .unwrap_or_else(|_| start_dir.to_path_buf());
    let repo_root = repo_root
        .canonicalize()
        .unwrap_or_else(|_| repo_root.to_path_buf());
    let mut dirs = Vec::new();
    let mut current = start_dir.as_path();

    loop {
        dirs.push(current.to_path_buf());
        if current == repo_root {
            break;
        }
        let Some(parent) = current.parent() else {
            break;
        };
        if parent == current {
            break;
        }
        current = parent;
    }

    dirs.reverse();
    Ok(dirs)
}

fn validate_command_argv(command: Option<Vec<String>>) -> Result<Option<Vec<String>>> {
    let Some(command) = command else {
        return Ok(None);
    };
    if command.is_empty() {
        return Err(anyhow!("validation must contain at least one argument"));
    }
    if command.iter().any(|arg| arg.trim().is_empty()) {
        return Err(anyhow!("validation arguments must be non-empty"));
    }
    Ok(Some(command))
}

#[cfg(test)]
mod tests {
    use super::{
        find_translation_roots, parse_content, resolve_chain, FrontmatterMode, SourceSpec,
    };
    use pretty_assertions::assert_eq;
    use std::fs;

    #[test]
    fn parse_yaml_frontmatter() {
        let parsed = parse_content(
            r#"---
model: openai/gpt-5
sources:
  "docs/*.md": "docs/i18n/{locale}/*.md"
---
Hello
"#,
        )
        .unwrap();

        assert_eq!(parsed.frontmatter.model.as_deref(), Some("openai/gpt-5"));
        assert!(matches!(
            parsed.frontmatter.sources,
            Some(SourceSpec::Map(_))
        ));
        assert_eq!(parsed.body, "Hello");
    }

    #[test]
    fn resolves_generic_translate_rules() {
        let parsed = parse_content(
            r#"---
model: openai/gpt-5
targets:
  es: Spanish
translate:
  - source: docs/**/*.md
    output: docs/i18n/{locale}/{relpath}
---
Hello
"#,
        )
        .unwrap();

        let rules = parsed.frontmatter.translation_rules().unwrap();
        assert_eq!(rules.len(), 1);
        assert_eq!(rules[0].sources[0].pattern, "docs/**/*.md");
        assert_eq!(
            rules[0].targets.get("es").map(String::as_str),
            Some("Spanish")
        );
        assert_eq!(
            rules[0].output.as_deref(),
            Some("docs/i18n/{locale}/{relpath}")
        );
    }

    #[test]
    fn resolves_inherited_model_identifier() {
        let root = tempfile::tempdir().unwrap();
        fs::write(
            root.path().join("GLOSSIA.md"),
            r#"---
source_language: en
model: openai/gpt-5
frontmatter: preserve
---
Global context
"#,
        )
        .unwrap();
        fs::create_dir_all(root.path().join("docs")).unwrap();
        fs::write(
            root.path().join("docs").join("GLOSSIA.md"),
            r#"---
model: openai/gpt-5-mini
sources:
  "*.md": "i18n/{locale}/*.md"
---
Docs context
"#,
        )
        .unwrap();

        let resolved = resolve_chain(&root.path().join("docs"), root.path()).unwrap();
        assert_eq!(
            resolved.merged_frontmatter.model.as_deref(),
            Some("openai/gpt-5-mini")
        );
        assert_eq!(
            resolved.merged_frontmatter.frontmatter,
            Some(FrontmatterMode::Preserve)
        );
        assert_eq!(resolved.merged_body, "Global context\n\nDocs context");
    }

    #[test]
    fn finds_only_files_with_local_sources() {
        let root = tempfile::tempdir().unwrap();
        fs::write(
            root.path().join("GLOSSIA.md"),
            "---\nsource_language: en\nmodel: openai/gpt-5\n---\nroot",
        )
        .unwrap();
        fs::create_dir_all(root.path().join("server")).unwrap();
        fs::write(
            root.path().join("server").join("GLOSSIA.md"),
            "---\nsources:\n  \"priv/gettext/*.pot\": \"priv/gettext/{locale}/LC_MESSAGES\"\n---\nserver",
        )
        .unwrap();

        let roots = find_translation_roots(root.path()).unwrap();
        assert_eq!(roots, vec![root.path().join("server")]);
    }

    #[test]
    fn resolves_effective_validation_from_deepest_scope() {
        let root = tempfile::tempdir().unwrap();
        fs::write(
            root.path().join("GLOSSIA.md"),
            "---\nsource_language: en\nvalidation:\n  - ./root-check.sh\n---\nroot",
        )
        .unwrap();
        fs::create_dir_all(root.path().join("docs")).unwrap();
        fs::write(
            root.path().join("docs").join("GLOSSIA.md"),
            "---\nvalidation:\n  - ./docs-check.sh\n---\ndocs",
        )
        .unwrap();

        let resolved = resolve_chain(&root.path().join("docs"), root.path()).unwrap();
        assert_eq!(
            resolved
                .validation
                .as_ref()
                .map(|value| value.relative_path.as_str()),
            Some("docs/GLOSSIA.md")
        );
        assert_eq!(
            resolved.validation.as_ref().map(|value| value.argv.clone()),
            Some(vec!["./docs-check.sh".into()])
        );
    }
}
