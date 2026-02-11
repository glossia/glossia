use std::io::{IsTerminal, Write};
use std::sync::Mutex;

use crate::reporter::{ProgressReporter, Reporter, Verb};

const RESET: &str = "\x1b[0m";
const BOLD: &str = "\x1b[1m";
const GREEN: &str = "\x1b[32m";
const CYAN: &str = "\x1b[36m";
const YELLOW: &str = "\x1b[33m";
const RED: &str = "\x1b[31m";
const WHITE: &str = "\x1b[37m";
const CLEAR_LINE: &str = "\x1b[2K";

fn verb_color(verb: Verb) -> &'static str {
    match verb {
        Verb::Ok
        | Verb::Translated
        | Verb::Removed
        | Verb::Cleaned
        | Verb::Created
        | Verb::Updated => GREEN,
        Verb::Translating | Verb::Validating | Verb::Checking => CYAN,
        Verb::Stale | Verb::Skipped | Verb::DryRun => YELLOW,
        Verb::Missing => RED,
        Verb::Summary | Verb::Info => WHITE,
    }
}

const VERB_COL: usize = 12;

fn format_line(verb: &str, message: &str, color: bool) -> String {
    let padded = format!("{:>width$}", verb, width = VERB_COL);
    if !color {
        return format!("{}  {}", padded, message);
    }
    let col = verb_color(match verb {
        "Translating" => Verb::Translating,
        "Validating" => Verb::Validating,
        "Checking" => Verb::Checking,
        "Ok" => Verb::Ok,
        "Stale" => Verb::Stale,
        "Missing" => Verb::Missing,
        "Removed" => Verb::Removed,
        "Skipped" => Verb::Skipped,
        "Translated" => Verb::Translated,
        "Cleaned" => Verb::Cleaned,
        "Created" => Verb::Created,
        "Updated" => Verb::Updated,
        "Summary" => Verb::Summary,
        "Info" => Verb::Info,
        "Dry run" => Verb::DryRun,
        _ => Verb::Info,
    });
    format!("{}{}{}{}  {}", BOLD, col, padded, RESET, message)
}

struct RendererState {
    in_place_line: bool,
}

pub struct Renderer {
    is_tty: bool,
    color: bool,
    state: Mutex<RendererState>,
}

impl Renderer {
    pub fn new(no_color: bool) -> Self {
        let is_tty = std::io::stdout().is_terminal();
        Self {
            is_tty,
            color: !no_color && is_tty,
            state: Mutex::new(RendererState {
                in_place_line: false,
            }),
        }
    }

    fn finalize(&self) {
        let mut state = self.state.lock().unwrap();
        if state.in_place_line {
            let _ = writeln!(std::io::stdout());
            let _ = std::io::stdout().flush();
            state.in_place_line = false;
        }
    }
}

impl Reporter for Renderer {
    fn log(&self, verb: Verb, message: &str) {
        self.finalize();
        let line = format_line(verb.as_str(), message, self.color);
        let _ = writeln!(std::io::stdout(), "{}", line);
        let _ = std::io::stdout().flush();
    }

    fn step(&self, verb: Verb, current: usize, total: usize, message: &str) {
        let label = format!("[{}/{}] {}", current, total, message);
        let line = format_line(verb.as_str(), &label, self.color);
        let mut state = self.state.lock().unwrap();

        if self.is_tty {
            if state.in_place_line {
                let clear = if self.color { CLEAR_LINE } else { "" };
                let _ = write!(std::io::stdout(), "\r{}", clear);
            }
            let _ = write!(std::io::stdout(), "{}", line);
            let _ = std::io::stdout().flush();
            state.in_place_line = true;
        } else {
            let _ = writeln!(std::io::stdout(), "{}", line);
            let _ = std::io::stdout().flush();
        }
    }

    fn blank(&self) {
        self.finalize();
        let _ = writeln!(std::io::stdout());
        let _ = std::io::stdout().flush();
    }

    fn progress(&self, verb: Verb, total: usize) -> Box<dyn ProgressReporter> {
        if total == 0 {
            return Box::new(NoopProgress);
        }
        Box::new(ProgressReporterImpl {
            verb,
            total,
            current: 0,
            is_tty: self.is_tty,
            color: self.color,
        })
    }
}

struct NoopProgress;

impl ProgressReporter for NoopProgress {
    fn increment(&mut self, _label: &str) {}
    fn done(&mut self) {}
}

struct ProgressReporterImpl {
    verb: Verb,
    total: usize,
    current: usize,
    is_tty: bool,
    color: bool,
}

impl ProgressReporter for ProgressReporterImpl {
    fn increment(&mut self, label: &str) {
        self.current += 1;
        let msg = format!("[{}/{}] {}", self.current, self.total, label);
        let line = format_line(self.verb.as_str(), &msg, self.color);

        if self.is_tty {
            let clear = if self.color { CLEAR_LINE } else { "" };
            let _ = write!(std::io::stdout(), "\r{}{}", clear, line);
            let _ = std::io::stdout().flush();
        } else {
            let _ = writeln!(std::io::stdout(), "{}", line);
            let _ = std::io::stdout().flush();
        }
    }

    fn done(&mut self) {
        if self.is_tty && self.current > 0 {
            let _ = writeln!(std::io::stdout());
            let _ = std::io::stdout().flush();
        }
    }
}
