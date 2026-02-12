#![allow(dead_code)]

mod acp;
mod agent;
mod checks;
mod cli;
mod commands;
mod config;
mod format;
mod hash;
mod llm;
mod locales;
mod locks;
mod output;
mod plan;
mod renderer;
mod reporter;
mod root;
mod tools;

use clap::Parser;
use std::path::Path;
use std::process;

use cli::{Cli, Commands};
use renderer::Renderer;
use reporter::Reporter;
use root::find_root;

fn resolve_base_dir(cwd: &str, override_path: Option<&str>) -> String {
    match override_path {
        None => cwd.to_string(),
        Some(p) if p.trim().is_empty() => cwd.to_string(),
        Some(p) => {
            let path = if Path::new(p).is_absolute() {
                p.to_string()
            } else {
                Path::new(cwd).join(p).to_string_lossy().to_string()
            };
            let meta = std::fs::metadata(&path);
            match meta {
                Ok(m) if !m.is_dir() => Path::new(&path)
                    .parent()
                    .map(|p| p.to_string_lossy().to_string())
                    .unwrap_or(path),
                _ => path,
            }
        }
    }
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();

    let cwd = std::env::current_dir()
        .unwrap_or_else(|_| Path::new(".").to_path_buf())
        .to_string_lossy()
        .to_string();

    let base_dir = resolve_base_dir(&cwd, cli.path.as_deref());
    let root = find_root(&base_dir);
    let no_color = cli.no_color || std::env::var("NO_COLOR").is_ok();
    let reporter = Renderer::new(no_color);

    let result = match cli.command {
        Commands::Init => {
            commands::init::init_cmd(
                &root,
                &commands::init::InitOptions {
                    reporter: &reporter,
                },
            )
            .await
        }
        Commands::Translate {
            force,
            yolo,
            no_yolo,
            retries,
            dry_run,
            check_cmd,
        } => {
            commands::translate::translate_cmd(
                &root,
                &commands::translate::TranslateOptions {
                    force,
                    yolo: if no_yolo { false } else { yolo },
                    retries,
                    dry_run,
                    check_cmd: check_cmd.unwrap_or_default(),
                    reporter: &reporter,
                },
            )
            .await
        }
        Commands::Check { check_cmd } => {
            commands::check::check_cmd(
                &root,
                &commands::check::CheckCmdOptions {
                    check_cmd: check_cmd.unwrap_or_default(),
                    reporter: &reporter,
                },
            )
            .await
        }
        Commands::Status => {
            commands::status::status_cmd(
                &root,
                &commands::status::StatusOptions {
                    reporter: &reporter,
                },
            )
            .await
        }
        Commands::Clean { dry_run, orphans } => {
            commands::clean::clean_cmd(
                &root,
                &commands::clean::CleanOptions {
                    dry_run,
                    orphans,
                    reporter: &reporter,
                },
            )
            .await
        }
    };

    if let Err(e) = result {
        reporter.blank();
        eprintln!("{}", e);
        process::exit(1);
    }
}
