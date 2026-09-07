use std::fmt;
use std::io::{self, IsTerminal, Write};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verb {
    Created,
}

impl fmt::Display for Verb {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let label = match self {
            Self::Created => "Created",
        };
        write!(f, "{label}")
    }
}

pub trait Reporter {
    fn log(&mut self, verb: Verb, message: &str);
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
            Verb::Created => "\u{001b}[1m\u{001b}[32m",
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
