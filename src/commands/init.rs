use anyhow::{Result, bail};
use dialoguer::{FuzzySelect, MultiSelect};
use std::path::Path;
use tokio::fs;

use crate::locales::{default_locales, locale_label, locale_name_by_code};
use crate::reporter::{Reporter, Verb};

pub struct InitOptions<'a> {
    pub reporter: &'a dyn Reporter,
}

pub async fn init_cmd(root: &str, opts: &InitOptions<'_>) -> Result<()> {
    if !atty::is(atty::Stream::Stdin) {
        bail!("init requires an interactive terminal");
    }

    let root_abs = std::fs::canonicalize(root).unwrap_or_else(|_| Path::new(root).to_path_buf());
    let l10n_path = root_abs.join("L10N.md");

    if l10n_path.exists() {
        bail!("L10N.md already exists at {}", l10n_path.display());
    }

    let locales = default_locales();
    let locale_labels: Vec<String> = locales.iter().map(locale_label).collect();
    let locale_codes: Vec<&str> = locales.iter().map(|l| l.code).collect();

    // Default to English
    let default_idx = locale_codes.iter().position(|&c| c == "en").unwrap_or(0);

    let source_idx = FuzzySelect::new()
        .with_prompt("Source language")
        .items(&locale_labels)
        .default(default_idx)
        .interact()?;
    let source_lang = locale_codes[source_idx].to_string();

    let target_labels: Vec<String> = locales
        .iter()
        .filter(|l| l.code != source_lang)
        .map(locale_label)
        .collect();
    let target_codes: Vec<&str> = locales
        .iter()
        .filter(|l| l.code != source_lang)
        .map(|l| l.code)
        .collect();

    let target_indices = MultiSelect::new()
        .with_prompt("Target languages (space to toggle, enter to confirm)")
        .items(&target_labels)
        .interact()?;

    if target_indices.is_empty() {
        bail!("no target languages selected");
    }

    let targets: Vec<String> = target_indices
        .iter()
        .map(|&i| target_codes[i].to_string())
        .collect();

    let names = locale_name_by_code(&locales);
    let content = render_l10n_template(&source_lang, &targets, &names);
    fs::write(&l10n_path, &content).await?;
    opts.reporter.log(Verb::Created, "L10N.md");

    let gitignore_path = root_abs.join(".gitignore");
    if ensure_line(&gitignore_path, "/.l10n/tmp").await? {
        opts.reporter.log(Verb::Updated, ".gitignore");
    }

    let attributes_path = root_abs.join(".gitattributes");
    if ensure_line(&attributes_path, ".l10n/locks/** linguist-generated=true").await? {
        opts.reporter.log(Verb::Updated, ".gitattributes");
    }

    opts.reporter.log(Verb::Info, "Next steps:");
    opts.reporter.log(
        Verb::Info,
        "  1. Open L10N.md and uncomment the example config.",
    );
    opts.reporter.log(
        Verb::Info,
        "  2. Update source globs, targets, and output paths for your repo.",
    );
    opts.reporter.log(
        Verb::Info,
        "  3. Set OPENAI_API_KEY (or change the provider/model settings).",
    );
    opts.reporter
        .log(Verb::Info, "  4. Run `l10n translate` to generate drafts.");

    Ok(())
}

fn render_l10n_template(
    source_lang: &str,
    targets: &[String],
    names: &std::collections::HashMap<String, String>,
) -> String {
    let mut sorted_targets = targets.to_vec();
    sorted_targets.sort();

    let source_label = label_for_locale(source_lang, names);
    let target_label: String = sorted_targets
        .iter()
        .map(|t| label_for_locale(t, names))
        .collect::<Vec<_>>()
        .join(", ");

    let mut b = String::new();
    b.push_str("+++\n");
    b.push_str("# Example configuration (uncomment to enable)\n");
    b.push_str("# [llm]\n");
    b.push_str("# provider = \"openai\"\n");
    b.push_str("# api_key = \"{{env.OPENAI_API_KEY}}\"\n");
    b.push_str("#\n");
    b.push_str("# [[llm.agent]]\n");
    b.push_str("# role = \"coordinator\"\n");
    b.push_str("# model = \"gpt-4o-mini\"\n");
    b.push_str("#\n");
    b.push_str("# [[llm.agent]]\n");
    b.push_str("# role = \"translator\"\n");
    b.push_str("# model = \"gpt-4o\"\n");
    b.push_str("#\n");
    b.push_str("# [[translate]]\n");
    b.push_str("# source = \"docs/**/*.md\"\n");
    b.push_str(&format!(
        "# targets = {}\n",
        format_toml_array(&sorted_targets)
    ));
    b.push_str("# output = \"docs/i18n/{lang}/{relpath}\"\n");
    b.push_str("+++\n\n");
    b.push_str("Uncomment the example above, then describe your product and tone here.\n");
    b.push_str(&format!("Source language: {}.\n", source_label));
    b.push_str(&format!("Target languages: {}.\n", target_label));
    b.push('\n');
    b
}

fn format_toml_array(values: &[String]) -> String {
    if values.is_empty() {
        return "[]".to_string();
    }
    let items: Vec<String> = values.iter().map(|v| format!("\"{}\"", v)).collect();
    format!("[{}]", items.join(", "))
}

fn label_for_locale(code: &str, names: &std::collections::HashMap<String, String>) -> String {
    if let Some(name) = names.get(code)
        && !name.trim().is_empty()
    {
        return format!("{} ({})", name, code);
    }
    code.to_string()
}

async fn ensure_line(path: &Path, line: &str) -> Result<bool> {
    let content = match fs::read_to_string(path).await {
        Ok(c) => c,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
            fs::write(path, format!("{}\n", line)).await?;
            return Ok(true);
        }
        Err(e) => return Err(e.into()),
    };

    let normalized = content.replace("\r\n", "\n");
    for existing in normalized.split('\n') {
        if existing.trim() == line.trim() {
            return Ok(false);
        }
    }

    let mut new_content = normalized;
    if !new_content.ends_with('\n') {
        new_content.push('\n');
    }
    new_content.push_str(line);
    new_content.push('\n');
    fs::write(path, new_content).await?;
    Ok(true)
}
