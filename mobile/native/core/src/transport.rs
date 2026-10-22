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
    Json(Value),
    Form(Vec<(&'a str, &'a str)>),
    Api(&'a str),
}

pub(crate) trait Transport {
    fn request<T: DeserializeOwned>(&self, url: &Url, body: Body<'_>) -> Result<T>;
}

pub(crate) struct Network;

impl Transport for Network {
    fn request<T: DeserializeOwned>(&self, url: &Url, body: Body<'_>) -> Result<T> {
        let client = client()?;
        let api = matches!(&body, Body::Api(_));
        let request = match body {
            Body::Get => client.get(url.clone()),
            Body::Json(value) => client.post(url.clone()).json(&value),
            Body::Form(pairs) => client.post(url.clone()).form(&pairs),
            Body::Api(token) => client.get(url.clone()).bearer_auth(token),
        };
        response(
            request
                .header("accept", "application/json")
                .header("cache-control", "no-store")
                .send(),
            api,
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

fn response<T: DeserializeOwned>(response: reqwest::Result<Response>, api: bool) -> Result<T> {
    let response = response.map_err(|_| error("network", "Could not reach Glossia. Try again."))?;
    let status = response.status();
    let mut bytes = Vec::new();
    response
        .take(1024 * 1024 + 1)
        .read_to_end(&mut bytes)
        .map_err(|_| invalid())?;
    if bytes.len() > 1024 * 1024 {
        return Err(invalid());
    }
    if !status.is_success() {
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
