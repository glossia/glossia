use serde_json::Value;
use std::collections::HashMap;
use std::fs;
use std::io::{BufRead, BufReader, Read, Write};
use std::net::{Shutdown, TcpListener, TcpStream};
#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;
use std::path::Path;
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, LazyLock, Mutex};
use std::thread::{self, JoinHandle};
use std::time::Duration;
use tempfile::TempDir;

#[test]
fn translates_markdown_with_frontmatter_and_local_context_hashing() {
    let provider = FakeProvider::start();
    let repo = TestRepo::new();
    repo.write_markdown_fixture(&provider.base_url());

    repo.run(["translate"]);
    repo.run(["check"]);
    repo.run(["status"]);

    let output = repo.read("docs/i18n/es/guide.md");
    assert!(output.contains("title: Hello world"));
    assert!(output.contains("# Hola mundo"));
    assert!(output.contains("Bienvenido {name}"));

    let lock = repo.read(".l10n/docs/guide.md/es.lock");
    assert!(lock.contains("\"kind\": \"context_snapshot\""));
    assert!(lock.contains("\"provider\": \"local_l10n\""));
    assert_eq!(provider.request_count(), 1);
}

#[test]
fn init_creates_model_only_l10n_and_runtime_config() {
    let repo = TestRepo::new();

    repo.run(["init"]);

    let l10n = repo.read("L10N.md");
    let runtime = repo.read("glossia.toml");

    assert!(l10n.contains("source_language: en"));
    assert!(l10n.contains("model: gpt-5"));
    assert!(!l10n.contains("provider:"));
    assert!(runtime.contains("[llm]"));
    assert!(runtime.contains("provider = \"openai\""));
    assert!(runtime.contains("api_key_env = \"OPENAI_API_KEY\""));
}

#[test]
fn retries_invalid_structured_output_without_gettext_specific_behavior() {
    let provider = FakeProvider::start();
    let repo = TestRepo::new();
    repo.write_json_fixture(&provider.base_url());

    repo.run(["translate"]);
    repo.run(["check"]);
    repo.run(["status"]);

    let output = repo.read("app/i18n/de/messages.json");
    assert!(output.contains("\"title\": \"Hallo Welt\""));
    assert!(output.contains("\"cta\": \"Willkommen {name}\""));
    assert!(output.contains("\"simulate_retry\": true"));
    assert_eq!(provider.request_count(), 2);
}

#[test]
fn runs_validation_from_the_declaring_document_with_replacement_semantics() {
    let provider = FakeProvider::start();
    let repo = TestRepo::new();
    repo.write_validation_fixture(&provider.base_url());

    repo.run(["translate"]);
    repo.run(["check"]);

    let trace = repo.read("docs/validation.trace");
    assert!(trace.contains("overlay"));
    assert!(trace.contains(
        repo.path()
            .join("docs")
            .join("L10N")
            .to_string_lossy()
            .as_ref()
    ));
    assert!(trace.contains(
        repo.path()
            .join("docs")
            .join("guide.md")
            .to_string_lossy()
            .as_ref()
    ));
    assert!(trace.contains(
        repo.path()
            .join("docs")
            .join("i18n")
            .join("es")
            .join("guide.md")
            .to_string_lossy()
            .as_ref()
    ));
    assert!(trace.contains(
        repo.path()
            .join("docs")
            .join("L10N")
            .join("es.md")
            .to_string_lossy()
            .as_ref()
    ));
}

struct TestRepo {
    temp_dir: TempDir,
}

impl TestRepo {
    fn new() -> Self {
        Self {
            temp_dir: tempfile::tempdir().expect("create temp repo"),
        }
    }

    fn path(&self) -> &Path {
        self.temp_dir.path()
    }

    fn run<'a>(&self, args: impl IntoIterator<Item = &'a str>) {
        let output = Command::new(env!("CARGO_BIN_EXE_glossia"))
            .arg("--path")
            .arg(self.path())
            .args(args)
            .output()
            .expect("run glossia");
        if !output.status.success() {
            panic!(
                "glossia failed:\nstdout:\n{}\nstderr:\n{}",
                String::from_utf8_lossy(&output.stdout),
                String::from_utf8_lossy(&output.stderr)
            );
        }
    }

    fn read(&self, relative_path: &str) -> String {
        fs::read_to_string(self.path().join(relative_path)).expect("read generated file")
    }

    fn write(&self, relative_path: &str, contents: &str) {
        let path = self.path().join(relative_path);
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).expect("create fixture directory");
        }
        fs::write(path, contents).expect("write fixture");
    }

    fn write_markdown_fixture(&self, base_url: &str) {
        self.write_runtime_config(base_url);
        self.write(
            "L10N.md",
            r#"---
source_language: en
model: fake-local
sources:
  "docs/*.md": "docs/i18n/{locale}/*.md"
targets:
  - es
frontmatter: preserve
---
Project context.
"#,
        );
        self.write("L10N/es.md", "Use natural Spanish.\n");
        self.write(
            "docs/guide.md",
            r#"---
title: Hello world
---
# Hello world

Welcome {name}
"#,
        );
    }

    fn write_json_fixture(&self, base_url: &str) {
        self.write_runtime_config(base_url);
        self.write(
            "L10N.md",
            r#"---
source_language: en
model: fake-local
sources:
  "app/*.json": "app/i18n/{locale}/*.json"
targets:
  - de
preserve:
  - placeholders
---
Translate UI copy, but preserve placeholders and JSON structure.
"#,
        );
        self.write(
            "app/messages.json",
            r#"{
  "title": "Hello world",
  "cta": "Welcome {name}",
  "simulate_retry": true
}
"#,
        );
    }

    fn write_validation_fixture(&self, base_url: &str) {
        self.write_runtime_config(base_url);
        self.write(
            "L10N.md",
            r#"---
source_language: en
model: fake-local
validation:
  - ./root-check.sh
sources:
  "docs/*.md": "docs/i18n/{locale}/*.md"
targets:
  - es
frontmatter: preserve
---
Root context.
"#,
        );
        self.write(
            "docs/L10N.md",
            r#"---
validation:
  - ./scope-check.sh
---
Docs scope context.
"#,
        );
        self.write(
            "docs/L10N/es.md",
            r#"---
locale: es
validation:
  - ./check.sh
  - overlay
---
Use neutral Spanish.
"#,
        );
        self.write(
            "docs/guide.md",
            r#"---
title: Hello world
---
# Hello world

Welcome {name}
"#,
        );
        self.write(
            "root-check.sh",
            "#!/bin/sh\nset -eu\nprintf 'root should not run\\n' >&2\nexit 1\n",
        );
        self.write(
            "docs/scope-check.sh",
            "#!/bin/sh\nset -eu\nprintf 'scope should not run\\n' >&2\nexit 1\n",
        );
        self.write(
            "docs/L10N/check.sh",
            "#!/bin/sh\nset -eu\n{\n  printf '%s\\n' \"$PWD\"\n  printf '%s\\n' \"$L10N_SOURCE_PATH\"\n  printf '%s\\n' \"$L10N_TARGET_PATH\"\n  printf '%s\\n' \"$L10N_LOCALE\"\n  printf '%s\\n' \"$L10N_DOC_PATH\"\n  printf '%s\\n' \"$1\"\n} > ../validation.trace\n",
        );
        self.make_executable("root-check.sh");
        self.make_executable("docs/scope-check.sh");
        self.make_executable("docs/L10N/check.sh");
    }

    fn write_runtime_config(&self, base_url: &str) {
        self.write(
            "glossia.toml",
            &format!(
                r#"[llm]
provider = "openai"
base_url = "{base_url}"
api_key = "test-key"
"#
            ),
        );
    }

    #[cfg(unix)]
    fn make_executable(&self, relative_path: &str) {
        let path = self.path().join(relative_path);
        let mut permissions = fs::metadata(&path).expect("stat script").permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(path, permissions).expect("chmod script");
    }

    #[cfg(not(unix))]
    fn make_executable(&self, _relative_path: &str) {}
}

struct FakeProvider {
    base_url: String,
    shutdown_addr: String,
    shutdown: Arc<AtomicBool>,
    request_count: Arc<Mutex<usize>>,
    thread: Option<JoinHandle<()>>,
}

impl FakeProvider {
    fn start() -> Self {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind fake provider");
        listener
            .set_nonblocking(true)
            .expect("make fake provider nonblocking");
        let addr = listener.local_addr().expect("read fake provider address");
        let shutdown = Arc::new(AtomicBool::new(false));
        let request_count = Arc::new(Mutex::new(0usize));
        let attempts = Arc::new(Mutex::new(HashMap::<String, usize>::new()));
        let thread_shutdown = Arc::clone(&shutdown);
        let thread_count = Arc::clone(&request_count);
        let thread_attempts = Arc::clone(&attempts);

        let thread = thread::spawn(move || {
            while !thread_shutdown.load(Ordering::SeqCst) {
                match listener.accept() {
                    Ok((stream, _)) => {
                        handle_connection(stream, &thread_count, &thread_attempts);
                    }
                    Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
                        thread::sleep(Duration::from_millis(10));
                    }
                    Err(error) => panic!("fake provider accept failed: {error}"),
                }
            }
        });

        Self {
            base_url: format!("http://127.0.0.1:{}/v1", addr.port()),
            shutdown_addr: format!("127.0.0.1:{}", addr.port()),
            shutdown,
            request_count,
            thread: Some(thread),
        }
    }

    fn base_url(&self) -> String {
        self.base_url.clone()
    }

    fn request_count(&self) -> usize {
        *self.request_count.lock().expect("lock request count")
    }
}

impl Drop for FakeProvider {
    fn drop(&mut self) {
        self.shutdown.store(true, Ordering::SeqCst);
        let _ = TcpStream::connect(&self.shutdown_addr);
        if let Some(thread) = self.thread.take() {
            let _ = thread.join();
        }
    }
}

fn handle_connection(
    stream: TcpStream,
    request_count: &Arc<Mutex<usize>>,
    attempts: &Arc<Mutex<HashMap<String, usize>>>,
) {
    let mut reader = BufReader::new(stream);
    let mut request_line = String::new();
    reader
        .read_line(&mut request_line)
        .expect("read request line");
    if request_line.is_empty() {
        return;
    }

    let mut content_length = 0usize;
    loop {
        let mut line = String::new();
        reader.read_line(&mut line).expect("read header line");
        if line == "\r\n" {
            break;
        }

        if let Some((name, value)) = line.split_once(':') {
            if name.eq_ignore_ascii_case("content-length") {
                content_length = value.trim().parse().expect("parse content length");
            }
        }
    }

    let mut body = vec![0; content_length];
    reader.read_exact(&mut body).expect("read request body");
    let mut stream = reader.into_inner();

    if !request_line.starts_with("POST /v1/chat/completions ") {
        write_response(
            &mut stream,
            404,
            &serde_json::json!({ "error": { "message": "not found" } }).to_string(),
        );
        return;
    }

    let Ok(payload) = serde_json::from_slice::<Value>(&body) else {
        write_response(
            &mut stream,
            400,
            &serde_json::json!({ "error": { "message": "invalid json" } }).to_string(),
        );
        return;
    };
    let messages = payload["messages"]
        .as_array()
        .expect("messages array in request");
    let locale = extract_locale(messages);
    let source = extract_source(messages);
    let key = format!("{locale}:{source}");
    let count = {
        let mut attempts = attempts.lock().expect("lock attempts");
        let count = attempts.get(&key).copied().unwrap_or(0);
        attempts.insert(key, count + 1);
        count
    };

    {
        let mut request_count = request_count.lock().expect("lock request count");
        *request_count += 1;
    }

    let content = render_response(&source, &locale, count);
    write_response(
        &mut stream,
        200,
        &serde_json::json!({
            "choices": [{ "message": { "content": content } }],
            "usage": {
                "prompt_tokens": 1,
                "completion_tokens": 1,
                "total_tokens": 2
            }
        })
        .to_string(),
    );
}

fn write_response(stream: &mut TcpStream, status: u16, body: &str) {
    let status_text = match status {
        200 => "OK",
        400 => "Bad Request",
        404 => "Not Found",
        _ => "Error",
    };
    write!(
        stream,
        "HTTP/1.1 {status} {status_text}\r\ncontent-type: application/json\r\ncontent-length: {}\r\nconnection: close\r\n\r\n{}",
        body.len(),
        body
    )
    .expect("write fake provider response");
    stream.flush().expect("flush fake provider response");
    let _ = stream.shutdown(Shutdown::Both);
}

fn extract_locale(messages: &[Value]) -> String {
    let Some(user) = messages
        .iter()
        .rev()
        .find(|message| message["role"].as_str() == Some("user"))
    else {
        return "en".into();
    };
    let Some(content) = user["content"].as_str() else {
        return "en".into();
    };
    let first_line = content.lines().next().unwrap_or_default();
    let Some(open) = first_line.rfind('(') else {
        return "en".into();
    };
    let suffix = first_line[open + 1..].trim_end_matches('.').trim_end();
    suffix.strip_suffix(')').unwrap_or("en").to_string()
}

fn extract_source(messages: &[Value]) -> String {
    let Some(user) = messages
        .iter()
        .rev()
        .find(|message| message["role"].as_str() == Some("user"))
    else {
        return String::new();
    };
    let Some(content) = user["content"].as_str() else {
        return String::new();
    };
    let Some(first_break) = content.find("\n\n") else {
        return String::new();
    };
    let remainder = &content[first_break + 2..];
    let retry_marker = "\n\nPrevious output failed validation:";
    let source = remainder
        .split(retry_marker)
        .next()
        .unwrap_or_default()
        .trim();
    source.to_string()
}

fn render_response(source: &str, locale: &str, attempt: usize) -> String {
    let trimmed = source.trim();
    if trimmed.starts_with('{') || trimmed.starts_with('[') {
        let parsed: Value = serde_json::from_str(trimmed).expect("parse structured source");
        if parsed["simulate_retry"].as_bool() == Some(true) && attempt == 0 {
            return "{\"broken\":".into();
        }
        return serde_json::to_string_pretty(&translate_json(&parsed, locale))
            .expect("encode translated json");
    }

    translate_markdown(source, locale)
}

fn translate_markdown(source: &str, locale: &str) -> String {
    let mut in_fence = false;
    source
        .lines()
        .map(|line| {
            if line.trim_start().starts_with("```") {
                in_fence = !in_fence;
                return line.to_string();
            }
            if in_fence {
                return line.to_string();
            }
            translate_string(line, locale)
        })
        .collect::<Vec<_>>()
        .join("\n")
}

fn translate_json(value: &Value, locale: &str) -> Value {
    match value {
        Value::String(string) => Value::String(translate_string(string, locale)),
        Value::Array(array) => Value::Array(
            array
                .iter()
                .map(|entry| translate_json(entry, locale))
                .collect(),
        ),
        Value::Object(object) => Value::Object(
            object
                .iter()
                .map(|(key, entry)| (key.clone(), translate_json(entry, locale)))
                .collect(),
        ),
        _ => value.clone(),
    }
}

fn translate_string(text: &str, locale: &str) -> String {
    let Some(dictionary) = dictionaries().get(locale) else {
        return text.to_string();
    };
    let mut translated = text.to_string();
    for &(key, replacement) in dictionary {
        translated = translated.replace(key, replacement);
    }
    translated
}

fn dictionaries() -> &'static HashMap<&'static str, Vec<(&'static str, &'static str)>> {
    static DICTIONARIES: LazyLock<HashMap<&'static str, Vec<(&'static str, &'static str)>>> =
        LazyLock::new(|| {
            let mut dictionaries = HashMap::from([
                (
                    "es",
                    vec![
                        ("Hello world", "Hola mundo"),
                        ("Project context.", "Contexto del proyecto."),
                        ("Welcome {name}", "Bienvenido {name}"),
                    ],
                ),
                (
                    "de",
                    vec![
                        ("Hello world", "Hallo Welt"),
                        ("Welcome {name}", "Willkommen {name}"),
                    ],
                ),
            ]);
            // Apply longer keys before shorter ones so a substring entry
            // (e.g. "Hello") can't partially translate a phrase that has a
            // longer, more specific entry (e.g. "Hello world").
            for entries in dictionaries.values_mut() {
                entries.sort_by_key(|(key, _)| std::cmp::Reverse(key.len()));
            }
            dictionaries
        });
    &DICTIONARIES
}
