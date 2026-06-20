use anyhow::{anyhow, Result};
use std::path::Path;
use wait_timeout::ChildExt;

use super::CheckOptions;

pub(super) fn run_shell_check(root: &Path, command_template: &str, content: &str) -> Result<()> {
    let tmp_dir = root.join(".l10n").join("tmp");
    std::fs::create_dir_all(&tmp_dir)?;

    let mut tmp = tempfile::Builder::new()
        .prefix("check-")
        .suffix(".tmp")
        .tempfile_in(tmp_dir)?;
    std::io::Write::write_all(&mut tmp, content.as_bytes())?;
    let path = tmp.path().to_string_lossy().to_string();
    let command = command_template.replace("{path}", &path);

    let mut child = if cfg!(windows) {
        std::process::Command::new("cmd")
            .arg("/d")
            .arg("/s")
            .arg("/c")
            .arg(&command)
            .current_dir(root)
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()?
    } else {
        std::process::Command::new("sh")
            .arg("-c")
            .arg(&command)
            .current_dir(root)
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()?
    };

    let status = wait_for_completion(&mut child, "external check failed: timed out")?;
    let output = child.wait_with_output()?;
    if status.success() {
        return Ok(());
    }

    Err(anyhow!(
        "external check failed: exit {}\n{}",
        status.code().unwrap_or(-1),
        combined_output(&output)
    ))
}

pub(super) fn run_validation_command(
    root: &Path,
    argv: &[String],
    options: &CheckOptions,
) -> Result<()> {
    let cwd = options.validation_cwd.as_deref().unwrap_or(root);
    let doc_abs = options
        .validation_doc_abs
        .as_ref()
        .ok_or_else(|| anyhow!("validation requires declaring document path"))?;
    let source_abs = options
        .source_abs
        .as_ref()
        .ok_or_else(|| anyhow!("validation requires source path"))?;
    let target_abs = options
        .target_abs
        .as_ref()
        .ok_or_else(|| anyhow!("validation requires target path"))?;
    let locale = options
        .locale
        .as_deref()
        .ok_or_else(|| anyhow!("validation requires locale"))?;

    let mut child = std::process::Command::new(&argv[0])
        .args(&argv[1..])
        .current_dir(cwd)
        .env("L10N_SOURCE_PATH", source_abs)
        .env("L10N_TARGET_PATH", target_abs)
        .env("L10N_LOCALE", locale)
        .env("L10N_DOC_PATH", doc_abs)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()?;

    let status = wait_for_completion(&mut child, "validation failed: timed out")?;
    let output = child.wait_with_output()?;
    if status.success() {
        return Ok(());
    }

    Err(anyhow!(
        "validation failed: exit {}\n{}",
        status.code().unwrap_or(-1),
        combined_output(&output)
    ))
}

fn wait_for_completion(
    child: &mut std::process::Child,
    timeout_message: &str,
) -> Result<std::process::ExitStatus> {
    let timeout = std::time::Duration::from_secs(600);
    child
        .wait_timeout(timeout)?
        .ok_or_else(|| anyhow!(timeout_message.to_string()))
}

fn combined_output(output: &std::process::Output) -> String {
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    [stderr, stdout]
        .into_iter()
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>()
        .join("\n")
}
