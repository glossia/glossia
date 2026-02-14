#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verb {
    Translating,
    Revisiting,
    Validating,
    Checking,
    Ok,
    Stale,
    Missing,
    Removed,
    Skipped,
    Translated,
    Revisited,
    Cleaned,
    Created,
    Updated,
    Summary,
    Info,
    DryRun,
}

impl Verb {
    pub fn as_str(&self) -> &'static str {
        match self {
            Verb::Translating => "Translating",
            Verb::Revisiting => "Revisiting",
            Verb::Validating => "Validating",
            Verb::Checking => "Checking",
            Verb::Ok => "Ok",
            Verb::Stale => "Stale",
            Verb::Missing => "Missing",
            Verb::Removed => "Removed",
            Verb::Skipped => "Skipped",
            Verb::Translated => "Translated",
            Verb::Revisited => "Revisited",
            Verb::Cleaned => "Cleaned",
            Verb::Created => "Created",
            Verb::Updated => "Updated",
            Verb::Summary => "Summary",
            Verb::Info => "Info",
            Verb::DryRun => "Dry run",
        }
    }
}

pub trait ProgressReporter {
    fn increment(&mut self, label: &str);
    fn done(&mut self);
}

pub trait Reporter: Send + Sync {
    fn log(&self, verb: Verb, message: &str);
    fn step(&self, verb: Verb, current: usize, total: usize, message: &str);
    fn blank(&self);
    fn progress(&self, verb: Verb, total: usize) -> Box<dyn ProgressReporter>;
}

struct NoopProgress;

impl ProgressReporter for NoopProgress {
    fn increment(&mut self, _label: &str) {}
    fn done(&mut self) {}
}

pub struct NoopReporter;

impl Reporter for NoopReporter {
    fn log(&self, _verb: Verb, _message: &str) {}
    fn step(&self, _verb: Verb, _current: usize, _total: usize, _message: &str) {}
    fn blank(&self) {}
    fn progress(&self, _verb: Verb, _total: usize) -> Box<dyn ProgressReporter> {
        Box::new(NoopProgress)
    }
}

pub fn ensure_reporter(reporter: Option<&dyn Reporter>) -> &dyn Reporter {
    static NOOP: NoopReporter = NoopReporter;
    reporter.unwrap_or(&NOOP)
}
