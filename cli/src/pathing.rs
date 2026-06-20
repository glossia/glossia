use anyhow::Result;
use std::path::Path;

pub fn normalize_slashes(input: impl AsRef<str>) -> String {
    input.as_ref().replace('\\', "/")
}

pub fn relative_path(base: &Path, target: &Path) -> Result<String> {
    let rel = target
        .strip_prefix(base)
        .map(|path| normalize_slashes(path.to_string_lossy()))
        .or_else(|_| {
            let canonical_base = base.canonicalize()?;
            let canonical_target = target.canonicalize()?;
            canonical_target
                .strip_prefix(&canonical_base)
                .map(|path| normalize_slashes(path.to_string_lossy()))
                .map_err(anyhow::Error::from)
        })
        .unwrap_or_else(|_| normalize_slashes(target.to_string_lossy()));
    Ok(if rel.is_empty() || rel == "." {
        ".".into()
    } else {
        rel
    })
}

pub fn relative_to_root(root: &Path, path: &Path) -> String {
    relative_path(root, path).unwrap_or_else(|_| normalize_slashes(path.to_string_lossy()))
}
