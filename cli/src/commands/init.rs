use anyhow::{Result, bail};
use dialoguer::FuzzySelect;
use std::path::Path;

use crate::acp::{detect_agents, install_recommendations, run_acp_init};
use crate::reporter::{Reporter, Verb};

pub struct InitOptions<'a> {
    pub reporter: &'a dyn Reporter,
}

pub async fn init_cmd(root: &str, opts: &InitOptions<'_>) -> Result<()> {
    if !atty::is(atty::Stream::Stdin) {
        bail!("init requires an interactive terminal");
    }

    let root_abs = std::fs::canonicalize(root).unwrap_or_else(|_| Path::new(root).to_path_buf());
    let content_path = root_abs.join("CONTENT.md");

    if content_path.exists() {
        bail!("CONTENT.md already exists at {}", content_path.display());
    }

    let agents = detect_agents();
    if agents.is_empty() {
        bail!(
            "No ACP-compatible coding agents found.\n\nInstall one of:\n{}",
            install_recommendations()
        );
    }

    let agent = if agents.len() == 1 {
        &agents[0]
    } else {
        let labels: Vec<&str> = agents.iter().map(|a| a.name).collect();
        let idx = FuzzySelect::new()
            .with_prompt("Select a coding agent")
            .items(&labels)
            .default(0)
            .interact()?;
        &agents[idx]
    };

    run_acp_init(root, agent, opts.reporter).await?;

    // Verify CONTENT.md was created
    if content_path.exists() {
        opts.reporter.log(Verb::Created, "CONTENT.md");
    }

    Ok(())
}
