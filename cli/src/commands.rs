use anyhow::{anyhow, Result};
use std::fs;
use std::path::Path;

use crate::args::{help_text, parse_args, Command};
use crate::reporter::{ConsoleReporter, Reporter, Verb};
use crate::root::{find_root, resolve_base_dir};

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
    let mut reporter =
        ConsoleReporter::new(parsed.global.no_color || std::env::var("NO_COLOR").is_ok());
    let result = match parsed.command.expect("command required") {
        Command::Init => init_command(&root, &mut reporter),
        Command::Revisit => revisit_command(),
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

    fs::write(&content_path, starter)?;
    reporter.log(Verb::Created, "GLOSSIA.md");
    Ok(())
}

fn revisit_command() -> Result<()> {
    Err(anyhow!(
        "revisit is not implemented in the Rust rewrite yet"
    ))
}
