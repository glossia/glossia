//! Persistent Phoenix transport, following Atlas native's presence/orbit_live model.
//! Native credential owners refresh and persist credentials before `open`; `next`
//! and `close` are local operations and must not hold their auth executor or slots.
use crate::{Result, Session, error, invalid, now, validate_registration, validate_uuid};
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::collections::HashMap;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Condvar, Mutex, OnceLock};
use std::time::Duration;
use tokio::sync::watch;
use tokio::time::{Instant, timeout};
use tokio_tungstenite::tungstenite::{
    Error as SocketError, Message, client::IntoClientRequest, http::Request,
    protocol::WebSocketConfig,
};

const MAX_CONNECTIONS: usize = 16;
const MAX_MESSAGE: usize = 1024 * 1024;
static WORKERS: AtomicUsize = AtomicUsize::new(0);

#[derive(Deserialize)]
#[serde(tag = "action", rename_all = "snake_case")]
pub(crate) enum Action {
    Open {
        session: Session,
        selection: crate::workspace::Selection,
        id: String,
    },
    Next {
        connection: String,
        after: u64,
    },
    Close {
        connection: String,
    },
}

struct Connection {
    closed: watch::Sender<bool>,
    latest: Mutex<Value>,
    changed: Condvar,
}

fn connections() -> &'static Mutex<HashMap<String, Arc<Connection>>> {
    static CONNECTIONS: OnceLock<Mutex<HashMap<String, Arc<Connection>>>> = OnceLock::new();
    CONNECTIONS.get_or_init(Default::default)
}

pub(crate) fn execute(action: Action) -> Result<Value> {
    match action {
        Action::Open {
            session,
            selection,
            id,
        } => {
            let mut url = validate_registration(&session.registration)?;
            if session.expires_at <= now() || session.access_token.is_empty() {
                return Err(error("sign_in_required", "Sign in to Glossia again."));
            }
            validate_uuid(&id)?;
            let (organization, project) = selection.live_handles()?;
            let payload = json!({"organization":organization,"project":project});
            url.set_scheme("wss").map_err(|_| invalid())?;
            url.set_path("/native/socket/websocket");
            url.set_query(Some("vsn=2.0.0"));
            // Only unit tests may replace the validated TLS endpoint with loopback.
            #[cfg(test)]
            let url = tests::endpoint(url);
            open(url.as_str(), session, id.to_ascii_lowercase(), payload)
        }
        Action::Next { connection, after } => {
            let state = connections()
                .lock()
                .map_err(|_| invalid())?
                .get(&connection)
                .cloned();
            let Some(state) = state else {
                return Ok(
                    json!({"sequence":after.saturating_add(1),"state":"closed","snapshot":null}),
                );
            };
            let latest = state.latest.lock().map_err(|_| invalid())?;
            let (latest, _) = state
                .changed
                .wait_timeout_while(latest, Duration::from_secs(30), |value| {
                    value["sequence"].as_u64().unwrap_or(0) <= after && !terminal(value)
                })
                .map_err(|_| invalid())?;
            Ok(latest.clone())
        }
        Action::Close { connection } => {
            let state = connections()
                .lock()
                .map_err(|_| invalid())?
                .remove(&connection);
            if let Some(state) = state {
                // Publish before cancellation so blocked next calls cannot see stale data.
                publish(&state, "closed", Value::Null, None);
                state.closed.send_replace(true);
            }
            Ok(json!({"closed":true}))
        }
    }
}

fn terminal(value: &Value) -> bool {
    matches!(
        value["state"].as_str(),
        Some("closed" | "unavailable" | "needs_session")
    )
}

fn open(url: &str, session: Session, id: String, payload: Value) -> Result<Value> {
    let mut request = url.into_client_request().map_err(|_| invalid())?;
    request.headers_mut().insert(
        "Sec-WebSocket-Protocol",
        format!(
            "phoenix, base64url.bearer.phx.{}",
            URL_SAFE_NO_PAD.encode(&session.access_token)
        )
        .parse()
        .map_err(|_| invalid())?,
    );
    let handle = crate::random_string()?;
    let (closed, receiver) = watch::channel(false);
    let state = Arc::new(Connection {
        closed,
        latest: Mutex::new(json!({"sequence":1,"state":"connecting","snapshot":null})),
        changed: Condvar::new(),
    });
    let mut registry = connections().lock().map_err(|_| invalid())?;
    // Count detached workers too: rapid open/close must not exceed the limit while
    // previous runtimes are still tearing down their DNS/TLS/socket resources.
    if registry.len() >= MAX_CONNECTIONS || WORKERS.load(Ordering::SeqCst) >= MAX_CONNECTIONS {
        return Err(error("internal", "Too many live translation connections."));
    }
    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .map_err(|_| error("internal", "Could not open live translation progress."))?;
    WORKERS.fetch_add(1, Ordering::SeqCst);
    let worker = Worker;
    registry.insert(handle.clone(), state.clone());
    if std::thread::Builder::new()
        .name("translation-live".into())
        .spawn(move || {
            let _worker = worker;
            let runtime = runtime;
            runtime.block_on(run(
                request,
                session.expires_at,
                id,
                payload,
                receiver,
                state,
            ));
        })
        .is_err()
    {
        registry.remove(&handle);
        return Err(error(
            "internal",
            "Could not open live translation progress.",
        ));
    }
    Ok(json!({"connection":handle}))
}

struct Worker;

impl Drop for Worker {
    fn drop(&mut self) {
        WORKERS.fetch_sub(1, Ordering::SeqCst);
    }
}

fn publish(state: &Connection, status: &str, snapshot: Value, error: Option<&str>) {
    if let Ok(mut latest) = state.latest.lock() {
        // Close wins races against a snapshot or revocation already being decoded.
        if latest["state"] == "closed" {
            return;
        }
        let sequence = latest["sequence"].as_u64().unwrap_or(0).saturating_add(1);
        *latest = json!({"sequence":sequence,"state":status,"snapshot":snapshot});
        if let Some(error) = error {
            latest["error"] = json!(error);
        }
        state.changed.notify_all();
    }
}

fn unavailable(state: &Connection, reason: Option<&str>) {
    let reason =
        reason.filter(|reason| matches!(*reason, "sign_in_required" | "forbidden" | "not_found"));
    publish(
        state,
        if reason == Some("sign_in_required") {
            "needs_session"
        } else {
            "unavailable"
        },
        Value::Null,
        reason,
    );
}

async fn run(
    request: Request<()>,
    expires_at: u64,
    id: String,
    payload: Value,
    mut closed: watch::Receiver<bool>,
    state: Arc<Connection>,
) {
    // One cancellation boundary covers connect, backoff, every send and receive.
    // Dropping the socket is intentional: close never waits on a network peer.
    tokio::select! {
        biased;
        _ = async {
            while !*closed.borrow_and_update() {
                if closed.changed().await.is_err() { break; }
            }
        } => {},
        _ = async {
            while now() < expires_at {
                tokio::time::sleep(Duration::from_secs(expires_at.saturating_sub(now()).min(86400))).await;
            }
        } => unavailable(&state, Some("sign_in_required")),
        _ = reconnect(request, &id, payload, &state) => {},
    }
}

async fn reconnect(request: Request<()>, id: &str, payload: Value, state: &Connection) {
    let topic = format!("translation:{id}");
    let mut backoff = 1;
    loop {
        let config = WebSocketConfig::default()
            .max_message_size(Some(MAX_MESSAGE))
            .max_frame_size(Some(MAX_MESSAGE))
            .max_write_buffer_size(MAX_MESSAGE);
        let connected = timeout(
            Duration::from_secs(10),
            tokio_tungstenite::connect_async_with_config(request.clone(), Some(config), true),
        )
        .await;
        match connected {
            Ok(Ok((mut socket, response))) => {
                if response
                    .headers()
                    .get("Sec-WebSocket-Protocol")
                    .and_then(|v| v.to_str().ok())
                    != Some("phoenix")
                {
                    unavailable(state, None);
                    return;
                }
                if send(&mut socket, json!(["1", "1", topic, "phx_join", payload])).await {
                    let mut joined = false;
                    let join_deadline = Instant::now() + Duration::from_secs(10);
                    let mut last_received = Instant::now();
                    let mut heartbeat = tokio::time::interval(Duration::from_secs(10));
                    heartbeat.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
                    heartbeat.tick().await;
                    let mut reference = 1_u64;
                    loop {
                        tokio::select! {
                            _ = tokio::time::sleep_until(join_deadline), if !joined => break,
                            _ = tokio::time::sleep_until(last_received + Duration::from_secs(30)) => break,
                            _ = heartbeat.tick() => {
                                reference = reference.wrapping_add(1);
                                if !send(&mut socket, json!([null,reference.to_string(),"phoenix","heartbeat",{}])).await {
                                    break;
                                }
                            }
                            message = socket.next() => {
                                let Some(Ok(message)) = message else { break; };
                                last_received = Instant::now();
                                let Message::Text(text) = message else {
                                    if matches!(message, Message::Close(_) | Message::Binary(_)) { break; }
                                    continue;
                                };
                                let Ok(frame) = serde_json::from_str::<Value>(&text) else { break; };
                                let Some(frame) = frame.as_array().filter(|frame| frame.len() == 5) else { break; };
                                if !frame[0].is_null() && !frame[0].is_string()
                                    || !frame[1].is_null() && !frame[1].is_string()
                                    || !frame[2].is_string() || !frame[3].is_string() || !frame[4].is_object()
                                { break; }
                                if frame[2] != topic || !(frame[0].is_null() || frame[0] == "1") { continue; }
                                if frame[3] == "access_revoked" {
                                    unavailable(state, frame[4]["reason"].as_str());
                                    return;
                                }
                                if frame[3] == "error" {
                                    unavailable(state, None);
                                    return;
                                }
                                let snapshot = if frame[3] == "phx_reply" && frame[0] == "1" && frame[1] == "1" && !joined {
                                    if frame[4]["status"] != "ok" {
                                        unavailable(state, frame[4]["response"]["reason"].as_str());
                                        return;
                                    }
                                    joined = true;
                                    &frame[4]["response"]
                                } else if frame[3] == "snapshot" && joined {
                                    &frame[4]
                                } else if frame[3] == "phx_close" || frame[3] == "phx_error" { break; }
                                else { continue; };
                                let Ok(snapshot) = sanitize(snapshot.clone(), id) else { break; };
                                // Durable progress.seq can stay unchanged across status/turn
                                // updates. Delivery always gets its own increasing sequence.
                                publish(state, "live", snapshot, None);
                                backoff = 1;
                            }
                        }
                    }
                }
            }
            Ok(Err(SocketError::Http(response))) => {
                let reason = match response.status().as_u16() {
                    401 => Some("sign_in_required"),
                    403 => Some("forbidden"),
                    404 => Some("not_found"),
                    _ => None,
                };
                if reason.is_some() {
                    unavailable(state, reason);
                    return;
                }
            }
            _ => {}
        }
        publish(state, "reconnecting", Value::Null, None);
        tokio::time::sleep(Duration::from_secs(backoff)).await;
        backoff = (backoff * 2).min(30);
    }
}

async fn send<S>(socket: &mut tokio_tungstenite::WebSocketStream<S>, value: Value) -> bool
where
    S: tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin,
{
    matches!(
        timeout(
            Duration::from_secs(5),
            socket.send(Message::Text(value.to_string().into()))
        )
        .await,
        Ok(Ok(()))
    )
}

// Mirror TranslationSnapshot's public projection, not the internal progress fold.
// Like Atlas, decode and re-encode the allowlist so raw output/provider fields
// accidentally added by a server can never cross the native bridge.
#[derive(Deserialize, Serialize)]
struct Snapshot {
    session: SessionProjection,
    progress: Progress,
}

#[derive(Deserialize, Serialize)]
struct SessionProjection {
    id: String,
    status: String,
    commit_sha: Option<String>,
    commit_message: Option<String>,
    source_language: Option<String>,
    target_languages: Vec<String>,
    translated_content_count: u64,
    inserted_at: String,
    summary: Option<String>,
}

#[derive(Deserialize, Serialize)]
struct Progress {
    seq: u64,
    summary: Summary,
    items: Vec<Item>,
    omitted_items: u64,
}

#[derive(Deserialize, Serialize)]
struct Summary {
    total: u64,
    checked: u64,
    needs_translation: u64,
    #[serde(rename = "assessed?")]
    assessed: bool,
    skipped: u64,
    done: u64,
    failed: u64,
    cancelled: u64,
    running: u64,
    queued: u64,
    #[serde(default)]
    awaiting_input: u64,
    glossary: Glossary,
}

#[derive(Deserialize, Serialize)]
struct Glossary {
    applied_ids: Vec<String>,
    shadowed_ids: Vec<String>,
    files_with_applied: u64,
    files_with_shadowed: u64,
}

#[derive(Deserialize, Serialize)]
struct Item {
    index: u64,
    output_path: Option<String>,
    locale: Option<String>,
    status: String,
    turns: u64,
    file_ref: Option<String>,
}

fn sanitize(value: Value, id: &str) -> Result<Value> {
    let snapshot: Snapshot = serde_json::from_value(value).map_err(|_| invalid())?;
    if snapshot.session.id != id
        || !matches!(
            snapshot.session.status.as_str(),
            "pending" | "running" | "awaiting_input" | "completed" | "failed" | "cancelled"
        )
        || snapshot.progress.items.len() > 500
    {
        return Err(invalid());
    }
    let mut indexes = std::collections::HashSet::new();
    for item in &snapshot.progress.items {
        if !indexes.insert(item.index)
            || !matches!(
                item.status.as_str(),
                "queued" | "running" | "awaiting_input" | "done" | "failed" | "cancelled"
            )
        {
            return Err(invalid());
        }
    }
    serde_json::to_value(snapshot).map_err(|_| invalid())
}

#[cfg(test)]
#[path = "translation_live_tests.rs"]
mod tests;
