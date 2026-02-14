use anyhow::{Result, bail};
use globset::GlobBuilder;
use std::collections::HashMap;
use std::path::Path;
use walkdir::WalkDir;

use crate::config::{
    AgentConfig, Entry, ContentFile, LLMConfig, merge_llm, parse_file, resolve_agents,
    split_toml_frontmatter, validate_content_entry,
};
use crate::format::{Format, detect_format};
use crate::output::{OutputValues, expand_output};

#[derive(Debug, Clone)]
pub struct Plan {
    pub root: String,
    pub content_files: Vec<ContentFile>,
    pub sources: Vec<SourcePlan>,
}

#[derive(Debug, Clone)]
pub struct SourcePlan {
    pub source_path: String,
    pub abs_path: String,
    pub base_path: String,
    pub rel_path: String,
    pub format: Format,
    pub kind: EntryKind,
    pub entry: Entry,
    pub context_bodies: Vec<String>,
    pub lang_context_bodies: HashMap<String, Vec<String>>,
    pub context_paths: Vec<String>,
    pub llm: LLMPlan,
    pub outputs: Vec<OutputPlan>,
}

#[derive(Debug, Clone)]
pub struct LLMPlan {
    pub coordinator: AgentConfig,
    pub translator: AgentConfig,
}

#[derive(Debug, Clone)]
pub enum EntryKind {
    Translate,
    Revisit,
}

#[derive(Debug, Clone)]
pub struct OutputPlan {
    pub lang: Option<String>,
    pub output_path: String,
}

impl OutputPlan {
    pub fn lang_key(&self) -> &str {
        self.lang.as_deref().unwrap_or("_")
    }

    pub fn format_label(&self, source_path: &str) -> String {
        match &self.lang {
            Some(lang) => format!("{} -> {} ({})", source_path, self.output_path, lang),
            None => format!("{} -> {}", source_path, self.output_path),
        }
    }
}

pub fn context_parts_for(source: &SourcePlan, lang: &str) -> Vec<String> {
    let mut parts = source.context_bodies.clone();
    if let Some(lang_bodies) = source.lang_context_bodies.get(lang) {
        parts.extend(lang_bodies.clone());
    }
    parts
}

pub async fn build_plan(root: &str) -> Result<Plan> {
    let content_files = discover_content(root).await?;
    let entries = collect_entries(root, &content_files);
    let candidates = resolve_entries(root, &entries)?;

    let mut sources = Vec::new();

    for (src_path, cand) in &candidates {
        let abs_path = Path::new(root).join(src_path);
        let context_files = ancestors_for(&abs_path.to_string_lossy(), &content_files);
        let mut context_bodies = Vec::new();
        let mut context_paths = Vec::new();
        let mut lang_context_bodies: HashMap<String, Vec<String>> = HashMap::new();
        let mut llm_config = LLMConfig::default();

        let is_translate = !cand.entry.targets.is_empty();
        let kind = if is_translate {
            EntryKind::Translate
        } else {
            EntryKind::Revisit
        };

        for cf in &context_files {
            if !cf.body.trim().is_empty() {
                context_bodies.push(cf.body.clone());
                context_paths.push(cf.path.clone());
            }
            // Only look up per-language context for translate entries
            if is_translate {
                for lang in &cand.entry.targets {
                    let (body, ok) = read_lang_context(&cf.dir, lang).await?;
                    if ok && !body.trim().is_empty() {
                        lang_context_bodies
                            .entry(lang.clone())
                            .or_default()
                            .push(body);
                    }
                }
            }
            llm_config = merge_llm(&llm_config, &cf.config.llm);
        }

        let (coordinator, translator) = resolve_agents(&llm_config)?;
        let resolved_llm = LLMPlan {
            coordinator,
            translator,
        };

        let rel_path = relative_path(&cand.base_path, src_path);

        let ext = Path::new(src_path)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("");
        let stem = Path::new(src_path)
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("");

        let mut outputs = Vec::new();
        if is_translate {
            for lang in &cand.entry.targets {
                let out = expand_output(
                    &cand.entry.output,
                    &OutputValues {
                        lang: lang.clone(),
                        relpath: rel_path.clone(),
                        basename: stem.to_string(),
                        ext: ext.to_string(),
                    },
                );
                outputs.push(OutputPlan {
                    lang: Some(lang.clone()),
                    output_path: out,
                });
            }
        } else {
            // Revisit: single output, no lang
            let output_path = if cand.entry.output.trim().is_empty() {
                // No output specified: overwrite source in place
                src_path.clone()
            } else {
                expand_output(
                    &cand.entry.output,
                    &OutputValues {
                        lang: String::new(),
                        relpath: rel_path.clone(),
                        basename: stem.to_string(),
                        ext: ext.to_string(),
                    },
                )
            };
            outputs.push(OutputPlan {
                lang: None,
                output_path,
            });
        }

        sources.push(SourcePlan {
            source_path: src_path.clone(),
            abs_path: abs_path.to_string_lossy().to_string(),
            base_path: cand.base_path.clone(),
            rel_path,
            format: detect_format(src_path),
            kind,
            entry: cand.entry.clone(),
            context_bodies,
            lang_context_bodies,
            context_paths,
            llm: resolved_llm,
            outputs,
        });
    }

    sources.sort_by(|a, b| a.source_path.cmp(&b.source_path));

    Ok(Plan {
        root: root.to_string(),
        content_files,
        sources,
    })
}

// Internals

struct Candidate {
    entry: Entry,
    base_path: String,
}

fn resolve_entries(root: &str, entries: &[Entry]) -> Result<Vec<(String, Candidate)>> {
    let mut candidates: HashMap<String, Candidate> = HashMap::new();

    for entry in entries {
        let (pattern, base) = entry_pattern(root, entry);
        let matches = glob_files(root, &pattern)?;
        let excludes = resolve_excludes(root, entry)?;

        for mat in matches {
            if excludes.contains(&mat) {
                continue;
            }
            if Path::new(&mat).file_name().and_then(|n| n.to_str()) == Some("CONTENT.md") {
                continue;
            }

            let full = Path::new(root).join(&mat);
            if !full.exists() || full.is_dir() {
                continue;
            }

            if let Some(existing) = candidates.get(&mat) {
                if should_override(&existing.entry, entry) {
                    candidates.insert(
                        mat,
                        Candidate {
                            entry: entry.clone(),
                            base_path: base.clone(),
                        },
                    );
                }
            } else {
                candidates.insert(
                    mat,
                    Candidate {
                        entry: entry.clone(),
                        base_path: base.clone(),
                    },
                );
            }
        }
    }

    // Sort by key for deterministic order
    let mut result: Vec<(String, Candidate)> = candidates.into_iter().collect();
    result.sort_by(|a, b| a.0.cmp(&b.0));
    Ok(result)
}

fn entry_pattern(root: &str, entry: &Entry) -> (String, String) {
    let rel_dir = relative_path(root, &entry.origin_dir);
    let rel_dir = if rel_dir == "." {
        String::new()
    } else {
        rel_dir
    };

    let src = if entry.source.trim().is_empty() {
        entry.path.trim().to_string()
    } else {
        entry.source.trim().to_string()
    };

    let pattern = if rel_dir.is_empty() {
        src
    } else {
        format!("{}/{}", rel_dir, src)
    };
    let pattern = pattern.replace('\\', "/");

    let mut base = glob_base(&pattern);
    if base == "." {
        base = if rel_dir.is_empty() {
            ".".to_string()
        } else {
            rel_dir
        };
    }

    (pattern, base)
}

fn resolve_excludes(root: &str, entry: &Entry) -> Result<std::collections::HashSet<String>> {
    let mut excludes = std::collections::HashSet::new();
    if entry.exclude.is_empty() {
        return Ok(excludes);
    }

    let rel_dir = relative_path(root, &entry.origin_dir);
    let rel_dir = if rel_dir == "." {
        String::new()
    } else {
        rel_dir
    };

    for ex in &entry.exclude {
        let pattern = if rel_dir.is_empty() {
            ex.clone()
        } else {
            format!("{}/{}", rel_dir, ex)
        };
        let pattern = pattern.replace('\\', "/");
        let matches = glob_files(root, &pattern)?;
        for m in matches {
            excludes.insert(m);
        }
    }

    Ok(excludes)
}

fn should_override(existing: &Entry, candidate: &Entry) -> bool {
    if candidate.origin_depth > existing.origin_depth {
        return true;
    }
    if candidate.origin_depth == existing.origin_depth && candidate.index > existing.index {
        return true;
    }
    false
}

fn collect_entries(_root: &str, content_files: &[ContentFile]) -> Vec<Entry> {
    let mut entries = Vec::new();
    for file in content_files {
        for (idx, raw) in file.config.content.iter().enumerate() {
            if let Err(e) = validate_content_entry(raw) {
                eprintln!("warning: skipping invalid content entry: {}", e);
                continue;
            }
            entries.push(Entry {
                source: if raw.source.is_empty() {
                    raw.path.clone()
                } else {
                    raw.source.clone()
                },
                path: if raw.path.is_empty() {
                    raw.source.clone()
                } else {
                    raw.path.clone()
                },
                targets: raw.targets.clone(),
                output: raw.output.clone(),
                exclude: raw.exclude.clone(),
                preserve: raw.preserve.clone(),
                frontmatter: if raw.frontmatter.is_empty() && !raw.targets.is_empty() {
                    "preserve".to_string()
                } else {
                    raw.frontmatter.clone()
                },
                prompt: raw.prompt.clone(),
                check_cmd: raw.check_cmd.clone(),
                check_cmds: raw.check_cmds.clone(),
                retries: raw.retries,
                origin_path: file.path.clone(),
                origin_dir: file.dir.clone(),
                origin_depth: file.depth,
                index: idx,
            });
        }
    }
    entries
}

async fn discover_content(root: &str) -> Result<Vec<ContentFile>> {
    let mut files = Vec::new();

    for entry in WalkDir::new(root).into_iter().filter_map(|e| e.ok()) {
        if entry.file_name() == "CONTENT.md" && entry.file_type().is_file() {
            let path = entry.path().to_string_lossy().to_string();
            let mut parsed = parse_file(&path).await?;

            let rel_dir = relative_path(root, &parsed.dir);
            if rel_dir.is_empty() || rel_dir == "." {
                parsed.depth = 0;
            } else {
                parsed.depth = rel_dir.split('/').count();
            }

            files.push(parsed);
        }
    }

    files.sort_by_key(|f| f.depth);
    Ok(files)
}

fn ancestors_for(source_abs: &str, content_files: &[ContentFile]) -> Vec<ContentFile> {
    let mut ancestors: Vec<ContentFile> = content_files
        .iter()
        .filter(|f| is_ancestor(&f.dir, source_abs))
        .cloned()
        .collect();
    ancestors.sort_by_key(|f| f.depth);
    ancestors
}

fn is_ancestor(dir: &str, path: &str) -> bool {
    let dir_normalized = dir.replace('\\', "/");
    let path_normalized = path.replace('\\', "/");

    path_normalized == dir_normalized
        || path_normalized.starts_with(&format!("{}/", dir_normalized))
}

fn glob_base(pattern: &str) -> String {
    let idx = pattern.find(['*', '?', '[']);
    match idx {
        None => {
            let p = Path::new(pattern);
            p.parent()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_else(|| ".".to_string())
        }
        Some(i) => {
            let prefix = &pattern[..i];
            let p = Path::new(prefix);
            let dir = p
                .parent()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_else(|| ".".to_string());
            if dir.is_empty() { ".".to_string() } else { dir }
        }
    }
}

async fn read_lang_context(dir: &str, lang: &str) -> Result<(String, bool)> {
    let trimmed = lang.trim();
    if trimmed.is_empty() {
        bail!("empty language code");
    }
    if trimmed.contains('/') || trimmed.contains('\\') {
        bail!("invalid language code \"{}\"", lang);
    }
    let path = Path::new(dir).join("CONTENT").join(format!("{}.md", trimmed));
    match tokio::fs::read_to_string(&path).await {
        Ok(data) => {
            let split = split_toml_frontmatter(&data)?;
            if split.has_frontmatter {
                Ok((split.body, true))
            } else {
                Ok((data, true))
            }
        }
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok((String::new(), false)),
        Err(e) => Err(e.into()),
    }
}

fn glob_files(root: &str, pattern: &str) -> Result<Vec<String>> {
    let glob = GlobBuilder::new(pattern)
        .literal_separator(false)
        .build()?
        .compile_matcher();

    let mut results = Vec::new();
    for entry in WalkDir::new(root).into_iter().filter_map(|e| e.ok()) {
        if !entry.file_type().is_file() {
            continue;
        }
        let rel = relative_path(root, &entry.path().to_string_lossy());
        let rel = rel.replace('\\', "/");
        if glob.is_match(&rel) {
            results.push(rel);
        }
    }
    Ok(results)
}

fn relative_path(base: &str, path: &str) -> String {
    let base_normalized = base.replace('\\', "/");
    let path_normalized = path.replace('\\', "/");

    if path_normalized == base_normalized {
        return ".".to_string();
    }

    let base_prefix = if base_normalized.ends_with('/') {
        base_normalized.clone()
    } else {
        format!("{}/", base_normalized)
    };

    if path_normalized.starts_with(&base_prefix) {
        return path_normalized[base_prefix.len()..].to_string();
    }

    // Use pathdiff as fallback
    pathdiff::diff_paths(&path_normalized, &base_normalized)
        .map(|p| p.to_string_lossy().replace('\\', "/"))
        .unwrap_or_else(|| path_normalized)
}
