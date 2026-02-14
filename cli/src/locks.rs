use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use tokio::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutputLock {
    pub path: String,
    pub hash: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context_hash: Option<String>,
    pub checked_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LockFile {
    pub source_path: String,
    pub source_hash: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context_hash: Option<String>,
    pub outputs: HashMap<String, OutputLock>,
    pub updated_at: String,
}

impl LockFile {
    pub fn new(source_path: &str) -> Self {
        Self {
            source_path: source_path.to_string(),
            source_hash: String::new(),
            context_hash: None,
            outputs: HashMap::new(),
            updated_at: String::new(),
        }
    }
}

pub fn lock_path(root: &str, source_path: &str) -> PathBuf {
    Path::new(root)
        .join(".glossia")
        .join("locks")
        .join(format!("{}.lock", source_path))
}

pub async fn read_lock(root: &str, source_path: &str) -> Result<Option<LockFile>> {
    let path = lock_path(root, source_path);
    match fs::read_to_string(&path).await {
        Ok(data) => {
            let lock: LockFile = serde_json::from_str(&data)?;
            Ok(Some(lock))
        }
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(e) => Err(e.into()),
    }
}

pub async fn write_lock(root: &str, source_path: &str, lock: &mut LockFile) -> Result<()> {
    lock.updated_at = chrono_now();
    let path = lock_path(root, source_path);
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).await?;
    }
    let data = serde_json::to_string_pretty(lock)? + "\n";
    fs::write(&path, data).await?;
    Ok(())
}

fn chrono_now() -> String {
    // Simple ISO 8601 timestamp without external chrono dependency
    use std::time::SystemTime;
    let now = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap_or_default();
    let secs = now.as_secs();

    // Convert to date-time components
    let days = secs / 86400;
    let time_secs = secs % 86400;
    let hours = time_secs / 3600;
    let minutes = (time_secs % 3600) / 60;
    let seconds = time_secs % 60;
    let millis = now.subsec_millis();

    // Calculate year, month, day from days since epoch
    let mut y = 1970i64;
    let mut remaining = days as i64;

    loop {
        let days_in_year = if is_leap_year(y) { 366 } else { 365 };
        if remaining < days_in_year {
            break;
        }
        remaining -= days_in_year;
        y += 1;
    }

    let leap = is_leap_year(y);
    let month_days: [i64; 12] = [
        31,
        if leap { 29 } else { 28 },
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
    ];

    let mut m = 0;
    for (i, &md) in month_days.iter().enumerate() {
        if remaining < md {
            m = i + 1;
            break;
        }
        remaining -= md;
    }
    let d = remaining + 1;

    format!(
        "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}.{:03}Z",
        y, m, d, hours, minutes, seconds, millis
    )
}

fn is_leap_year(y: i64) -> bool {
    (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)
}
