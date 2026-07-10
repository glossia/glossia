use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use crate::context::{ContextEntry, ContextSnapshot};
use crate::format::Format;
use crate::hash::{hash_json, hash_string};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HashNode {
    pub kind: String,
    pub label: String,
    pub hash: String,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub metadata: BTreeMap<String, String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub children: Vec<HashNode>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HashTree {
    pub root: HashNode,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HashState {
    pub hash: String,
    pub source_hash: String,
    pub tree: HashTree,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LockFile {
    pub hash: String,
    pub provider: String,
    pub model: String,
    pub source_path: String,
    pub output_path: String,
    pub output_hash: String,
    pub translated_at: String,
    pub hash_tree: HashTree,
}

#[derive(Debug, Serialize)]
struct NodeDescriptor<'a> {
    kind: &'a str,
    label: &'a str,
    metadata: &'a BTreeMap<String, String>,
    child_hashes: Vec<&'a str>,
}

pub fn lock_path(root: &Path, source_path: &str, locale: &str) -> PathBuf {
    root.join(".glossia")
        .join(source_path)
        .join(format!("{locale}.lock"))
}

// Legacy location used before the .l10n -> .glossia rename. Read as a fallback so
// repositories translated before the rename are not treated as fully stale.
fn legacy_lock_path(root: &Path, source_path: &str, locale: &str) -> PathBuf {
    root.join(".l10n")
        .join(source_path)
        .join(format!("{locale}.lock"))
}

pub fn read_lock(root: &Path, source_path: &str, locale: &str) -> Result<Option<LockFile>> {
    let path = lock_path(root, source_path, locale);
    let path = if path.exists() {
        path
    } else {
        legacy_lock_path(root, source_path, locale)
    };
    if !path.exists() {
        return Ok(None);
    }
    let raw = fs::read_to_string(path)?;
    Ok(serde_json::from_str(&raw).ok())
}

pub fn stale(
    lock: Option<&LockFile>,
    current_hash: &str,
    output_path: &str,
    output_hash: &str,
) -> bool {
    let Some(lock) = lock else {
        return true;
    };
    lock.hash != current_hash || lock.output_path != output_path || lock.output_hash != output_hash
}

pub fn build_hash_state(
    format: Format,
    source_path: &str,
    source_content: &str,
    provider: &str,
    model: &str,
    context_snapshots: &[ContextSnapshot],
) -> HashState {
    let source_hash = source_hash(format, source_content);
    let source_node = build_node(
        "source",
        source_path,
        BTreeMap::from([("content_hash".into(), source_hash.clone())]),
        Vec::new(),
    );

    let config_node = build_node(
        "translation_config",
        "llm",
        BTreeMap::from([
            ("provider".into(), provider.to_string()),
            ("model".into(), model.to_string()),
        ]),
        Vec::new(),
    );

    let mut children = vec![source_node, config_node];
    let mut ordered_snapshots = context_snapshots.to_vec();
    ordered_snapshots.sort_by_key(snapshot_sort_key);
    let context_nodes = ordered_snapshots
        .iter()
        .map(snapshot_node)
        .collect::<Vec<_>>();
    if !context_nodes.is_empty() {
        children.push(build_node(
            "context_bundle",
            "context",
            BTreeMap::new(),
            context_nodes,
        ));
    }

    let root = build_node("translation_input", source_path, BTreeMap::new(), children);
    let hash = root.hash.clone();

    HashState {
        hash,
        source_hash,
        tree: HashTree { root },
    }
}

pub fn source_hash(format: Format, source_content: &str) -> String {
    if format == Format::PO {
        return hash_string(&normalized_po_source(source_content));
    }
    hash_string(source_content)
}

fn snapshot_node(snapshot: &ContextSnapshot) -> HashNode {
    let mut metadata = snapshot.metadata.clone();
    metadata.insert("provider".into(), snapshot.provider.clone());
    metadata.insert(
        "request_fingerprint".into(),
        snapshot.request_fingerprint.clone(),
    );
    metadata.insert("content_hash".into(), snapshot.content_hash());
    if let Some(snapshot_id) = &snapshot.snapshot_id {
        metadata.insert("snapshot_id".into(), snapshot_id.clone());
    }

    let mut entries = snapshot.entries.clone();
    entries.sort_by_key(entry_sort_key);
    let children = entries.iter().map(context_entry_node).collect::<Vec<_>>();

    build_node("context_snapshot", &snapshot.scope, metadata, children)
}

fn context_entry_node(entry: &ContextEntry) -> HashNode {
    let mut metadata = entry.metadata.clone();
    metadata.insert("stable_id".into(), entry.stable_id.clone());
    metadata.insert("content_hash".into(), entry.content_hash.clone());
    if let Some(revision) = &entry.revision {
        metadata.insert("revision".into(), revision.clone());
    }

    build_node(&entry.kind, &entry.stable_id, metadata, Vec::new())
}

fn build_node(
    kind: impl Into<String>,
    label: impl Into<String>,
    metadata: BTreeMap<String, String>,
    children: Vec<HashNode>,
) -> HashNode {
    let kind = kind.into();
    let label = label.into();
    let descriptor = NodeDescriptor {
        kind: &kind,
        label: &label,
        metadata: &metadata,
        child_hashes: children.iter().map(|child| child.hash.as_str()).collect(),
    };
    let hash = hash_json(&descriptor);

    HashNode {
        kind,
        label,
        hash,
        metadata,
        children,
    }
}

fn snapshot_sort_key(snapshot: &ContextSnapshot) -> (String, String, String, String) {
    (
        snapshot.scope.clone(),
        snapshot.provider.clone(),
        snapshot.snapshot_id.clone().unwrap_or_default(),
        snapshot.request_fingerprint.clone(),
    )
}

fn entry_sort_key(entry: &ContextEntry) -> (String, String, String, String) {
    (
        entry.kind.clone(),
        entry.stable_id.clone(),
        entry.revision.clone().unwrap_or_default(),
        entry.content_hash.clone(),
    )
}

fn normalized_po_source(content: &str) -> String {
    let mut normalized = Vec::new();
    let mut lines = content.lines().peekable();

    while let Some(line) = lines.next() {
        if let Some(reference) = line.strip_prefix("#: ") {
            let mut references = reference
                .split_whitespace()
                .map(normalize_reference)
                .collect::<Vec<_>>();

            while let Some(next) = lines.peek() {
                let Some(reference) = next.strip_prefix("#: ") else {
                    break;
                };
                references.extend(reference.split_whitespace().map(normalize_reference));
                let _ = lines.next();
            }

            references.sort();
            references.dedup();
            normalized.push(format!("#: {}", references.join(" ")));
            continue;
        }

        normalized.push(line.to_string());
    }

    normalized.join("\n")
}

fn normalize_reference(reference: &str) -> String {
    let mut parts = reference.rsplitn(2, ':');
    let last = parts.next().unwrap_or_default();
    let rest = parts.next();
    if last.chars().all(|ch| ch.is_ascii_digit()) {
        rest.unwrap_or(reference).to_string()
    } else {
        reference.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::{build_hash_state, source_hash};
    use crate::context::{ContextEntry, ContextSnapshot};
    use crate::format::Format;
    use std::collections::BTreeMap;

    #[test]
    fn po_source_hash_ignores_line_number_churn() {
        let left = "#: lib/app.ex:10\nmsgid \"Hello\"\nmsgstr \"\"";
        let right = "#: lib/app.ex:99\nmsgid \"Hello\"\nmsgstr \"\"";
        assert_eq!(
            source_hash(Format::PO, left),
            source_hash(Format::PO, right)
        );
    }

    #[test]
    fn snapshot_request_fingerprint_participates_in_root_hash() {
        let entry = ContextEntry {
            kind: "remote_context_entry".into(),
            stable_id: "glossary:button".into(),
            revision: None,
            content_hash: "same-content".into(),
            metadata: BTreeMap::new(),
        };
        let first = ContextSnapshot {
            provider: "glossia".into(),
            scope: "project_context".into(),
            request_fingerprint: "first".into(),
            snapshot_id: Some("snapshot-1".into()),
            metadata: BTreeMap::new(),
            content: "Context".into(),
            entries: vec![entry.clone()],
        };
        let second = ContextSnapshot {
            request_fingerprint: "second".into(),
            ..first.clone()
        };

        let first_hash = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[first],
        )
        .hash;
        let second_hash = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[second],
        )
        .hash;

        assert_ne!(first_hash, second_hash);
    }

    #[test]
    fn snapshot_content_hash_participates_in_root_hash() {
        let base = ContextSnapshot {
            provider: "glossia".into(),
            scope: "project_context".into(),
            request_fingerprint: "same".into(),
            snapshot_id: None,
            metadata: BTreeMap::new(),
            content: "A".into(),
            entries: Vec::new(),
        };
        let changed = ContextSnapshot {
            content: "B".into(),
            ..base.clone()
        };

        let left = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[base],
        )
        .hash;
        let right = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[changed],
        )
        .hash;

        assert_ne!(left, right);
    }

    #[test]
    fn snapshot_hash_is_stable_across_snapshot_order() {
        let first = ContextSnapshot {
            provider: "glossia".into(),
            scope: "project_context".into(),
            request_fingerprint: "one".into(),
            snapshot_id: Some("snapshot-a".into()),
            metadata: BTreeMap::new(),
            content: "A".into(),
            entries: Vec::new(),
        };
        let second = ContextSnapshot {
            provider: "glossia".into(),
            scope: "locale_override".into(),
            request_fingerprint: "two".into(),
            snapshot_id: Some("snapshot-b".into()),
            metadata: BTreeMap::new(),
            content: "B".into(),
            entries: Vec::new(),
        };

        let left = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[first.clone(), second.clone()],
        )
        .hash;
        let right = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[second, first],
        )
        .hash;

        assert_eq!(left, right);
    }

    #[test]
    fn snapshot_hash_is_stable_across_entry_order() {
        let first_entry = ContextEntry {
            kind: "remote_context_entry".into(),
            stable_id: "a".into(),
            revision: None,
            content_hash: "one".into(),
            metadata: BTreeMap::new(),
        };
        let second_entry = ContextEntry {
            kind: "remote_context_entry".into(),
            stable_id: "b".into(),
            revision: None,
            content_hash: "two".into(),
            metadata: BTreeMap::new(),
        };
        let left_snapshot = ContextSnapshot {
            provider: "glossia".into(),
            scope: "project_context".into(),
            request_fingerprint: "same".into(),
            snapshot_id: Some("snapshot".into()),
            metadata: BTreeMap::new(),
            content: "merged".into(),
            entries: vec![first_entry.clone(), second_entry.clone()],
        };
        let right_snapshot = ContextSnapshot {
            entries: vec![second_entry, first_entry],
            ..left_snapshot.clone()
        };

        let left = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[left_snapshot],
        )
        .hash;
        let right = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[right_snapshot],
        )
        .hash;

        assert_eq!(left, right);
    }

    #[test]
    fn model_participates_in_root_hash() {
        let left = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5",
            &[],
        )
        .hash;
        let right = build_hash_state(
            Format::Markdown,
            "docs/page.md",
            "Body",
            "openai",
            "gpt-5-mini",
            &[],
        )
        .hash;

        assert_ne!(left, right);
    }
}
