use anyhow::Result;
use std::path::{Path, PathBuf};

pub fn find_root(start: &Path) -> Result<PathBuf> {
    let mut current = start.canonicalize().unwrap_or_else(|_| start.to_path_buf());
    loop {
        if current.join(".git").exists() {
            return Ok(current);
        }

        let Some(parent) = current.parent() else {
            return std::fs::canonicalize(start).or_else(|_| Ok(start.to_path_buf()));
        };

        if parent == current {
            return std::fs::canonicalize(start).or_else(|_| Ok(start.to_path_buf()));
        }

        current = parent.to_path_buf();
    }
}

pub fn resolve_base_dir(cwd: &Path, override_path: Option<&str>) -> Result<PathBuf> {
    let Some(raw_path) = override_path else {
        return Ok(cwd.to_path_buf());
    };

    let raw_path = raw_path.trim();
    if raw_path.is_empty() {
        return Ok(cwd.to_path_buf());
    }

    let candidate = if Path::new(raw_path).is_absolute() {
        PathBuf::from(raw_path)
    } else {
        cwd.join(raw_path)
    };

    match std::fs::metadata(&candidate) {
        Ok(metadata) if metadata.is_dir() => Ok(candidate),
        Ok(_) => Ok(candidate.parent().unwrap_or(cwd).to_path_buf()),
        Err(_) => Ok(candidate),
    }
}
