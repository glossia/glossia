use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::path::Path;

use crate::config::{ContextFile, LocaleOverrideContext, ResolvedContext};
use crate::hash::{hash_json, hash_string};
use crate::pathing::relative_to_root;

const LOCAL_PROVIDER: &str = "local_glossia";

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ContextEntry {
    pub kind: String,
    pub stable_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub revision: Option<String>,
    pub content_hash: String,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub metadata: BTreeMap<String, String>,
}

impl ContextEntry {
    pub fn from_content(
        kind: impl Into<String>,
        stable_id: impl Into<String>,
        revision: Option<String>,
        content: &str,
        metadata: BTreeMap<String, String>,
    ) -> Self {
        Self {
            kind: kind.into(),
            stable_id: stable_id.into(),
            revision,
            content_hash: hash_string(content),
            metadata,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ContextSnapshot {
    pub provider: String,
    pub scope: String,
    pub request_fingerprint: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub snapshot_id: Option<String>,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub metadata: BTreeMap<String, String>,
    pub content: String,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub entries: Vec<ContextEntry>,
}

impl ContextSnapshot {
    pub fn content_hash(&self) -> String {
        hash_string(&self.content)
    }
}

#[derive(Debug, Serialize)]
struct RequestDescriptor<'a> {
    provider: &'a str,
    scope: &'a str,
    metadata: &'a BTreeMap<String, String>,
}

pub fn local_context_snapshot(
    translation_root: &Path,
    repo_root: &Path,
    resolved: &ResolvedContext,
) -> ContextSnapshot {
    build_local_snapshot(
        "project_context",
        "local_context_file",
        snapshot_metadata(translation_root, repo_root, None),
        &resolved.merged_body,
        &resolved.files,
    )
}

pub fn local_locale_override_snapshot(
    translation_root: &Path,
    repo_root: &Path,
    locale: &str,
    resolved: &LocaleOverrideContext,
) -> Option<ContextSnapshot> {
    if resolved.files.is_empty() && resolved.merged_body.trim().is_empty() {
        return None;
    }

    Some(build_local_snapshot(
        "locale_override",
        "locale_override_file",
        snapshot_metadata(translation_root, repo_root, Some(locale)),
        &resolved.merged_body,
        &resolved.files,
    ))
}

fn build_local_snapshot(
    scope: &str,
    entry_kind: &str,
    metadata: BTreeMap<String, String>,
    content: &str,
    files: &[ContextFile],
) -> ContextSnapshot {
    let entries = files
        .iter()
        .map(|file| {
            ContextEntry::from_content(
                entry_kind,
                file.relative_path.clone(),
                None,
                &file.raw_content,
                BTreeMap::new(),
            )
        })
        .collect::<Vec<_>>();

    ContextSnapshot {
        provider: LOCAL_PROVIDER.into(),
        scope: scope.into(),
        request_fingerprint: hash_json(&RequestDescriptor {
            provider: LOCAL_PROVIDER,
            scope,
            metadata: &metadata,
        }),
        snapshot_id: None,
        metadata,
        content: content.to_string(),
        entries,
    }
}

fn snapshot_metadata(
    translation_root: &Path,
    repo_root: &Path,
    locale: Option<&str>,
) -> BTreeMap<String, String> {
    let mut metadata = BTreeMap::new();
    metadata.insert(
        "translation_root".into(),
        relative_to_root(repo_root, translation_root),
    );
    if let Some(locale) = locale {
        metadata.insert("locale".into(), locale.to_string());
    }
    metadata
}

#[cfg(test)]
mod tests {
    use super::{
        local_context_snapshot, local_locale_override_snapshot, ContextEntry, ContextSnapshot,
    };
    use crate::config::{ContextFile, Frontmatter, LocaleOverrideContext, ResolvedContext};
    use std::collections::BTreeMap;
    use std::path::Path;

    #[test]
    fn entry_hashes_raw_content() {
        let entry = ContextEntry::from_content(
            "remote_context_entry",
            "style-guide",
            None,
            "A",
            BTreeMap::new(),
        );
        let changed = ContextEntry::from_content(
            "remote_context_entry",
            "style-guide",
            None,
            "B",
            BTreeMap::new(),
        );
        assert_ne!(entry.content_hash, changed.content_hash);
    }

    #[test]
    fn local_snapshot_uses_request_fingerprint_for_scope() {
        let file = ContextFile {
            relative_path: "docs/GLOSSIA.md".into(),
            raw_content: "---\nmodel: gpt-4.1\n---\nDocs".into(),
            body: "Docs".into(),
            frontmatter: Frontmatter::default(),
        };
        let resolved = ResolvedContext {
            merged_frontmatter: Frontmatter::default(),
            merged_body: "Docs".into(),
            files: vec![file.clone()],
            validation: None,
        };
        let override_ctx = LocaleOverrideContext {
            merged_body: "Spanish".into(),
            files: vec![file],
            model: None,
            validation: None,
        };

        let project = local_context_snapshot(Path::new("docs"), Path::new("."), &resolved);
        let locale =
            local_locale_override_snapshot(Path::new("docs"), Path::new("."), "es", &override_ctx)
                .unwrap();

        assert_ne!(project.request_fingerprint, locale.request_fingerprint);
    }

    #[test]
    fn content_hash_tracks_merged_prompt_context() {
        let snapshot = ContextSnapshot {
            provider: "remote".into(),
            scope: "project_context".into(),
            request_fingerprint: "fingerprint".into(),
            snapshot_id: None,
            metadata: BTreeMap::new(),
            content: "A".into(),
            entries: Vec::new(),
        };
        let changed = ContextSnapshot {
            content: "B".into(),
            ..snapshot.clone()
        };

        assert_ne!(snapshot.content_hash(), changed.content_hash());
    }
}
