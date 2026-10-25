use crate::{AuthError, Result, error, invalid};
use reqwest::blocking::{Client, Response};
use serde::de::DeserializeOwned;
use serde_json::Value;
use std::io::Read;
use std::sync::OnceLock;
use std::time::Duration;
use url::Url;

pub(crate) enum Body<'a> {
    Get,
    Public {
        failure: fn(u16, &[u8]) -> AuthError,
    },
    Json(Value),
    Form(Vec<(&'a str, &'a str)>),
    Api(&'a str),
    ApiJson(&'a str, Value),
    ApiPut(&'a str, Value),
    Push {
        method: reqwest::Method,
        token: &'a str,
        payload: Option<Value>,
        failure: fn(u16, &[u8]) -> AuthError,
    },
}

pub(crate) trait Transport {
    fn request<T: DeserializeOwned>(&self, url: &Url, body: Body<'_>) -> Result<T>;
}

pub(crate) struct Network;

impl Transport for Network {
    fn request<T: DeserializeOwned>(&self, url: &Url, body: Body<'_>) -> Result<T> {
        let client = client()?;
        let api = matches!(
            &body,
            Body::Api(_) | Body::ApiJson(_, _) | Body::ApiPut(_, _) | Body::Push { .. }
        );
        let failure = match &body {
            Body::Public { failure } | Body::Push { failure, .. } => Some(*failure),
            _ => None,
        };
        let request = match body {
            Body::Get | Body::Public { .. } => client.get(url.clone()),
            Body::Json(value) => client.post(url.clone()).json(&value),
            Body::Form(pairs) => client.post(url.clone()).form(&pairs),
            Body::Api(token) => client.get(url.clone()).bearer_auth(token),
            Body::ApiJson(token, value) => client.post(url.clone()).bearer_auth(token).json(&value),
            Body::ApiPut(token, value) => client.put(url.clone()).bearer_auth(token).json(&value),
            Body::Push {
                method,
                token,
                payload,
                ..
            } => {
                let request = client.request(method, url.clone()).bearer_auth(token);
                if let Some(payload) = payload {
                    request.json(&payload)
                } else {
                    request
                }
            }
        };
        response(
            request
                .header("accept", "application/json")
                .header("cache-control", "no-store")
                .send(),
            api,
            failure,
        )
    }
}

fn client() -> Result<&'static Client> {
    static CLIENT: OnceLock<Client> = OnceLock::new();
    if let Some(client) = CLIENT.get() {
        return Ok(client);
    }
    let client = Client::builder()
        .redirect(reqwest::redirect::Policy::none())
        .timeout(Duration::from_secs(30))
        .connect_timeout(Duration::from_secs(10))
        .user_agent("GlossiaMobile/0.1")
        .build()
        .map_err(|_| error("network", "Could not initialize secure networking."))?;
    let _ = CLIENT.set(client);
    Ok(CLIENT.get().expect("client initialized"))
}

fn response<T: DeserializeOwned>(
    response: reqwest::Result<Response>,
    api: bool,
    failure: Option<fn(u16, &[u8]) -> AuthError>,
) -> Result<T> {
    let response = response.map_err(|_| error("network", "Could not reach Glossia. Try again."))?;
    let status = response.status();
    // A complete 100-message conversation can exceed 1 MiB after JSON escaping.
    // Keep OAuth responses smaller while allowing the server's bounded history.
    let max_bytes = if api { 8 * 1024 * 1024 } else { 1024 * 1024 };
    let mut bytes = Vec::new();
    response
        .take((max_bytes + 1) as u64)
        .read_to_end(&mut bytes)
        .map_err(|_| invalid())?;
    if bytes.len() > max_bytes {
        return Err(invalid());
    }
    if !status.is_success() {
        if let Some(failure) = failure {
            return Err(failure(status.as_u16(), &bytes));
        }
        return Err(if api {
            match status.as_u16() {
                401 => error("sign_in_required", "Your session expired. Sign in again."),
                403 => error("forbidden", "You do not have access to this workspace."),
                404 => error("not_found", "Nothing has been configured here yet."),
                _ => error("server", "Glossia could not load this data. Try again."),
            }
        } else {
            response_failure(status.as_u16(), &bytes)
        });
    }
    serde_json::from_slice(&bytes).map_err(|_| invalid())
}

pub(super) fn response_failure(status: u16, bytes: &[u8]) -> AuthError {
    let body = serde_json::from_slice::<Value>(bytes).ok();
    if matches!(status, 400 | 401)
        && matches!(
            body.as_ref().and_then(|body| body["error"].as_str()),
            Some("invalid_grant" | "invalid_client" | "unauthorized_client")
        )
    {
        error(
            "rejected",
            "Glossia rejected these credentials. Sign in again.",
        )
    } else {
        error("server", "Glossia could not complete sign-in. Try again.")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::io::{BufRead, BufReader, Write};
    use std::net::TcpListener;
    use std::thread::{self, JoinHandle};

    fn serve(status: u16, body: String) -> (Url, JoinHandle<String>) {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let url = Url::parse(&format!("http://{}/fixed", listener.local_addr().unwrap())).unwrap();
        let worker = thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            stream
                .set_read_timeout(Some(Duration::from_secs(5)))
                .unwrap();
            stream
                .set_write_timeout(Some(Duration::from_secs(5)))
                .unwrap();
            let mut reader = BufReader::new(&mut stream);
            let mut request = String::new();
            let mut length = 0;
            loop {
                let mut line = String::new();
                assert_ne!(reader.read_line(&mut line).unwrap(), 0);
                request.push_str(&line);
                if line == "\r\n" {
                    break;
                }
                if let Some((name, value)) = line.split_once(':')
                    && name.eq_ignore_ascii_case("content-length")
                {
                    length = value.trim().parse::<usize>().unwrap();
                }
            }
            let mut bytes = vec![0; length];
            reader.read_exact(&mut bytes).unwrap();
            request.push_str(std::str::from_utf8(&bytes).unwrap());
            stream.write_all(format!(
                "HTTP/1.1 {status} Mock\r\ncontent-type: application/json\r\ncontent-length: {}\r\nconnection: close\r\n\r\n{body}", body.len()
            ).as_bytes()).unwrap();
            request
        });
        (url, worker)
    }

    #[test]
    fn push_puts_and_deletes_use_real_bearer_transport_without_redirects_or_error_body_leaks() {
        for method in [reqwest::Method::PUT, reqwest::Method::DELETE] {
            for status in [200, 302, 401, 403, 404, 503] {
                let payload =
                    (method == reqwest::Method::PUT).then(|| json!({"token":"provider-token"}));
                let (url, worker) = serve(
                    status,
                    json!({"deleted":true,"private":"never-echo"}).to_string(),
                );
                let result: Result<Value> = Network.request(
                    &url,
                    Body::Push {
                        method: method.clone(),
                        token: "access",
                        payload: payload.clone(),
                        failure: |_, _| error("push_unavailable", "Push unavailable."),
                    },
                );
                let request = worker.join().unwrap();
                assert!(request.starts_with(&format!("{method} /fixed HTTP/1.1\r\n")));
                let (headers, body) = request.split_once("\r\n\r\n").unwrap();
                assert!(
                    headers
                        .to_ascii_lowercase()
                        .contains("authorization: bearer access")
                );
                assert!(
                    headers
                        .to_ascii_lowercase()
                        .contains("cache-control: no-store")
                );
                if let Some(payload) = payload {
                    assert_eq!(serde_json::from_str::<Value>(body).unwrap(), payload);
                } else {
                    assert!(body.is_empty());
                }
                if status == 200 {
                    assert_eq!(result.unwrap()["deleted"], true);
                } else {
                    let failure = result.unwrap_err();
                    assert_eq!(failure.kind, "push_unavailable");
                    assert!(
                        !serde_json::to_string(&failure)
                            .unwrap()
                            .contains("never-echo")
                    );
                }
            }
        }
    }

    #[test]
    fn bearer_json_posts_accept_202_and_use_api_errors_without_leaking_response_bodies() {
        for (status, failure) in [
            (202, None),
            (401, Some("sign_in_required")),
            (403, Some("forbidden")),
            (404, Some("not_found")),
            (409, Some("server")),
            (422, Some("server")),
            (429, Some("server")),
            (500, Some("server")),
            (302, Some("server")),
        ] {
            let body =
                json!({"conversation":{"status":"queued"},"messages":[],"secret":"must-not-echo"});
            let (url, worker) = serve(status, body.to_string());
            let payload = json!({"id":"019a19fe-6c00-7000-8000-0123456789ab","content":"Hello 🌍"});
            let result: Result<Value> =
                Network.request(&url, Body::ApiJson("access", payload.clone()));
            let request = worker.join().unwrap();
            assert!(request.starts_with("POST /fixed HTTP/1.1\r\n"));
            let (headers, sent) = request.split_once("\r\n\r\n").unwrap();
            let headers = headers.to_ascii_lowercase();
            assert!(headers.contains("\r\nauthorization: bearer access\r\n"));
            assert!(headers.contains("\r\ncontent-type: application/json\r\n"));
            assert!(headers.contains("\r\naccept: application/json\r\n"));
            assert!(headers.contains("\r\ncache-control: no-store\r\n"));
            assert_eq!(serde_json::from_str::<Value>(sent).unwrap(), payload);
            match failure {
                None => assert_eq!(result.unwrap(), body),
                Some(kind) => {
                    let failure = result.unwrap_err();
                    assert_eq!(failure.kind, kind);
                    assert!(
                        !serde_json::to_string(&failure)
                            .unwrap()
                            .contains("must-not-echo")
                    );
                }
            }
        }
    }

    #[test]
    fn translation_details_use_bearer_gets_and_conversation_origins_survive_json_posts() {
        let translation_id = "019A19FE-6C00-7000-8000-0123456789AC";
        let conversation_id = "019a19fe-6c00-7000-8000-0123456789ab";
        let detail = json!({"session":{"id":translation_id,"future_field":{"keep":true}}});
        let (mut url, worker) = serve(200, detail.to_string());
        url.path_segments_mut().unwrap().clear().extend([
            "api",
            "team",
            "projects",
            "mobile",
            "translations",
            translation_id,
        ]);
        let result: Value = Network.request(&url, Body::Api("access")).unwrap();
        let request = worker.join().unwrap();
        assert!(request.starts_with(&format!(
            "GET /api/team/projects/mobile/translations/{translation_id} HTTP/1.1\r\n"
        )));
        assert!(
            request
                .to_ascii_lowercase()
                .contains("\r\nauthorization: bearer access\r\n")
        );
        assert_eq!(result, detail);

        let detail = json!({"conversation":{"id":conversation_id,"translation_session_id":translation_id},"messages":[]});
        let (mut url, worker) = serve(202, detail.to_string());
        url.set_path("/api/team/projects/mobile/toki/conversations");
        let payload = json!({"id":conversation_id,"translation_session_id":translation_id});
        let result: Value = Network
            .request(&url, Body::ApiJson("access", payload.clone()))
            .unwrap();
        let request = worker.join().unwrap();
        assert!(
            request.starts_with("POST /api/team/projects/mobile/toki/conversations HTTP/1.1\r\n")
        );
        let (headers, sent) = request.split_once("\r\n\r\n").unwrap();
        assert!(
            headers
                .to_ascii_lowercase()
                .contains("\r\nauthorization: bearer access\r\n")
        );
        assert_eq!(serde_json::from_str::<Value>(sent).unwrap(), payload);
        assert_eq!(result, detail);
    }

    #[test]
    fn public_metadata_sends_no_credentials_and_cannot_reject_oauth_credentials() {
        for status in [200, 401, 403, 404, 302, 500] {
            let body = json!({"error":"invalid_grant"});
            let (url, worker) = serve(status, body.to_string());
            let result: Result<Value> = Network.request(
                &url,
                Body::Public {
                    failure: |_, _| error("theme_unavailable", "Theme unavailable."),
                },
            );
            let request = worker.join().unwrap().to_ascii_lowercase();
            assert!(request.starts_with("get /fixed http/1.1\r\n"));
            assert!(!request.contains("authorization:"));
            assert!(!request.contains("cookie:"));
            if status == 200 {
                assert_eq!(result.unwrap(), body);
            } else {
                assert_eq!(result.unwrap_err().kind, "theme_unavailable");
            }
        }
    }

    #[test]
    fn network_is_shareable_across_workers_and_reuses_the_same_client() {
        fn assert_thread_safe<T: Send + Sync>() {}
        assert_thread_safe::<Network>();
        let network = Network;
        thread::scope(|scope| {
            let workers: Vec<_> = (0..8)
                .map(|_| {
                    let network = &network;
                    scope.spawn(move || {
                        let (url, server) =
                            serve(200, json!({"user":{"handle":"ana"}}).to_string());
                        let result: Value = network.request(&url, Body::Api("access")).unwrap();
                        assert_eq!(result["user"]["handle"], "ana");
                        assert!(
                            server
                                .join()
                                .unwrap()
                                .starts_with("GET /fixed HTTP/1.1\r\n")
                        );
                        client().unwrap()
                    })
                })
                .collect();
            for worker in workers {
                assert!(std::ptr::eq(worker.join().unwrap(), client().unwrap()));
            }
        });
    }

    #[test]
    fn complete_bounded_chat_history_fits_the_api_response_limit() {
        let messages: Vec<_> = (0..100)
            .map(|id| json!({"id": id, "role": "assistant", "content": "\0".repeat(8000)}))
            .collect();
        let body = json!({"conversation": {"status": "completed"}, "messages": messages});
        let (url, server) = serve(200, body.to_string());
        let result: Value = Network.request(&url, Body::Api("access")).unwrap();
        server.join().unwrap();
        assert_eq!(result, body);
    }

    #[test]
    fn responses_keep_separate_api_and_oauth_size_bounds() {
        let (url, server) = serve(202, format!("\"{}\"", "a".repeat(8 * 1024 * 1024)));
        let failure = Network
            .request::<Value>(&url, Body::ApiJson("access", json!({})))
            .unwrap_err();
        server.join().unwrap();
        assert_eq!(failure.kind, "invalid_response");

        let (url, server) = serve(200, format!("\"{}\"", "a".repeat(1024 * 1024)));
        let failure = Network.request::<Value>(&url, Body::Get).unwrap_err();
        server.join().unwrap();
        assert_eq!(failure.kind, "invalid_response");
    }
}
