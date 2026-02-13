use std::io::{IsTerminal, Write};
use std::sync::Mutex;

use crate::reporter::{ProgressReporter, Reporter, Verb};

const RESET: &str = "\x1b[0m";
const BOLD: &str = "\x1b[1m";
const DIM: &str = "\x1b[2m";
const GREEN: &str = "\x1b[32m";
const CYAN: &str = "\x1b[36m";
const YELLOW: &str = "\x1b[33m";
const RED: &str = "\x1b[31m";
const WHITE: &str = "\x1b[37m";
const MAGENTA: &str = "\x1b[35m";
const CLEAR_LINE: &str = "\x1b[2K";

fn verb_color(verb: Verb) -> &'static str {
    match verb {
        Verb::Ok
        | Verb::Translated
        | Verb::Revisited
        | Verb::Removed
        | Verb::Cleaned
        | Verb::Created
        | Verb::Updated => GREEN,
        Verb::Translating | Verb::Revisiting | Verb::Validating | Verb::Checking => CYAN,
        Verb::Stale | Verb::Skipped | Verb::DryRun => YELLOW,
        Verb::Missing => RED,
        Verb::Summary | Verb::Info => WHITE,
    }
}

const VERB_COL: usize = 12;

fn format_verb(verb: &str, color: bool) -> String {
    let padded = format!("{:>width$}", verb, width = VERB_COL);
    if !color {
        return padded;
    }
    let col = verb_color(match verb {
        "Translating" => Verb::Translating,
        "Revisiting" => Verb::Revisiting,
        "Validating" => Verb::Validating,
        "Checking" => Verb::Checking,
        "Ok" => Verb::Ok,
        "Stale" => Verb::Stale,
        "Missing" => Verb::Missing,
        "Removed" => Verb::Removed,
        "Skipped" => Verb::Skipped,
        "Translated" => Verb::Translated,
        "Revisited" => Verb::Revisited,
        "Cleaned" => Verb::Cleaned,
        "Created" => Verb::Created,
        "Updated" => Verb::Updated,
        "Summary" => Verb::Summary,
        "Info" => Verb::Info,
        "Dry run" => Verb::DryRun,
        _ => Verb::Info,
    });
    format!("{}{}{}{}", BOLD, col, padded, RESET)
}

/// Colorize "source -> output (lang)" style messages.
fn colorize_message(message: &str, verb: Verb) -> String {
    // Summary lines like "18 ok, 0 stale, 0 missing"
    if verb == Verb::Summary {
        return colorize_summary(message);
    }

    // Path messages with " -> " arrow and "(lang)" suffix
    if let Some((source, rest)) = message.split_once(" -> ") {
        if let Some((output, lang)) = rest.rsplit_once(" (") {
            let lang = lang.trim_end_matches(')');
            return format!(
                "{}{}{}  {}{}{}  {}{}{}  {}{}{}{}{}",
                DIM,
                source,
                RESET,
                CYAN,
                "->",
                RESET,
                DIM,
                output,
                RESET,
                MAGENTA,
                "(",
                lang,
                ")",
                RESET,
            );
        }
        // Arrow but no lang
        return format!(
            "{}{}{}  {}{}{}  {}{}{}",
            DIM, source, RESET, CYAN, "->", RESET, DIM, rest, RESET,
        );
    }

    // Default: just dim the message slightly for non-info verbs
    match verb {
        Verb::Info => message.to_string(),
        _ => format!("{}{}{}", DIM, message, RESET),
    }
}

/// Colorize summary: "18 ok, 0 stale, 0 missing"
fn colorize_summary(message: &str) -> String {
    let mut result = String::new();
    for (i, part) in message.split(", ").enumerate() {
        if i > 0 {
            result.push_str(&format!("{}{}{}", DIM, ", ", RESET));
        }
        if let Some((num, label)) = part.split_once(' ') {
            let n: usize = num.parse().unwrap_or(0);
            let (num_color, label_color) = match label {
                "ok" => {
                    if n > 0 {
                        (GREEN, GREEN)
                    } else {
                        (DIM, DIM)
                    }
                }
                "stale" => {
                    if n > 0 {
                        (YELLOW, YELLOW)
                    } else {
                        (DIM, DIM)
                    }
                }
                "missing" => {
                    if n > 0 {
                        (RED, RED)
                    } else {
                        (DIM, DIM)
                    }
                }
                _ => {
                    if n > 0 {
                        (WHITE, DIM)
                    } else {
                        (DIM, DIM)
                    }
                }
            };
            result.push_str(&format!(
                "{}{}{}{} {}{}{}",
                BOLD, num_color, num, RESET, label_color, label, RESET
            ));
        } else {
            result.push_str(part);
        }
    }
    result
}

/// Colorize "[N/N]" step counter prefix.
fn colorize_step_label(message: &str) -> String {
    // "[1/18] source -> output (lang)"
    if let Some(rest) = message.strip_prefix('[')
        && let Some((counter, body)) = rest.split_once("] ")
    {
        return format!("{}[{}]{} {}", DIM, counter, RESET, body);
    }
    message.to_string()
}

fn format_line(verb: &str, message: &str, color: bool) -> String {
    let formatted_verb = format_verb(verb, color);
    if !color {
        return format!("{}  {}", formatted_verb, message);
    }
    format!("{}  {}", formatted_verb, message)
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
        let msg = if self.color {
            colorize_message(message, verb)
        } else {
            message.to_string()
        };
        let line = format_line(verb.as_str(), &msg, self.color);
        let _ = writeln!(std::io::stdout(), "{}", line);
        let _ = std::io::stdout().flush();
    }

    fn step(&self, verb: Verb, current: usize, total: usize, message: &str) {
        let raw_label = format!("[{}/{}] {}", current, total, message);
        let label = if self.color {
            let colored_msg = colorize_message(message, verb);
            let full = format!("[{}/{}] {}", current, total, colored_msg);
            colorize_step_label(&full)
        } else {
            raw_label
        };
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
        let raw_msg = format!("[{}/{}] {}", self.current, self.total, label);
        let msg = if self.color {
            let colored_label = colorize_message(label, self.verb);
            let full = format!("[{}/{}] {}", self.current, self.total, colored_label);
            colorize_step_label(&full)
        } else {
            raw_msg
        };
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
