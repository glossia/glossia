use std::fmt;
use std::io::{self, IsTerminal, Write};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verb {
    Validating,
    Ok,
    Stale,
    Missing,
    Removed,
    Skipped,
    Cleaned,
    Created,
    Summary,
}

impl fmt::Display for Verb {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let label = match self {
            Self::Validating => "Validating",
            Self::Ok => "Ok",
            Self::Stale => "Stale",
            Self::Missing => "Missing",
            Self::Removed => "Removed",
            Self::Skipped => "Skipped",
            Self::Cleaned => "Cleaned",
            Self::Created => "Created",
            Self::Summary => "Summary",
        };
        write!(f, "{label}")
    }
}

pub trait Reporter {
    fn log(&mut self, verb: Verb, message: &str);
    fn step(&mut self, verb: Verb, current: usize, total: usize, message: &str) {
        self.log(verb, &format!("[{current}/{total}] {message}"));
    }
    fn blank(&mut self);
}

pub struct ConsoleReporter {
    use_color: bool,
}

impl ConsoleReporter {
    pub fn new(no_color: bool) -> Self {
        Self {
            use_color: !no_color && io::stdout().is_terminal(),
        }
    }

    fn color_for_verb(&self, verb: Verb) -> &'static str {
        if !self.use_color {
            return "";
        }

        match verb {
            Verb::Ok | Verb::Removed | Verb::Cleaned | Verb::Created => "\u{001b}[1m\u{001b}[32m",
            Verb::Validating => "\u{001b}[1m\u{001b}[36m",
            Verb::Stale | Verb::Skipped => "\u{001b}[1m\u{001b}[33m",
            Verb::Missing => "\u{001b}[1m\u{001b}[31m",
            Verb::Summary => "\u{001b}[1m\u{001b}[37m",
        }
    }

    fn format_verb(&self, verb: Verb) -> String {
        let padded = format!("{verb:>12}");
        if !self.use_color {
            return padded;
        }
        format!("{}{}\u{001b}[0m", self.color_for_verb(verb), padded)
    }
}

impl Reporter for ConsoleReporter {
    fn log(&mut self, verb: Verb, message: &str) {
        let mut stdout = io::stdout().lock();
        let _ = writeln!(stdout, "{}  {}", self.format_verb(verb), message);
    }

    fn blank(&mut self) {
        let mut stdout = io::stdout().lock();
        let _ = writeln!(stdout);
    }
}
