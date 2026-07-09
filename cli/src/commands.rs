use anyhow::{anyhow, Result};
use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

use crate::args::{help_text, parse_args, Command};
use crate::hash::hash_string;
use crate::locks::{build_hash_state, lock_path, read_lock, stale, LockFile};
use crate::reporter::{ConsoleReporter, Reporter, Verb};
use crate::root::{find_root, resolve_base_dir};
use crate::runtime_config::{load_runtime_config, path as runtime_config_path, RuntimeConfig};
use crate::translate::build_plan;
use crate::validate::{validate_output, CheckOptions};

#[derive(Debug, Clone, Default)]
struct CheckCommandOptions {
    check_cmd: Option<String>,
    locale: Option<String>,
}

#[derive(Debug, Clone, Default)]
struct CleanOptions {
    dry_run: bool,
    orphans: bool,
    locale: Option<String>,
}

pub fn main_entry() -> i32 {
    let argv = std::env::args().skip(1).collect::<Vec<_>>();
    let parsed = match parse_args(&argv) {
        Ok(parsed) => parsed,
        Err(error) => {
            println!();
            eprintln!("{error}");
            return 1;
        }
    };

    if parsed.show_help {
        print!("{}", help_text());
        return 0;
    }

    let cwd = match std::env::current_dir() {
        Ok(cwd) => cwd,
        Err(error) => {
            println!();
            eprintln!("{error}");
            return 1;
        }
    };

    let base_dir = match resolve_base_dir(&cwd, parsed.global.path.as_deref()) {
        Ok(base_dir) => base_dir,
        Err(error) => {
            println!();
            eprintln!("{error}");
            return 1;
        }
    };

    let root = match find_root(&base_dir) {
        Ok(root) => root,
        Err(error) => {
            println!();
            eprintln!("{error}");
            return 1;
        }
    };
    let runtime = match load_runtime_config(&root) {
        Ok(runtime) => runtime,
        Err(error) => {
            println!();
            eprintln!("{error}");
            return 1;
        }
    };

    let mut reporter =
        ConsoleReporter::new(parsed.global.no_color || std::env::var("NO_COLOR").is_ok());
    let result = match parsed.command.expect("command required") {
        Command::Init => init_command(&root, &mut reporter),
        Command::Revisit => revisit_command(),
        Command::Check => check_command(
            &root,
            &runtime,
            parse_check_options(&parsed.command_args),
            &mut reporter,
        ),
        Command::Status => status_command(
            &root,
            &runtime,
            parse_check_options(&parsed.command_args),
            &mut reporter,
        ),
        Command::Clean => clean_command(
            &root,
            &runtime,
            parse_clean_options(&parsed.command_args),
            &mut reporter,
        ),
    };

    if let Err(error) = result {
        reporter.blank();
        eprintln!("{error}");
        return 1;
    }

    0
}

fn init_command(root: &Path, reporter: &mut dyn Reporter) -> Result<()> {
    let content_path = root.join("GLOSSIA.md");
    let runtime_path = runtime_config_path(root);
    if content_path.exists() {
        return Err(anyhow!(
            "GLOSSIA.md already exists at {}",
            content_path.display()
        ));
    }

    let starter = r#"---
source_language: en
model: gpt-5
sources:
  "docs/*.md": "docs/i18n/{locale}/*.md"
targets:
  - es
  - de
frontmatter: preserve
---
Project context for translators goes here.
"#;
    let runtime = r#"[llm]
provider = "openai"
api_key_env = "OPENAI_API_KEY"
"#;

    fs::write(&content_path, starter)?;
    if !runtime_path.exists() {
        fs::write(&runtime_path, runtime)?;
        reporter.log(Verb::Created, "glossia.toml");
    }
    reporter.log(Verb::Created, "GLOSSIA.md");
    Ok(())
}

fn revisit_command() -> Result<()> {
    Err(anyhow!(
        "revisit is not implemented in the Rust rewrite yet"
    ))
}

fn check_command(
    root: &Path,
    runtime: &RuntimeConfig,
    options: Result<CheckCommandOptions>,
    reporter: &mut dyn Reporter,
) -> Result<()> {
    let options = options?;
    let plan = build_plan(root, options.locale.as_deref(), runtime)?;
    if plan.items.is_empty() {
        return Err(anyhow!("no sources found"));
    }

    let total = plan.items.len();
    for (index, item) in plan.items.iter().enumerate() {
        let source_text = fs::read_to_string(&item.source_abs)?;
        let output_text = fs::read_to_string(&item.output_abs)
            .map_err(|_| anyhow!("missing output: {}", item.output_path))?;
        reporter.step(Verb::Validating, index + 1, total, &item.label());
        let mut check_options = CheckOptions {
            preserve: item.preserve.clone(),
            check_cmd: item.check_cmd.clone(),
            check_cmds: item.check_cmds.clone(),
            validation: item.validation.clone(),
            validation_cwd: item.validation_cwd.clone(),
            validation_doc_abs: item.validation_doc_abs.clone(),
            source_abs: Some(item.source_abs.clone()),
            target_abs: Some(item.output_abs.clone()),
            locale: Some(item.locale.clone()),
        };
        if let Some(check_cmd) = &options.check_cmd {
            check_options.check_cmd = Some(check_cmd.clone());
        }
        validate_output(
            root,
            item.format,
            &output_text,
            &source_text,
            &check_options,
        )?;
    }

    Ok(())
}

fn status_command(
    root: &Path,
    runtime: &RuntimeConfig,
    options: Result<CheckCommandOptions>,
    reporter: &mut dyn Reporter,
) -> Result<()> {
    let options = options?;
    let plan = build_plan(root, options.locale.as_deref(), runtime)?;
    if plan.items.is_empty() {
        return Err(anyhow!("no sources found"));
    }

    let mut ok = 0usize;
    let mut stale_count = 0usize;
    let mut missing = 0usize;

    for item in plan.items {
        let source_text = fs::read_to_string(&item.source_abs)?;
        let hash_state = build_hash_state(
            item.format,
            &item.source_path,
            &source_text,
            &item.llm.provider,
            &item.llm.model,
            &item.context_snapshots,
        );

        let Ok(output_text) = fs::read_to_string(&item.output_abs) else {
            missing += 1;
            reporter.log(Verb::Missing, &item.label());
            continue;
        };
        let output_hash = hash_string(&output_text);
        let lock = read_lock(root, &item.source_path, &item.locale)?;

        if stale(
            lock.as_ref(),
            &hash_state.hash,
            &item.output_path,
            &output_hash,
        ) {
            stale_count += 1;
            reporter.log(Verb::Stale, &item.label());
        } else {
            ok += 1;
            reporter.log(Verb::Ok, &item.label());
        }
    }

    reporter.log(
        Verb::Summary,
        &format!("{ok} ok, {stale_count} stale, {missing} missing"),
    );

    if stale_count > 0 || missing > 0 {
        return Err(anyhow!("outputs out of date"));
    }
    Ok(())
}

fn clean_command(
    root: &Path,
    runtime: &RuntimeConfig,
    options: Result<CleanOptions>,
    reporter: &mut dyn Reporter,
) -> Result<()> {
    let options = options?;
    let plan = build_plan(root, options.locale.as_deref(), runtime)?;
    if plan.items.is_empty() {
        return Err(anyhow!("no sources found"));
    }

    let mut removed = 0usize;
    let mut missing = 0usize;
    let mut lock_removed = 0usize;
    let mut planned_keys = BTreeSet::new();

    for item in &plan.items {
        planned_keys.insert((item.source_path.clone(), item.locale.clone()));
        match remove_file(&item.output_abs, options.dry_run)? {
            RemoveResult::Removed => {
                removed += 1;
                reporter.log(Verb::Removed, &item.output_path);
            }
            RemoveResult::Missing => {
                missing += 1;
                reporter.log(Verb::Skipped, &format!("{} (not found)", item.output_path));
            }
            RemoveResult::Skipped => {}
        }

        let lock_file = lock_path(root, &item.source_path, &item.locale);
        match remove_file(&lock_file, options.dry_run)? {
            RemoveResult::Removed => {
                lock_removed += 1;
                reporter.log(Verb::Removed, &lock_file.display().to_string());
            }
            RemoveResult::Missing => {
                missing += 1;
                reporter.log(
                    Verb::Skipped,
                    &format!("{} (not found)", lock_file.display()),
                );
            }
            RemoveResult::Skipped => {}
        }
    }

    if options.orphans {
        let orphan_results = clean_orphans(root, &planned_keys, options.dry_run, reporter)?;
        removed += orphan_results.removed;
        missing += orphan_results.missing;
        lock_removed += orphan_results.lock_removed;
    }

    reporter.log(
        Verb::Cleaned,
        &format!("{removed} files removed, {missing} not found, {lock_removed} lockfiles removed"),
    );

    Ok(())
}

struct OrphanCleanResult {
    removed: usize,
    missing: usize,
    lock_removed: usize,
}

fn clean_orphans(
    root: &Path,
    planned_keys: &BTreeSet<(String, String)>,
    dry_run: bool,
    reporter: &mut dyn Reporter,
) -> Result<OrphanCleanResult> {
    let mut result = OrphanCleanResult {
        removed: 0,
        missing: 0,
        lock_removed: 0,
    };
    // Scan both the current lock directory and the legacy .l10n one so orphans
    // left over from before the .l10n -> .glossia rename are still cleaned.
    let mut entries = Vec::new();
    for lock_root in [root.join(".glossia"), root.join(".l10n")] {
        if lock_root.exists() {
            entries.extend(walk_locks(&lock_root)?);
        }
    }
    if entries.is_empty() {
        return Ok(result);
    }

    for entry in entries {
        let raw = fs::read_to_string(&entry)?;
        let Ok(lock) = serde_json::from_str::<LockFile>(&raw) else {
            continue;
        };
        let locale = Path::new(&entry)
            .file_stem()
            .and_then(|value| value.to_str())
            .unwrap_or_default()
            .to_string();
        let key = (lock.source_path.clone(), locale);
        if planned_keys.contains(&key) {
            continue;
        }

        let output_path = root.join(&lock.output_path);
        match remove_file(&output_path, dry_run)? {
            RemoveResult::Removed => {
                result.removed += 1;
                reporter.log(Verb::Removed, &lock.output_path);
            }
            RemoveResult::Missing => {
                result.missing += 1;
                reporter.log(Verb::Skipped, &format!("{} (not found)", lock.output_path));
            }
            RemoveResult::Skipped => {}
        }

        match remove_file(&entry, dry_run)? {
            RemoveResult::Removed => {
                result.lock_removed += 1;
                reporter.log(Verb::Removed, &entry.display().to_string());
            }
            RemoveResult::Missing => {
                result.missing += 1;
                reporter.log(Verb::Skipped, &format!("{} (not found)", entry.display()));
            }
            RemoveResult::Skipped => {}
        }
    }

    Ok(result)
}

fn walk_locks(root: &Path) -> Result<Vec<PathBuf>> {
    let mut files = Vec::new();
    for entry in walkdir::WalkDir::new(root) {
        let entry = entry?;
        if entry.file_type().is_file()
            && entry.path().extension().and_then(|value| value.to_str()) == Some("lock")
        {
            files.push(entry.path().to_path_buf());
        }
    }
    Ok(files)
}

enum RemoveResult {
    Removed,
    Missing,
    Skipped,
}

fn remove_file(path: &Path, dry_run: bool) -> Result<RemoveResult> {
    if dry_run {
        return Ok(RemoveResult::Skipped);
    }
    if !path.exists() {
        return Ok(RemoveResult::Missing);
    }
    fs::remove_file(path)?;
    Ok(RemoveResult::Removed)
}

fn parse_check_options(argv: &[String]) -> Result<CheckCommandOptions> {
    let mut options = CheckCommandOptions::default();
    let mut i = 0;
    while i < argv.len() {
        match argv[i].as_str() {
            "--check-cmd" => {
                options.check_cmd = Some(parse_string_flag(argv, &mut i, "--check-cmd")?);
            }
            "--locale" => {
                options.locale = Some(parse_string_flag(argv, &mut i, "--locale")?);
            }
            value => return Err(anyhow!("unknown check flag: {value}")),
        }
    }
    Ok(options)
}

fn parse_clean_options(argv: &[String]) -> Result<CleanOptions> {
    let mut options = CleanOptions::default();
    let mut i = 0;
    while i < argv.len() {
        match argv[i].as_str() {
            "--dry-run" => {
                options.dry_run = true;
                i += 1;
            }
            "--orphans" => {
                options.orphans = true;
                i += 1;
            }
            "--locale" => {
                options.locale = Some(parse_string_flag(argv, &mut i, "--locale")?);
            }
            value => return Err(anyhow!("unknown clean flag: {value}")),
        }
    }
    Ok(options)
}

fn parse_string_flag(argv: &[String], index: &mut usize, flag: &str) -> Result<String> {
    let value = argv.get(*index + 1).cloned().unwrap_or_default();
    if value.is_empty() || value.starts_with('-') {
        return Err(anyhow!("{flag} requires a value"));
    }
    *index += 2;
    Ok(value)
}

