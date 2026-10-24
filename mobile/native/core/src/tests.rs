use super::*;
use serde_json::{Value, json};
use std::cell::RefCell;
use std::collections::VecDeque;

struct NetworkFixture {
    responses: RefCell<VecDeque<Value>>,
    requests: RefCell<Vec<(Url, Value)>>,
}

impl NetworkFixture {
    fn new(responses: Vec<Value>) -> Self {
        Self {
            responses: RefCell::new(responses.into()),
            requests: RefCell::new(vec![]),
        }
    }
}

impl Transport for NetworkFixture {
    fn request<T: serde::de::DeserializeOwned>(&self, url: &Url, body: Body<'_>) -> Result<T> {
        let body = match body {
            Body::Get => Value::Null,
            Body::Api(token) => json!({"bearer": token}),
            Body::Json(value) => value,
            Body::Form(pairs) => pairs
                .into_iter()
                .map(|(key, value)| (key.to_owned(), json!(value)))
                .collect(),
        };
        self.requests.borrow_mut().push((url.clone(), body));
        serde_json::from_value(
            self.responses
                .borrow_mut()
                .pop_front()
                .expect("unexpected request"),
        )
        .map_err(|_| invalid())
    }
}

fn registration() -> Registration {
    Registration {
        server: "https://glossia.example/".into(),
        authorization_endpoint: "https://glossia.example/oauth/authorize".into(),
        token_endpoint: "https://glossia.example/oauth/token".into(),
        client_id: "registered-native-client".into(),
    }
}

fn saved_session() -> Session {
    Session {
        registration: registration(),
        access_token: "access".into(),
        refresh_token: "refresh".into(),
        expires_at: now() + 3600,
    }
}

fn discovery() -> Value {
    json!({"issuer":"https://glossia.example", "authorization_endpoint":"https://glossia.example/oauth/authorize",
        "token_endpoint":"https://glossia.example/oauth/token", "registration_endpoint":"https://glossia.example/oauth/register",
        "code_challenge_methods_supported":["S256"]})
}

#[test]
fn dynamic_public_login_exchanges_pkce_code_and_rotates_refresh_token() {
    let network = NetworkFixture::new(vec![
        discovery(),
        json!({"client_id":"dynamic-client","token_endpoint_auth_method":"none"}),
        json!({"access_token":"first", "refresh_token":"original-refresh", "token_type":"Bearer", "expires_in":3600}),
        json!({"access_token":"second", "refresh_token":"rotated-refresh", "token_type":"bearer", "expires_in":3600}),
    ]);
    let login = begin_using(&network, "https://glossia.example", None).unwrap();
    let verifier = login.pending.verifier.clone();
    let url = Url::parse(&login.authorization_url).unwrap();
    let query: std::collections::HashMap<_, _> = url.query_pairs().collect();
    assert_eq!(query["redirect_uri"], "glossia://oauth/callback");
    assert_eq!(query["code_challenge_method"], "S256");
    assert!(query["scope"].contains("organization:read"));
    let callback = format!(
        "{REDIRECT_URI}?state={}&code=a%2Bb%26c",
        login.pending.state
    );
    let mut session = complete_using(&network, login.pending, &callback).unwrap();
    session.expires_at = 0;
    let session = restore_using(&network, session).unwrap();
    assert_eq!(session.access_token, "second");
    assert_eq!(session.refresh_token, "rotated-refresh");
    assert_eq!(session.registration.client_id, "dynamic-client");
    let requests = network.requests.borrow();
    assert_eq!(requests[1].1["token_endpoint_auth_method"], "none");
    assert_eq!(
        requests[1].1["redirect_uris"],
        json!(["glossia://oauth/callback"])
    );
    assert_eq!(requests[2].1["code"], "a+b&c");
    assert_eq!(requests[2].1["code_verifier"], verifier);
    assert!(requests[2].1.get("client_secret").is_none());
    assert_eq!(requests[3].1["refresh_token"], "original-refresh");
}

#[test]
fn discovery_cannot_move_credentials_to_another_origin_or_downgrade_pkce() {
    for key in [
        "issuer",
        "authorization_endpoint",
        "token_endpoint",
        "registration_endpoint",
    ] {
        let mut response = discovery();
        response[key] = json!("https://attacker.example/oauth");
        let network = NetworkFixture::new(vec![response]);
        assert!(begin_using(&network, "https://glossia.example", None).is_err());
        assert_eq!(network.requests.borrow().len(), 1);
    }
    let mut response = discovery();
    response["code_challenge_methods_supported"] = json!(["plain"]);
    assert!(
        begin_using(
            &NetworkFixture::new(vec![response]),
            "https://glossia.example",
            None
        )
        .is_err()
    );
    for address in [
        "http://glossia.example",
        "https://user:pass@glossia.example",
        "https://glossia.example/path",
        "https://glossia.example?x=1",
    ] {
        assert!(begin(address, None).is_err());
    }
}

#[test]
fn callback_validation_rejects_wrong_destination_duplicate_state_code_and_expiry() {
    let pending = serde_json::to_value(
        begin("https://glossia.example", Some(registration()))
            .unwrap()
            .pending,
    )
    .unwrap();
    let callback = format!(
        "{REDIRECT_URI}?state={}&code=secret-code",
        pending["state"].as_str().unwrap()
    );
    for bad in [
        callback.replace("glossia:", "evil:"),
        callback.replace("oauth/", "other/"),
        callback.replace("/callback", "/other"),
        callback.replace("oauth/", "oauth:443/"),
        format!("{callback}&state=other"),
        format!("{callback}&code=other"),
        format!("{callback}&error=access_denied"),
    ] {
        let response: Value = serde_json::from_str(&bridge::execute(
            &json!({"operation":"complete","pending":pending,"callback":bad}).to_string(),
        ))
        .unwrap();
        assert!(response.get("error").is_some());
        assert!(!response.to_string().contains("secret-code"));
    }
    let mut expired = pending;
    expired["created_at"] = json!(now() - 601);
    assert!(complete(serde_json::from_value(expired).unwrap(), &callback).is_err());
}

#[test]
fn callback_preflight_rejects_unrelated_responses_without_consuming_the_grant() {
    let login = begin("https://glossia.example", Some(registration())).unwrap();
    let pending = serde_json::to_value(&login.pending).unwrap();
    let validate = |callback: String| -> Value {
        serde_json::from_str(&bridge::execute(
            &json!({"operation":"validate_callback","pending":pending,"callback":callback})
                .to_string(),
        ))
        .unwrap()
    };
    assert_eq!(
        validate(format!("{REDIRECT_URI}?state=unrelated&code=stale"))["error"]["kind"],
        "invalid_callback"
    );
    assert_eq!(
        validate(format!(
            "{REDIRECT_URI}?state=unrelated&error=access_denied"
        ))["error"]["kind"],
        "invalid_callback"
    );
    assert_eq!(
        validate(format!(
            "{REDIRECT_URI}?state={}&error=access_denied",
            login.pending.state
        ))["error"]["kind"],
        "denied"
    );
    assert_eq!(
        validate(format!(
            "{REDIRECT_URI}?state={}&code=valid-code",
            login.pending.state
        )),
        json!({"ok":{}})
    );
}

#[test]
fn restoring_fresh_sessions_needs_no_network_and_refresh_keeps_omitted_token() {
    assert!(restore_using(&NetworkFixture::new(vec![]), saved_session()).is_ok());
    let mut saved = saved_session();
    saved.expires_at = 0;
    let network = NetworkFixture::new(vec![
        json!({"access_token":"new", "token_type":"Bearer", "expires_in":3600}),
    ]);
    let restored = restore_using(&network, saved).unwrap();
    assert_eq!(restored.refresh_token, "refresh");
    assert_eq!(restored.registration.client_id, "registered-native-client");
    assert_eq!(
        transport::response_failure(400, br#"{"error":"invalid_grant"}"#).kind,
        "rejected"
    );
    assert_eq!(
        transport::response_failure(503, br#"{"error":"invalid_grant"}"#).kind,
        "server"
    );
    assert_eq!(
        transport::response_failure(401, b"upstream error").kind,
        "server"
    );
}

#[test]
fn workspace_loads_all_project_pages_and_keeps_valid_global_context() {
    let network = NetworkFixture::new(vec![
        json!({"organizations":[{"handle":"first","name":"First"},{"handle":"team","name":"Team"}]}),
        json!({"projects":[{"handle":"one","name":"One"}],"meta":{"has_next_page?":true}}),
        json!({"projects":[{"handle":"two","name":"Two"}],"meta":{"has_next_page?":false}}),
    ]);
    let selection = serde_json::from_value(json!({"organization":"team","project":"two"})).unwrap();
    let result = workspace::load(&network, saved_session(), selection).unwrap();
    assert_eq!(
        result["selection"],
        json!({"organization":"team","project":"two"})
    );
    assert_eq!(result["projects"].as_array().unwrap().len(), 2);
    assert_eq!(
        network.requests.borrow()[2].0.as_str(),
        "https://glossia.example/api/team/projects?page=2"
    );
}

#[test]
fn missing_organization_resets_project_instead_of_reusing_same_handle_elsewhere() {
    let network = NetworkFixture::new(vec![
        json!({"organizations":[{"handle":"new","name":"New"}]}),
        json!({"projects":[{"handle":"default"},{"handle":"same-name"}]}),
    ]);
    let result = workspace::load(
        &network,
        saved_session(),
        serde_json::from_value(json!({"organization":"removed","project":"same-name"})).unwrap(),
    )
    .unwrap();
    assert_eq!(
        result["selection"],
        json!({"organization":"new","project":"default"})
    );
    let empty = workspace::load(
        &NetworkFixture::new(vec![json!({"organizations":[]})]),
        saved_session(),
        Default::default(),
    )
    .unwrap();
    assert_eq!(
        empty["selection"],
        json!({"organization":null,"project":null})
    );
}

#[test]
fn resources_are_organization_scoped_and_path_segments_are_encoded() {
    let network = NetworkFixture::new(vec![json!({"tone":"Friendly","version":3})]);
    let selection =
        serde_json::from_value(json!({"organization":"team name","project":"mobile"})).unwrap();
    let result = workspace::resource(
        &network,
        saved_session(),
        selection,
        workspace::Resource::Voice,
    )
    .unwrap();
    assert_eq!(result["voice"]["tone"], "Friendly");
    assert_eq!(
        network.requests.borrow()[0].0.as_str(),
        "https://glossia.example/api/team%20name/voice"
    );
}

#[test]
fn ffi_returns_sanitized_owned_strings() {
    use std::ffi::{CStr, CString};
    let input = CString::new(r#"{"operation":"unknown","secret":"must-not-echo"}"#).unwrap();
    unsafe {
        let output = bridge::glossia_core_execute(input.as_ptr());
        let text = CStr::from_ptr(output).to_str().unwrap();
        assert!(text.contains("invalid_response"));
        assert!(!text.contains("must-not-echo"));
        bridge::glossia_core_free(output);
        bridge::glossia_core_free(std::ptr::null_mut());
    }
}
