use super::*;
use std::cell::RefCell;
use std::io::Read;
use std::net::{TcpListener, TcpStream};
use std::sync::{MutexGuard, mpsc};
use tokio_tungstenite::tungstenite::{WebSocket, accept_hdr};
use url::Url;

const ID: &str = "019a19fe-6c00-7000-8000-0123456789ac";
const OTHER: &str = "019a19fe-6c00-7000-8000-0123456789ab";
static TESTS: Mutex<()> = Mutex::new(());
thread_local! {
    static ENDPOINT: RefCell<Option<Url>> = const { RefCell::new(None) };
}

// This seam is compiled out of shipped libraries. It still exercises registration
// validation and the exact production JSON bridge and Phoenix client handshake.
pub(super) fn endpoint(url: Url) -> Url {
    assert_eq!(url.scheme(), "wss");
    assert_eq!(url.path(), "/native/socket/websocket");
    assert_eq!(url.query(), Some("vsn=2.0.0"));
    ENDPOINT.with(|endpoint| endpoint.borrow().clone().unwrap_or(url))
}

fn isolated() -> MutexGuard<'static, ()> {
    let guard = TESTS.lock().unwrap_or_else(|error| error.into_inner());
    drained();
    assert!(connections().lock().unwrap().is_empty());
    ENDPOINT.with(|endpoint| *endpoint.borrow_mut() = None);
    guard
}

fn drained() {
    let deadline = std::time::Instant::now() + Duration::from_secs(3);
    while WORKERS.load(Ordering::SeqCst) != 0 {
        assert!(std::time::Instant::now() < deadline, "live worker leaked");
        std::thread::sleep(Duration::from_millis(2));
    }
}

fn listener() -> TcpListener {
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    let url = Url::parse(&format!(
        "ws://{}/native/socket/websocket?vsn=2.0.0",
        listener.local_addr().unwrap()
    ))
    .unwrap();
    ENDPOINT.with(|endpoint| *endpoint.borrow_mut() = Some(url));
    listener
}

fn command(mut request: Value) -> Value {
    request["operation"] = json!("translation_live");
    serde_json::from_str(&crate::bridge::execute(&request.to_string())).unwrap()
}

fn ok(request: Value) -> Value {
    let value = command(request);
    assert!(value.get("error").is_none(), "{value}");
    value["ok"].clone()
}

fn open_command() -> Value {
    json!({"action":"open","id":ID.to_uppercase(),
        "selection":{"organization":"team","project":"42-mobile"},
        "session":{"registration":{"server":"https://glossia.example/",
            "authorization_endpoint":"https://glossia.example/oauth/authorize",
            "token_endpoint":"https://glossia.example/oauth/token","client_id":"native"},
            "access_token":"private-token+/=","refresh_token":"private-refresh","expires_at":now()+3600}})
}

struct Handle(String);

impl Handle {
    fn open() -> Self {
        Self::from_command(open_command())
    }

    fn from_command(command: Value) -> Self {
        let value = ok(command);
        assert_eq!(value.as_object().unwrap().len(), 1);
        Self(value["connection"].as_str().unwrap().to_owned())
    }

    fn next(&self, after: u64) -> Value {
        next(&self.0, after)
    }

    fn state(&self, status: &str, mut after: u64) -> Value {
        let deadline = std::time::Instant::now() + Duration::from_secs(5);
        loop {
            let value = self.next(after);
            if value["state"] == status {
                return value;
            }
            assert!(std::time::Instant::now() < deadline, "{value}");
            after = sequence(&value);
        }
    }
}

impl Drop for Handle {
    fn drop(&mut self) {
        assert_eq!(
            ok(json!({"action":"close","connection":self.0})),
            json!({"closed":true})
        );
    }
}

fn next(id: &str, after: u64) -> Value {
    ok(json!({"action":"next","connection":id,"after":after}))
}

fn sequence(value: &Value) -> u64 {
    value["sequence"].as_u64().unwrap()
}

fn snapshot(status: &str, seq: u64) -> Value {
    json!({"session":{"id":ID,"status":status,"commit_sha":null,"commit_message":"Translate",
        "source_language":"en","target_languages":["es"],"translated_content_count":0,
        "inserted_at":"2026-10-25T00:00:00Z","summary":null},
        "progress":{"seq":seq,"summary":{"total":1,"checked":1,"needs_translation":1,
            "assessed?":true,"skipped":0,"done":0,"failed":0,"cancelled":0,"running":1,"queued":0,
            "glossary":{"applied_ids":[],"shadowed_ids":[],"files_with_applied":0,"files_with_shadowed":0}},
            "items":[{"index":1,"output_path":"es.md","locale":"es","status":"running",
                "turns":1,"file_ref":null}],"omitted_items":0}})
}

#[allow(clippy::result_large_err)] // Tungstenite's handshake callback fixes this type.
fn accept(listener: &TcpListener) -> WebSocket<TcpStream> {
    let (stream, _) = listener.accept().unwrap();
    stream
        .set_read_timeout(Some(Duration::from_secs(5)))
        .unwrap();
    stream
        .set_write_timeout(Some(Duration::from_secs(5)))
        .unwrap();
    let mut socket = accept_hdr(
        stream,
        |request: &tokio_tungstenite::tungstenite::handshake::server::Request,
         mut response: tokio_tungstenite::tungstenite::handshake::server::Response| {
            assert_eq!(request.uri(), "/native/socket/websocket?vsn=2.0.0");
            assert_eq!(
                request.headers()["Sec-WebSocket-Protocol"],
                "phoenix, base64url.bearer.phx.cHJpdmF0ZS10b2tlbisvPQ"
            );
            assert!(request.headers().get("Authorization").is_none());
            assert!(request.headers().get("Cookie").is_none());
            response
                .headers_mut()
                .insert("Sec-WebSocket-Protocol", "phoenix".parse().unwrap());
            Ok(response)
        },
    )
    .unwrap();
    let join = receive(&mut socket);
    assert_eq!(
        join,
        json!(["1","1",format!("translation:{ID}"),"phx_join",{"organization":"team","project":"42-mobile"}])
    );
    socket
}

fn receive(socket: &mut WebSocket<TcpStream>) -> Value {
    serde_json::from_str(socket.read().unwrap().to_text().unwrap()).unwrap()
}

fn send(socket: &mut WebSocket<TcpStream>, value: Value) {
    socket
        .send(Message::Text(value.to_string().into()))
        .unwrap();
}

fn reply(socket: &mut WebSocket<TcpStream>, value: Value) {
    send(
        socket,
        json!(["1","1",format!("translation:{ID}"),"phx_reply",{"status":"ok","response":value}]),
    );
}

fn push(socket: &mut WebSocket<TcpStream>, value: Value) {
    // Phoenix fastlane broadcasts may have null join references.
    send(
        socket,
        json!([null, null, format!("translation:{ID}"), "snapshot", value]),
    );
}

fn wait_sequence(handle: &Handle, minimum: u64) {
    let state = connections().lock().unwrap()[&handle.0].clone();
    let latest = state.latest.lock().unwrap();
    let (latest, _) = state
        .changed
        .wait_timeout_while(latest, Duration::from_secs(5), |latest| {
            sequence(latest) < minimum
        })
        .unwrap();
    assert!(sequence(&latest) >= minimum, "{latest}");
}

#[test]
fn bridge_handshake_join_unsolicited_status_and_latest_only_coalescing() {
    let _guard = isolated();
    let listener = listener();
    let (commands, events) = mpsc::channel();
    let server = std::thread::spawn(move || {
        let mut socket = accept(&listener);
        let mut initial = snapshot("running", 7);
        initial["token"] = json!("must-not-forward");
        initial["progress"]["items"][0]["text"] = json!("must-not-forward");
        initial["progress"]["items"][0]["provider"] = json!({"secret":"must-not-forward"});
        reply(&mut socket, initial);
        events.recv_timeout(Duration::from_secs(5)).unwrap();
        push(&mut socket, snapshot("completed", 7));
        events.recv_timeout(Duration::from_secs(5)).unwrap();
        for index in 0..100 {
            let mut value = snapshot("completed", 7);
            value["progress"]["items"][0]["turns"] = json!(index + 1);
            push(&mut socket, value);
        }
        events.recv_timeout(Duration::from_secs(5)).unwrap();
        // next() sent no network traffic; only close terminates the persistent socket.
        assert!(socket.read().is_err());
    });
    let handle = Handle::open();
    let first = handle.state("live", 0);
    assert_eq!(first["snapshot"], snapshot("running", 7));
    commands.send(()).unwrap();
    let changed = handle.next(sequence(&first));
    assert_eq!(changed["state"], "live");
    assert_eq!(changed["snapshot"], snapshot("completed", 7));
    assert!(sequence(&changed) > sequence(&first));
    commands.send(()).unwrap();
    wait_sequence(&handle, sequence(&changed) + 100);
    let latest = handle.next(sequence(&changed));
    assert_eq!(latest["snapshot"]["progress"]["seq"], 7);
    assert_eq!(latest["snapshot"]["progress"]["items"][0]["turns"], 100);
    assert_eq!(sequence(&latest), sequence(&changed) + 100);
    drop(handle);
    commands.send(()).unwrap();
    server.join().unwrap();
    drained();
}

#[test]
fn malformed_foreign_identity_and_oversized_snapshots_never_reach_the_bridge() {
    let _guard = isolated();
    let mut malformed = Vec::new();
    let mut foreign = snapshot("running", 7);
    foreign["session"]["id"] = json!(OTHER);
    malformed.push(foreign);
    for (path, bad) in [
        ("/progress/items", json!({})),
        ("/progress/seq", json!(-1)),
        ("/progress/omitted_items", json!(-1)),
        ("/progress/summary/done", json!("one")),
        ("/progress/summary/glossary/applied_ids", json!([7])),
        ("/progress/items/0/turns", json!(null)),
        ("/progress/items/0/status", json!("secret")),
        ("/session/target_languages", json!([7])),
    ] {
        let mut value = snapshot("running", 7);
        *value.pointer_mut(path).unwrap() = bad;
        malformed.push(value);
    }
    let mut huge = snapshot("running", 7);
    huge["progress"]["items"][0]["text"] = json!("x".repeat(MAX_MESSAGE));
    malformed.push(huge);
    let mut duplicate = snapshot("running", 7);
    let item = duplicate["progress"]["items"][0].clone();
    duplicate["progress"]["items"]
        .as_array_mut()
        .unwrap()
        .push(item);
    malformed.push(duplicate);
    let mut too_many = snapshot("running", 7);
    too_many["progress"]["items"] = json!(
        (0..501)
            .map(|index| {
                let mut item = snapshot("running", 7)["progress"]["items"][0].clone();
                item["index"] = json!(index);
                item
            })
            .collect::<Vec<_>>()
    );
    malformed.push(too_many);
    for bad in malformed {
        let listener = listener();
        let (commands, events) = mpsc::channel();
        let server = std::thread::spawn(move || {
            let mut socket = accept(&listener);
            // A foreign topic, and an old join reference on our topic, are ignored.
            send(
                &mut socket,
                json!([
                    "1",
                    null,
                    format!("translation:{OTHER}"),
                    "snapshot",
                    snapshot("failed", 900)
                ]),
            );
            send(
                &mut socket,
                json!(["9",null,format!("translation:{ID}"),"access_revoked",{"reason":"forbidden"}]),
            );
            push(&mut socket, snapshot("failed", 900)); // No snapshots before phx_join succeeds.
            reply(&mut socket, snapshot("running", 7));
            events.recv_timeout(Duration::from_secs(5)).unwrap();
            if bad.to_string().len() > MAX_MESSAGE {
                // The client rejects the frame header without waiting for the
                // entire oversized body, so this write can race its TCP close.
                match socket.send(Message::Text(
                    json!([null, null, format!("translation:{ID}"), "snapshot", bad])
                        .to_string()
                        .into(),
                )) {
                    Ok(()) => {}
                    Err(SocketError::Io(error)) => assert!(matches!(
                        error.kind(),
                        std::io::ErrorKind::BrokenPipe | std::io::ErrorKind::ConnectionReset
                    )),
                    Err(error) => panic!("unexpected oversized write error: {error}"),
                }
            } else {
                push(&mut socket, bad);
            }
            events.recv_timeout(Duration::from_secs(5)).unwrap();
        });
        let handle = Handle::open();
        let initial = handle.state("live", 0);
        assert_eq!(sequence(&initial), 2);
        commands.send(()).unwrap();
        let invalid = handle.next(sequence(&initial));
        assert_eq!(invalid["state"], "reconnecting");
        assert!(invalid["snapshot"].is_null());
        drop(handle);
        commands.send(()).unwrap();
        server.join().unwrap();
        drained();
    }
}

#[test]
fn revocation_and_join_denial_are_terminal_clear_private_snapshots_and_do_not_retry() {
    let _guard = isolated();
    for denial in [false, true] {
        for reason in [
            "sign_in_required",
            "forbidden",
            "not_found",
            "payload_too_large",
        ] {
            let listener = listener();
            let (commands, events) = mpsc::channel();
            let server = std::thread::spawn(move || {
                let mut socket = accept(&listener);
                if denial {
                    send(
                        &mut socket,
                        json!(["1","1",format!("translation:{ID}"),"phx_reply",{"status":"error","response":{"reason":reason}}]),
                    );
                } else {
                    reply(&mut socket, snapshot("running", 7));
                    events.recv_timeout(Duration::from_secs(5)).unwrap();
                    let event = if reason == "payload_too_large" {
                        "error"
                    } else {
                        "access_revoked"
                    };
                    send(
                        &mut socket,
                        json!(["1",null,format!("translation:{ID}"),event,{"reason":reason}]),
                    );
                }
                events.recv_timeout(Duration::from_secs(5)).unwrap();
                listener.set_nonblocking(true).unwrap();
                assert_eq!(
                    listener.accept().unwrap_err().kind(),
                    std::io::ErrorKind::WouldBlock
                );
            });
            let handle = Handle::open();
            let after = if denial {
                0
            } else {
                let live = handle.state("live", 0);
                commands.send(()).unwrap();
                sequence(&live)
            };
            let expected = if reason == "sign_in_required" {
                "needs_session"
            } else {
                "unavailable"
            };
            let revoked = handle.state(expected, after);
            assert!(revoked["snapshot"].is_null());
            if reason == "payload_too_large" {
                assert!(revoked.get("error").is_none());
            } else {
                assert_eq!(revoked["error"], reason);
            }
            drained();
            let start = std::time::Instant::now();
            assert_eq!(handle.next(sequence(&revoked)), revoked);
            assert!(start.elapsed() < Duration::from_millis(100));
            drop(handle);
            commands.send(()).unwrap();
            server.join().unwrap();
        }
    }
}

#[test]
fn reconnect_rejoins_and_close_wakes_an_already_blocked_local_waiter() {
    let _guard = isolated();
    let listener = listener();
    let (commands, events) = mpsc::channel();
    let server = std::thread::spawn(move || {
        let mut socket = accept(&listener);
        reply(&mut socket, snapshot("running", 7));
        events.recv_timeout(Duration::from_secs(5)).unwrap();
        drop(socket);
        let mut socket = accept(&listener);
        reply(&mut socket, snapshot("completed", 7));
        events.recv_timeout(Duration::from_secs(5)).unwrap();
        assert!(socket.read().is_err());
    });
    let handle = Handle::open();
    let first = handle.state("live", 0);
    commands.send(()).unwrap();
    let disconnected = handle.next(sequence(&first));
    assert_eq!(disconnected["state"], "reconnecting");
    let reconnected = handle.state("live", sequence(&disconnected));
    assert_eq!(reconnected["snapshot"], snapshot("completed", 7));
    let state = connections().lock().unwrap()[&handle.0].clone();
    let references = Arc::strong_count(&state);
    let id = handle.0.clone();
    let after = sequence(&reconnected);
    let (done, finished) = mpsc::channel();
    let waiter = std::thread::spawn(move || done.send(next(&id, after)).unwrap());
    let deadline = std::time::Instant::now() + Duration::from_secs(2);
    while Arc::strong_count(&state) <= references {
        assert!(std::time::Instant::now() < deadline);
        std::thread::sleep(Duration::from_millis(1));
    }
    let id = handle.0.clone();
    drop(handle);
    let closed = finished.recv_timeout(Duration::from_secs(1)).unwrap();
    assert_eq!(
        closed,
        json!({"sequence":after+1,"state":"closed","snapshot":null})
    );
    waiter.join().unwrap();
    assert!(!connections().lock().unwrap().contains_key(&id));
    assert_eq!(next(&id, after)["state"], "closed");
    assert_eq!(
        ok(json!({"action":"close","connection":id})),
        json!({"closed":true})
    );
    commands.send(()).unwrap();
    server.join().unwrap();
    drained();
}

#[test]
fn close_cancels_an_incomplete_handshake_and_network_backoff_promptly() {
    let _guard = isolated();
    let listener = listener();
    let (ready, started) = mpsc::channel();
    let (commands, events) = mpsc::channel();
    let server = std::thread::spawn(move || {
        let (mut stream, _) = listener.accept().unwrap();
        stream
            .set_read_timeout(Some(Duration::from_secs(5)))
            .unwrap();
        let mut bytes = [0; 4096];
        assert!(stream.read(&mut bytes).unwrap() > 0);
        ready.send(()).unwrap();
        events.recv_timeout(Duration::from_secs(5)).unwrap();
        assert_eq!(stream.read(&mut bytes).unwrap(), 0);
    });
    let handle = Handle::open();
    started.recv_timeout(Duration::from_secs(5)).unwrap();
    let start = std::time::Instant::now();
    drop(handle);
    drained();
    assert!(start.elapsed() < Duration::from_secs(1));
    commands.send(()).unwrap();
    server.join().unwrap();

    let listener = self::listener();
    drop(listener); // Refused connection enters the exponential retry delay.
    let handle = Handle::open();
    handle.state("reconnecting", 0);
    let start = std::time::Instant::now();
    drop(handle);
    drained();
    assert!(start.elapsed() < Duration::from_secs(1));
}

#[test]
fn registry_and_workers_are_bounded_and_handles_are_reclaimed_on_close() {
    let _guard = isolated();
    let _listener = listener(); // Keep all clients in the incomplete handshake.
    let handles: Vec<_> = (0..MAX_CONNECTIONS).map(|_| Handle::open()).collect();
    assert_eq!(connections().lock().unwrap().len(), MAX_CONNECTIONS);
    assert_eq!(WORKERS.load(Ordering::SeqCst), MAX_CONNECTIONS);
    let overflow = command(open_command());
    assert_eq!(overflow["error"]["kind"], "internal");
    assert!(overflow["ok"].is_null());
    drop(handles);
    drained();
    assert!(connections().lock().unwrap().is_empty());
    let handle = Handle::open();
    drop(handle);
    drained();
}

#[test]
fn open_validates_credentials_registration_uuid_and_exact_workspace_handles() {
    let _guard = isolated();
    for (path, value) in [
        ("/session/registration/server", json!("http://127.0.0.1")),
        (
            "/session/registration/token_endpoint",
            json!("https://attacker.example/oauth/token"),
        ),
        ("/session/registration/client_id", json!("")),
        ("/session/expires_at", json!(0)),
        ("/session/access_token", json!("")),
        ("/id", json!("../other")),
        ("/selection/organization", json!("team/name")),
        ("/selection/organization", json!("42-team")),
        ("/selection/project", json!("mobile name")),
        ("/selection/project", json!("mobile-")),
        ("/selection/project", json!("m".repeat(40))),
    ] {
        let mut request = open_command();
        *request.pointer_mut(path).unwrap() = value;
        let result = command(request);
        assert!(result["error"].is_object());
        assert!(!result.to_string().contains("private-"));
    }
    for after in [json!(-1), json!(1.5), json!("1")] {
        assert!(
            command(json!({"action":"next","connection":"missing","after":after}))["error"]
                .is_object()
        );
    }
    assert_eq!(
        ok(json!({"action":"close","connection":"missing"})),
        json!({"closed":true})
    );
    assert!(connections().lock().unwrap().is_empty());
    assert_eq!(WORKERS.load(Ordering::SeqCst), 0);
}

#[test]
fn credential_expiry_cancels_even_an_incomplete_handshake() {
    let _guard = isolated();
    let _listener = listener();
    let mut request = open_command();
    request["session"]["expires_at"] = json!(now() + 1);
    let handle = Handle::from_command(request);
    let expired = handle.state("needs_session", 0);
    assert_eq!(expired["error"], "sign_in_required");
    assert!(expired["snapshot"].is_null());
    drained();
    drop(handle);
}

#[test]
fn heartbeats_do_not_replace_snapshots_and_a_silent_peer_reconnects_after_thirty_seconds() {
    let _guard = isolated();
    let listener = listener();
    let (commands, events) = mpsc::channel();
    let (ready, started) = mpsc::channel();
    let server = std::thread::spawn(move || {
        let mut socket = accept(&listener);
        socket
            .get_mut()
            .set_read_timeout(Some(Duration::from_secs(15)))
            .unwrap();
        reply(&mut socket, snapshot("running", 7));
        let first = receive(&mut socket);
        assert_eq!(first, json!([null, "2", "phoenix", "heartbeat", {}]));
        let second = receive(&mut socket);
        assert_eq!(second, json!([null, "3", "phoenix", "heartbeat", {}]));
        ready.send(()).unwrap();
        // No heartbeat replies or other received messages, so the client reconnects.
        let mut socket = accept(&listener);
        reply(&mut socket, snapshot("completed", 7));
        events.recv_timeout(Duration::from_secs(5)).unwrap();
        assert!(socket.read().is_err());
    });
    let handle = Handle::open();
    let first = handle.state("live", 0);
    started.recv_timeout(Duration::from_secs(25)).unwrap();
    let current = handle.next(0);
    assert_eq!(
        current, first,
        "heartbeat must not publish a partial projection"
    );
    let disconnected = handle.next(sequence(&first));
    assert_eq!(disconnected["state"], "reconnecting");
    let reconnected = handle.state("live", sequence(&disconnected));
    assert_eq!(reconnected["snapshot"], snapshot("completed", 7));
    drop(handle);
    commands.send(()).unwrap();
    server.join().unwrap();
    drained();
}
