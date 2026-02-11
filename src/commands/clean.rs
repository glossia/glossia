use anyhow::{Result, bail};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use tokio::fs;
use walkdir::WalkDir;

use crate::locks::{LockFile, lock_path};
use crate::plan::{SourcePlan, build_plan};
use crate::reporter::{Reporter, Verb};

pub struct CleanOptions<'a> {
    pub dry_run: bool,
    pub orphans: bool,
    pub reporter: &'a dyn Reporter,
}

pub async fn clean_cmd(root: &str, opts: &CleanOptions<'_>) -> Result<()> {
    let pl = build_plan(root).await?;
    if pl.sources.is_empty() {
        bail!("no sources found");
    }

    let root_abs = std::fs::canonicalize(root).unwrap_or_else(|_| PathBuf::from(root));
    let root_abs_str = root_abs.to_string_lossy().to_string();

    let mut planned: HashMap<String, &SourcePlan> = HashMap::new();
    for source in &pl.sources {
        planned.insert(source.source_path.clone(), source);
    }

    let mut removed = 0usize;
    let mut missing_count = 0usize;
    let mut lock_removed = 0usize;

    for source in &pl.sources {
        for output in &source.outputs {
            let abs = resolve_within_root(&root_abs_str, &output.output_path)?;
            match remove_path(&abs, opts.dry_run).await {
                RemoveResult::Removed => {
                    removed += 1;
                    opts.reporter.log(Verb::Removed, &output.output_path);
                }
                RemoveResult::Missing => {
                    missing_count += 1;
                    opts.reporter.log(
                        Verb::Skipped,
                        &format!("{} (not found)", output.output_path),
                    );
                }
                RemoveResult::Skipped => {}
            }
        }
        let lp = lock_path(root, &source.source_path);
        let lp_str = lp.to_string_lossy().to_string();
        match remove_path(&lp_str, opts.dry_run).await {
            RemoveResult::Removed => {
                lock_removed += 1;
                opts.reporter.log(Verb::Removed, &lp_str);
            }
            RemoveResult::Missing => {
                missing_count += 1;
                opts.reporter
                    .log(Verb::Skipped, &format!("{} (not found)", lp_str));
            }
            RemoveResult::Skipped => {}
        }
    }

    if opts.orphans {
        let lock_dir = Path::new(root).join(".l10n").join("locks");
        if lock_dir.exists() {
            for entry in WalkDir::new(&lock_dir).into_iter().filter_map(|e| e.ok()) {
                if !entry.file_type().is_file() {
                    continue;
                }
                let path = entry.path();
                if path.extension().and_then(|e| e.to_str()) != Some("lock") {
                    continue;
                }

                let lock: LockFile = match fs::read_to_string(path).await {
                    Ok(data) => match serde_json::from_str(&data) {
                        Ok(l) => l,
                        Err(_) => continue,
                    },
                    Err(_) => continue,
                };

                let mut source_path = lock.source_path.trim().to_string();
                if source_path.is_empty() {
                    source_path = source_path_from_lock(&root_abs_str, &path.to_string_lossy());
                }
                if planned.contains_key(&source_path) {
                    continue;
                }

                for output in lock.outputs.values() {
                    let abs = match resolve_within_root(&root_abs_str, &output.path) {
                        Ok(a) => a,
                        Err(_) => continue,
                    };
                    match remove_path(&abs, opts.dry_run).await {
                        RemoveResult::Removed => {
                            removed += 1;
                            opts.reporter.log(Verb::Removed, &output.path);
                        }
                        RemoveResult::Missing => {
                            missing_count += 1;
                            opts.reporter
                                .log(Verb::Skipped, &format!("{} (not found)", output.path));
                        }
                        RemoveResult::Skipped => {}
                    }
                }

                let path_str = path.to_string_lossy().to_string();
                match remove_path(&path_str, opts.dry_run).await {
                    RemoveResult::Removed => {
                        lock_removed += 1;
                        opts.reporter.log(Verb::Removed, &path_str);
                    }
                    RemoveResult::Missing => {
                        missing_count += 1;
                        opts.reporter
                            .log(Verb::Skipped, &format!("{} (not found)", path_str));
                    }
                    RemoveResult::Skipped => {}
                }
            }
        }
    }

    opts.reporter.log(
        Verb::Cleaned,
        &format!(
            "{} files removed, {} not found, {} lockfiles removed",
            removed, missing_count, lock_removed
        ),
    );

    Ok(())
}

fn resolve_within_root(root_abs: &str, rel: &str) -> Result<String> {
    if rel.trim().is_empty() {
        bail!("empty path");
    }
    let rel_path = Path::new(rel);
    if rel_path.is_absolute() {
        bail!("refusing to remove absolute path \"{}\"", rel);
    }
    let abs = Path::new(root_abs).join(rel);
    let abs_str = abs.to_string_lossy().to_string();
    let root_prefix = if root_abs.ends_with('/') || root_abs.ends_with('\\') {
        root_abs.to_string()
    } else {
        format!("{}/", root_abs)
    };
    let root_prefix_backslash = root_prefix.replace('/', "\\");

    if abs_str != root_abs
        && !abs_str.starts_with(&root_prefix)
        && !abs_str.starts_with(&root_prefix_backslash)
    {
        bail!("refusing to remove path outside root: {}", rel);
    }
    Ok(abs_str)
}

enum RemoveResult {
    Removed,
    Missing,
    Skipped,
}

async fn remove_path(path: &str, dry_run: bool) -> RemoveResult {
    if dry_run {
        return RemoveResult::Skipped;
    }
    match fs::remove_file(path).await {
        Ok(()) => RemoveResult::Removed,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => RemoveResult::Missing,
        Err(_) => RemoveResult::Missing,
    }
}

fn source_path_from_lock(root_abs: &str, lock_file_path: &str) -> String {
    let base = format!("{}/.l10n/locks/", root_abs.trim_end_matches('/'));
    let base_backslash = base.replace('/', "\\");

    let rel = if lock_file_path.starts_with(&base) {
        &lock_file_path[base.len()..]
    } else if lock_file_path.starts_with(&base_backslash) {
        &lock_file_path[base_backslash.len()..]
    } else {
        lock_file_path
    };

    rel.trim_end_matches(".lock").replace('\\', "/").to_string()
}
