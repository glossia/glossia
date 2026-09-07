use anyhow::{anyhow, Result};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Command {
    Init,
    Revisit,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct GlobalFlags {
    pub no_color: bool,
    pub path: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParsedArgs {
    pub show_help: bool,
    pub command: Option<Command>,
    pub command_args: Vec<String>,
    pub global: GlobalFlags,
}

pub fn parse_args(argv: &[String]) -> Result<ParsedArgs> {
    if argv.is_empty() || contains_help(argv) {
        return Ok(ParsedArgs {
            show_help: true,
            command: None,
            command_args: Vec::new(),
            global: GlobalFlags::default(),
        });
    }

    let mut global = GlobalFlags::default();
    let mut command = None;
    let mut command_args = Vec::new();
    let mut i = 0;

    while i < argv.len() {
        let token = &argv[i];

        if token == "--no-color" {
            global.no_color = true;
            i += 1;
            continue;
        }

        if token == "--path" {
            let value = argv.get(i + 1).cloned().unwrap_or_default();
            if value.is_empty() || value.starts_with('-') {
                return Err(anyhow!("--path requires a value"));
            }
            global.path = Some(value);
            i += 2;
            continue;
        }

        if command.is_none() && !token.starts_with('-') {
            command = Some(parse_command(token)?);
            i += 1;
            continue;
        }

        if command.is_some() {
            command_args.push(token.clone());
            i += 1;
            continue;
        }

        return Err(anyhow!("unknown option: {token}"));
    }

    if command.is_none() {
        return Err(anyhow!("missing command (expected one of: init, revisit)"));
    }

    Ok(ParsedArgs {
        show_help: false,
        command,
        command_args,
        global,
    })
}

fn contains_help(argv: &[String]) -> bool {
    argv.iter().any(|token| token == "--help" || token == "-h")
}

fn parse_command(value: &str) -> Result<Command> {
    match value {
        "init" => Ok(Command::Init),
        "revisit" => Ok(Command::Revisit),
        _ => Err(anyhow!("unknown command: {value}")),
    }
}

pub fn help_text() -> &'static str {
    "glossia - Localize like you ship software.

USAGE:
  glossia <command> [options]

COMMANDS:
  init       Initialize Glossia in this repo
  revisit    Revisit content in the source language

GLOBAL OPTIONS:
  --no-color        Disable color output
  --path <path>     Run as if in this directory

Run 'glossia <command> --help' for command-specific flags.
"
}

#[cfg(test)]
mod tests {
    use super::{help_text, parse_args, Command};

    #[test]
    fn accepts_setup_and_source_revision_commands() {
        let init = parse_args(&["init".into()]).unwrap();
        let revisit = parse_args(&["revisit".into()]).unwrap();

        assert_eq!(init.command, Some(Command::Init));
        assert_eq!(revisit.command, Some(Command::Revisit));
    }

    #[test]
    fn rejects_retired_translation_workflow_commands() {
        for command in ["translate", "check", "status", "clean"] {
            let error = parse_args(&[command.into()]).unwrap_err();
            assert_eq!(error.to_string(), format!("unknown command: {command}"));
            assert!(!help_text().contains(&format!("  {command}")));
        }
    }
}
