use anyhow::{Result, bail};
use std::path::Path;
use tokio::fs;

use crate::checks::{CheckOptions, validate};
use crate::plan::build_plan;
use crate::reporter::{Reporter, Verb};

pub struct CheckCmdOptions<'a> {
    pub check_cmd: String,
    pub reporter: &'a dyn Reporter,
}

pub async fn check_cmd(root: &str, opts: &CheckCmdOptions<'_>) -> Result<()> {
    let pl = build_plan(root).await?;
    if pl.sources.is_empty() {
        bail!("no sources found");
    }

    let mut total = 0usize;
    for source in &pl.sources {
        total += source.outputs.len();
    }
    let mut progress = opts.reporter.progress(Verb::Validating, total);

    let result: Result<()> = async {
        for source in &pl.sources {
            let source_bytes = fs::read_to_string(&source.abs_path).await?;
            for output in &source.outputs {
                let output_abs = Path::new(root).join(&output.output_path);
                let output_bytes = match fs::read_to_string(&output_abs).await {
                    Ok(b) => b,
                    Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
                        bail!("missing output: {}", output.output_path);
                    }
                    Err(e) => return Err(e.into()),
                };

                let check_cmd_str = pick_check_cmd(&opts.check_cmd, &source.entry.check_cmd);
                let check_cmds =
                    if !opts.check_cmd.trim().is_empty() || source.entry.check_cmds.is_empty() {
                        None
                    } else {
                        Some(&source.entry.check_cmds)
                    };

                let label = output.format_label(&source.source_path);
                progress.increment(&label);

                let check_opts = CheckOptions {
                    preserve: &source.entry.preserve,
                    check_cmd: if check_cmd_str.is_empty() {
                        None
                    } else {
                        Some(&check_cmd_str)
                    },
                    check_cmds,
                    reporter: Some(opts.reporter),
                    label: Some(&label),
                    current: 0,
                    total: 0,
                };

                validate(
                    root,
                    source.format,
                    &output_bytes,
                    &source_bytes,
                    &check_opts,
                )
                .await?;
            }
        }
        Ok(())
    }
    .await;

    progress.done();
    result
}

fn pick_check_cmd(flag_cmd: &str, entry_cmd: &str) -> String {
    if !flag_cmd.trim().is_empty() {
        return flag_cmd.to_string();
    }
    entry_cmd.to_string()
}
