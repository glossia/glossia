use anyhow::{Result, bail};
use std::path::Path;
use tokio::fs;

use crate::hash::{hash_bytes, hash_strings};
use crate::locks::read_lock;
use crate::plan::{build_plan, context_parts_for};
use crate::reporter::{Reporter, Verb};

pub struct StatusOptions<'a> {
    pub reporter: &'a dyn Reporter,
}

pub async fn status_cmd(root: &str, opts: &StatusOptions<'_>) -> Result<()> {
    let pl = build_plan(root).await?;
    if pl.sources.is_empty() {
        bail!("no sources found");
    }

    let mut missing = 0usize;
    let mut stale = 0usize;
    let mut up_to_date = 0usize;

    for source in &pl.sources {
        let source_bytes = fs::read(&source.abs_path).await?;
        let source_hash = hash_bytes(&source_bytes);
        let lock = read_lock(root, &source.source_path).await?;

        for output in &source.outputs {
            let output_abs = Path::new(root).join(&output.output_path);
            let label = format!(
                "{} -> {} ({})",
                source.source_path, output.output_path, output.lang
            );

            if !output_abs.exists() {
                missing += 1;
                opts.reporter.log(Verb::Missing, &label);
                continue;
            }

            let context_hash = hash_strings(&context_parts_for(source, &output.lang));

            let lock = match &lock {
                Some(l) => l,
                None => {
                    stale += 1;
                    opts.reporter.log(Verb::Stale, &label);
                    continue;
                }
            };

            if lock.source_hash != source_hash {
                stale += 1;
                opts.reporter.log(Verb::Stale, &label);
                continue;
            }

            let output_lock = match lock.outputs.get(&output.lang) {
                Some(ol) => ol,
                None => {
                    stale += 1;
                    opts.reporter.log(Verb::Stale, &label);
                    continue;
                }
            };

            let locked_ctx_hash = lock_context_hash(lock, &output.lang);
            if locked_ctx_hash != context_hash {
                stale += 1;
                opts.reporter.log(Verb::Stale, &label);
                continue;
            }

            if output_lock.path != output.output_path {
                stale += 1;
                opts.reporter.log(Verb::Stale, &label);
                continue;
            }

            up_to_date += 1;
            opts.reporter.log(Verb::Ok, &label);
        }
    }

    opts.reporter.log(
        Verb::Summary,
        &format!("{} ok, {} stale, {} missing", up_to_date, stale, missing),
    );

    if stale > 0 || missing > 0 {
        bail!("translations out of date");
    }

    Ok(())
}

fn lock_context_hash(lock: &crate::locks::LockFile, lang: &str) -> String {
    if let Some(output) = lock.outputs.get(lang)
        && let Some(ref ch) = output.context_hash
        && !ch.is_empty()
    {
        return ch.clone();
    }
    lock.context_hash.as_deref().unwrap_or("").to_string()
}
