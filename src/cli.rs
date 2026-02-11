use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "l10n", about = "Localize like you ship software.")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,

    /// Disable color output
    #[arg(long, global = true)]
    pub no_color: bool,

    /// Run as if in this directory
    #[arg(long, global = true)]
    pub path: Option<String>,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Initialize l10n in this repo
    Init,

    /// Generate translations
    Translate {
        /// Retranslate even if up to date
        #[arg(long)]
        force: bool,

        /// Skip human review (default true)
        #[arg(long, default_value_t = true)]
        yolo: bool,

        /// Disable yolo mode, enable human review
        #[arg(long = "no-yolo")]
        no_yolo: bool,

        /// Override retry count (-1 uses config or default)
        #[arg(long, default_value_t = -1)]
        retries: i32,

        /// Print actions without writing files
        #[arg(long)]
        dry_run: bool,

        /// Override external check command
        #[arg(long)]
        check_cmd: Option<String>,
    },

    /// Validate outputs
    Check {
        /// Override external check command
        #[arg(long)]
        check_cmd: Option<String>,
    },

    /// Report missing or stale outputs
    Status,

    /// Remove generated outputs and lockfiles
    Clean {
        /// Print actions without removing files
        #[arg(long)]
        dry_run: bool,

        /// Also remove outputs for sources no longer in config
        #[arg(long)]
        orphans: bool,
    },
}
