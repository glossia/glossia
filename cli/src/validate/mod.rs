mod external;
mod po;
mod preserve;
mod syntax;

use anyhow::Result;
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use crate::format::Format;
use external::{run_shell_check, run_validation_command};

#[derive(Debug, Clone, Default)]
pub struct CheckOptions {
    pub preserve: Vec<String>,
    pub check_cmd: Option<String>,
    pub check_cmds: BTreeMap<String, String>,
    pub validation: Option<Vec<String>>,
    pub validation_cwd: Option<PathBuf>,
    pub validation_doc_abs: Option<PathBuf>,
    pub source_abs: Option<PathBuf>,
    pub target_abs: Option<PathBuf>,
    pub locale: Option<String>,
}

pub fn validate_output(
    root: &Path,
    format: Format,
    output: &str,
    source: &str,
    options: &CheckOptions,
) -> Result<()> {
    syntax::validate_syntax(format, output, source)?;

    let preserve_kinds = preserve::resolve_preserve(&options.preserve);
    if !preserve_kinds.is_empty() {
        preserve::validate_preserve(output, source, &preserve_kinds)?;
    }

    if let Some(command) = &options.validation {
        run_validation_command(root, command, options)?;
    } else if let Some(command) = select_check_command(format, options) {
        run_shell_check(root, &command, output)?;
    }

    Ok(())
}

pub(crate) fn validate_po(output: &str, source: &str) -> Result<()> {
    po::validate_po(output, source)
}

fn select_check_command(format: Format, options: &CheckOptions) -> Option<String> {
    let format_key = format.to_string();
    options
        .check_cmds
        .get(&format_key)
        .cloned()
        .or_else(|| options.check_cmd.clone())
        .filter(|value| !value.trim().is_empty())
}
