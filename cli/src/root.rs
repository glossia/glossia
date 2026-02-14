use std::path::Path;

pub fn find_root(start: &str) -> String {
    let mut dir = Path::new(start).to_path_buf();
    loop {
        if dir.join(".git").exists() {
            return dir.to_string_lossy().to_string();
        }
        match dir.parent() {
            Some(parent) if parent != dir => {
                dir = parent.to_path_buf();
            }
            _ => return start.to_string(),
        }
    }
}
