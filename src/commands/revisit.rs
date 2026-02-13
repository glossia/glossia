use anyhow::{Result, bail};
use std::collections::HashMap;
use std::path::Path;
use tokio::fs;

use crate::agent::{RevisitRequest, revisit};
use crate::hash::{hash_bytes, hash_string, hash_strings};
use crate::llm::TokenUsage;
use crate::locks::{LockFile, read_lock, write_lock};
use crate::plan::{EntryKind, SourcePlan, build_plan, context_parts_for};
use crate::reporter::{Reporter, Verb};

pub struct RevisitOptions<'a> {
    pub force: bool,
    pub retries: i32,
    pub dry_run: bool,
    pub check_cmd: String,
    pub reporter: &'a dyn Reporter,
}

pub async fn revisit_cmd(root: &str, opts: &RevisitOptions<'_>) -> Result<()> {
    let pl = build_plan(root).await?;
    let revisit_sources: Vec<SourcePlan> = pl
        .sources
        .into_iter()
        .filter(|s| matches!(s.kind, EntryKind::Revisit))
        .collect();
    if revisit_sources.is_empty() {
        bail!("no revisit sources found");
    }

    struct RevisitPlan {
        source: SourcePlan,
        source_bytes: Vec<u8>,
        source_hash: String,
        lock: LockFile,
        context_hashes: HashMap<String, String>,
        revisit_map: HashMap<String, bool>,
    }

    let mut plans = Vec::new();
    let mut total = 0usize;

    for source in &revisit_sources {
        let source_bytes = fs::read(&source.abs_path).await?;
        let source_hash = hash_bytes(&source_bytes);
        let lock = read_lock(root, &source.source_path)
            .await?
            .unwrap_or_else(|| LockFile::new(&source.source_path));

        let mut context_hashes = HashMap::new();
        let mut revisit_map = HashMap::new();

        for output in &source.outputs {
            let lang_key = output.lang_key().to_string();
            let parts = context_parts_for(source, &lang_key);
            let context_hash = hash_strings(&parts);
            context_hashes.insert(lang_key.clone(), context_hash.clone());

            let output_lock = lock.outputs.get(&lang_key);
            let locked_context_hash = lock_context_hash(&lock, &lang_key);
            let up_to_date = output_lock.is_some()
                && lock.source_hash == source_hash
                && output_lock.unwrap().path == output.output_path
                && locked_context_hash == context_hash;

            if !opts.force && up_to_date {
                continue;
            }
            revisit_map.insert(lang_key, true);
            total += 1;
        }

        plans.push(RevisitPlan {
            source: source.clone(),
            source_bytes,
            source_hash,
            lock,
            context_hashes,
            revisit_map,
        });
    }

    if total == 0 {
        opts.reporter.log(Verb::Info, "no revisions needed");
        return Ok(());
    }

    // Log model info from the first source
    if let Some(first) = plans.first() {
        let coordinator_model = first.source.llm.coordinator.model.trim();
        let translator_model = first.source.llm.translator.model.trim();
        if !coordinator_model.is_empty() {
            opts.reporter.log(
                Verb::Info,
                &format!("coordinator: {}, model: {}", coordinator_model, translator_model),
            );
        } else {
            opts.reporter.log(
                Verb::Info,
                &format!("model: {}", translator_model),
            );
        }
    }

    let mut total_usage = TokenUsage::default();
    let mut current = 0usize;
    for plan_item in &mut plans {
        for output in &plan_item.source.outputs {
            let lang_key = output.lang_key().to_string();
            if !plan_item.revisit_map.contains_key(&lang_key) {
                continue;
            }

            let label = output.format_label(&plan_item.source.source_path);
            let step = current + 1;
            opts.reporter.step(Verb::Revisiting, step, total, &label);

            if opts.dry_run {
                opts.reporter.log(Verb::DryRun, &label);
                current = step;
                continue;
            }

            let mut retries = opts.retries;
            if retries < 0
                && let Some(r) = plan_item.source.entry.retries
            {
                retries = r;
            }
            if retries < 0 {
                retries = 2;
            }

            let mut check_cmds = plan_item.source.entry.check_cmds.clone();
            if !opts.check_cmd.trim().is_empty() {
                check_cmds = HashMap::new();
            }

            let parts = context_parts_for(&plan_item.source, &lang_key);
            let context = parts.join("\n\n");

            let source_text = String::from_utf8(plan_item.source_bytes.clone()).unwrap_or_default();

            let req = RevisitRequest {
                source: source_text.clone(),
                format: plan_item.source.format,
                context,
                prompt: plan_item.source.entry.prompt.clone(),
                check_cmd: pick_check_cmd(&opts.check_cmd, &plan_item.source.entry.check_cmd),
                check_cmds,
                tool_reporter: Some(opts.reporter),
                progress_label: label.clone(),
                progress_current: step,
                progress_total: total,
                retries,
                coordinator: plan_item.source.llm.coordinator.clone(),
                translator: plan_item.source.llm.translator.clone(),
                root: root.to_string(),
            };

            let result = revisit(&req).await?;
            total_usage.prompt_tokens += result.usage.prompt_tokens;
            total_usage.completion_tokens += result.usage.completion_tokens;
            total_usage.total_tokens += result.usage.total_tokens;

            let output_abs = Path::new(root).join(&output.output_path);
            if let Some(parent) = output_abs.parent() {
                fs::create_dir_all(parent).await?;
            }
            fs::write(&output_abs, &result.text).await?;

            plan_item.lock.source_hash = plan_item.source_hash.clone();
            plan_item.lock.outputs.insert(
                lang_key.clone(),
                crate::locks::OutputLock {
                    path: output.output_path.clone(),
                    hash: hash_string(&result.text),
                    context_hash: Some(
                        plan_item
                            .context_hashes
                            .get(&lang_key)
                            .cloned()
                            .unwrap_or_default(),
                    ),
                    checked_at: chrono_now(),
                },
            );
            write_lock(root, &plan_item.source.source_path, &mut plan_item.lock).await?;
            current = step;
        }
    }

    if total_usage.total_tokens > 0 {
        opts.reporter.log(
            Verb::Summary,
            &format!(
                "{} prompt + {} completion = {} total tokens",
                total_usage.prompt_tokens,
                total_usage.completion_tokens,
                total_usage.total_tokens
            ),
        );
    }

    Ok(())
}

fn pick_check_cmd(flag_cmd: &str, entry_cmd: &str) -> String {
    if !flag_cmd.trim().is_empty() {
        return flag_cmd.to_string();
    }
    entry_cmd.to_string()
}

fn lock_context_hash(lock: &LockFile, lang: &str) -> String {
    if let Some(output) = lock.outputs.get(lang)
        && let Some(ref ch) = output.context_hash
        && !ch.is_empty()
    {
        return ch.clone();
    }
    lock.context_hash.as_deref().unwrap_or("").to_string()
}

fn chrono_now() -> String {
    use std::time::SystemTime;
    let now = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap_or_default();
    let secs = now.as_secs();
    let millis = now.subsec_millis();

    let days = secs / 86400;
    let time_secs = secs % 86400;
    let hours = time_secs / 3600;
    let minutes = (time_secs % 3600) / 60;
    let seconds = time_secs % 60;

    let mut y = 1970i64;
    let mut remaining = days as i64;
    loop {
        let days_in_year = if (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0) {
            366
        } else {
            365
        };
        if remaining < days_in_year {
            break;
        }
        remaining -= days_in_year;
        y += 1;
    }
    let leap = (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
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
