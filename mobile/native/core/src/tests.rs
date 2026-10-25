use super::*;
use serde_json::{Value, json};
use std::cell::RefCell;
use std::collections::VecDeque;

mod navigation;
mod reviews;

pub(crate) struct NetworkFixture {
    pub(crate) responses: RefCell<VecDeque<Result<Value>>>,
    pub(crate) requests: RefCell<Vec<(Url, Value)>>,
    pub(crate) methods: RefCell<Vec<&'static str>>,
}

impl NetworkFixture {
    pub(crate) fn new(responses: Vec<Value>) -> Self {
        Self {
            responses: RefCell::new(responses.into_iter().map(Ok).collect()),
            requests: RefCell::new(vec![]),
            methods: RefCell::new(vec![]),
        }
    }
}

impl Transport for NetworkFixture {
    fn request<T: serde::de::DeserializeOwned>(&self, url: &Url, body: Body<'_>) -> Result<T> {
        self.methods.borrow_mut().push(match &body {
            Body::Get | Body::Public { .. } | Body::Api(_) => "GET",
            Body::Json(_) | Body::Form(_) | Body::ApiJson(_, _) => "POST",
            Body::ApiPut(_, _) => "PUT",
            Body::Push { method, .. } => {
                if *method == reqwest::Method::PUT {
                    "PUT"
                } else {
                    "DELETE"
                }
            }
        });
        let body = match body {
            Body::Get | Body::Public { .. } => Value::Null,
            Body::Api(token) => json!({"bearer": token}),
            Body::ApiJson(token, value) | Body::ApiPut(token, value) => {
                json!({"bearer": token, "json": value})
            }
            Body::Push { token, payload, .. } => json!({"bearer": token, "json": payload}),
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
                .expect("unexpected request")?,
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

pub(crate) fn saved_session() -> Session {
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
    assert_eq!(
        query["scope"].split_whitespace().collect::<Vec<_>>(),
        [
            "organization:read",
            "project:read",
            "voice:read",
            "glossary:read",
            "user:read",
            "user:write",
            "translation:read",
            "translation:write",
            "analytics:read",
            "toki:read",
            "toki:write"
        ]
    );
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
        1,
        30,
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

fn feature_response(network: &NetworkFixture, mut command: Value) -> Value {
    command["session"] = serde_json::to_value(saved_session()).unwrap();
    serde_json::from_str(&bridge::execute_using(network, &command.to_string())).unwrap()
}

fn resource_command(resource: &str) -> Value {
    json!({"operation":"resource", "resource":resource,
        "selection":{"organization":"team","project":"mobile"}})
}

const CONVERSATION_ID: &str = "019a19fe-6c00-7000-8000-0123456789ab";
const MESSAGE_ID: &str = "019a19fe-6c00-7000-8000-0123456789ac";

fn conversation_command(action: &str) -> Value {
    let mut command = json!({"operation":"conversation", "action":action, "id":CONVERSATION_ID,
        "selection":{"organization":"team","project":"mobile"}});
    if action == "send" {
        command["message_id"] = json!(MESSAGE_ID);
        command["content"] = json!("  Translate this, please. 🌍\n");
    }
    command
}

#[test]
fn destinations_are_stable_with_toki_first_and_profile_last() {
    let response: Value =
        serde_json::from_str(&bridge::execute(r#"{"operation":"destinations"}"#)).unwrap();
    assert_eq!(
        response,
        json!({"ok":{"destinations":[
            {"id":"toki","title":"Toki","symbol":"bubble.left.and.bubble.right"},
            {"id":"translations","title":"Translations","symbol":"character.bubble"},
            {"id":"analytics","title":"Analytics","symbol":"chart.bar"},
            {"id":"profile","title":"Profile","symbol":"person.crop.circle"}
        ]}})
    );
}

#[test]
fn project_resources_preserve_complete_server_json_and_encode_dynamic_segments() {
    for (resource, suffix, response) in [
        (
            "translations",
            "translations?page=1",
            json!({"sessions":[{
            "id":"session-1", "status":"completed", "commit_message":"Add French",
            "source_language":"en", "target_languages":["fr"], "translated_content_count":3,
            "inserted_at":"2026-10-25T10:00:00Z", "summary":"Translated three strings"
        }],"meta":{"has_next_page?":true,"total_count":2},"future_field":{"keep":true}}),
        ),
        (
            "analytics",
            "analytics?days=30",
            json!({"summary":{
            "pageviews":100,"unique_visitors":70,"locale_gap_visits":25,
            "top_country":"ES","top_browser_language":"es"
        },"top_pages":[{"pathname":"/pricing","pageviews":40}],"days":30,"future_field":null}),
        ),
        (
            "conversations",
            "toki/conversations?page=1",
            json!({"conversations":[{
            "id":CONVERSATION_ID,"title":"Spanish launch","status":"running",
            "updated_at":"2026-10-25T10:00:00Z"
        }],"meta":{"has_next_page?":false,"page":1},"future_field":[1,2]}),
        ),
    ] {
        let network = NetworkFixture::new(vec![response.clone()]);
        let mut command = resource_command(resource);
        command["selection"] =
            json!({"organization":"team/name?role=owner#1","project":"../other %"});
        // UI-supplied URLs and paths cannot change the fixed route.
        command["url"] = json!("https://attacker.example/steal");
        command["path"] = json!("/api/other/projects/private");
        assert_eq!(feature_response(&network, command), json!({"ok":response}));
        let requests = network.requests.borrow();
        assert_eq!(requests.len(), 1);
        assert_eq!(
            requests[0].0.as_str(),
            format!(
                "https://glossia.example/api/team%2Fname%3Frole=owner%231/projects/..%2Fother%20%25/{suffix}"
            )
        );
        assert_eq!(requests[0].1, json!({"bearer":"access"}));
        assert_eq!(*network.methods.borrow(), ["GET"]);
    }
}

#[test]
fn profile_requires_no_workspace_and_preserves_the_server_envelope() {
    let response = json!({"user":{"id":"user-1","name":"Ana","email":"ana@example.com","handle":"ana"},
        "server_version":"2026.10.25", "future_field":{"keep":true}});
    let network = NetworkFixture::new(vec![response.clone()]);
    assert_eq!(
        feature_response(
            &network,
            json!({"operation":"resource","resource":"profile"})
        ),
        json!({"ok":response})
    );
    assert_eq!(
        network.requests.borrow()[0].0.as_str(),
        "https://glossia.example/api/me"
    );
    assert_eq!(network.requests.borrow()[0].1, json!({"bearer":"access"}));
}

#[test]
fn paginated_resources_make_one_request_and_validate_both_boundaries() {
    for resource in ["translations", "conversations"] {
        for page in [1, 2, 1000] {
            let response = json!({"meta":{"has_next_page?":true,"page":page}});
            let network = NetworkFixture::new(vec![response.clone()]);
            let mut command = resource_command(resource);
            command["page"] = json!(page);
            assert_eq!(feature_response(&network, command), json!({"ok":response}));
            assert_eq!(network.requests.borrow().len(), 1);
            assert_eq!(
                network.requests.borrow()[0].0.query(),
                Some(format!("page={page}").as_str())
            );
        }
        for page in [
            json!(0),
            json!(1001),
            json!(u32::MAX),
            json!(-1),
            json!(1.5),
            json!("2"),
            Value::Null,
            json!(u64::MAX),
        ] {
            let network = NetworkFixture::new(vec![]);
            let mut command = resource_command(resource);
            command["page"] = page;
            assert!(feature_response(&network, command).get("error").is_some());
            assert!(network.requests.borrow().is_empty());
        }
    }
}

#[test]
fn analytics_accepts_only_the_supported_day_windows() {
    for days in [7, 30, 90] {
        let network = NetworkFixture::new(vec![json!({"days":days})]);
        let mut command = resource_command("analytics");
        command["days"] = json!(days);
        assert_eq!(
            feature_response(&network, command),
            json!({"ok":{"days":days}})
        );
        assert_eq!(
            network.requests.borrow()[0].0.query(),
            Some(format!("days={days}").as_str())
        );
    }
    for days in [
        json!(0),
        json!(1),
        json!(31),
        json!(91),
        json!(-7),
        json!("30"),
        Value::Null,
    ] {
        let network = NetworkFixture::new(vec![]);
        let mut command = resource_command("analytics");
        command["days"] = days;
        assert!(feature_response(&network, command).get("error").is_some());
        assert!(network.requests.borrow().is_empty());
    }
}

#[test]
fn project_features_require_both_selections_and_reject_dot_segments() {
    let commands = [
        resource_command("translations"),
        resource_command("analytics"),
        resource_command("conversations"),
        conversation_command("create"),
        conversation_command("show"),
        conversation_command("send"),
    ];
    for mut command in commands {
        for selection in [
            json!({}),
            json!({"organization":"team"}),
            json!({"project":"mobile"}),
            json!({"organization":" ","project":"mobile"}),
            json!({"organization":"team","project":""}),
        ] {
            let network = NetworkFixture::new(vec![]);
            command["selection"] = selection;
            assert_eq!(
                feature_response(&network, command.clone())["error"]["kind"],
                "selection_required"
            );
            assert!(network.requests.borrow().is_empty());
        }
        for selection in [
            json!({"organization":"..","project":"mobile"}),
            json!({"organization":"team","project":"."}),
            json!({"organization":"team","project":"bad\nname"}),
        ] {
            let network = NetworkFixture::new(vec![]);
            command["selection"] = selection;
            assert_eq!(
                feature_response(&network, command.clone())["error"]["kind"],
                "invalid_input"
            );
            assert!(network.requests.borrow().is_empty());
        }
    }
}

#[test]
fn each_call_uses_its_own_project_and_does_not_refresh_native_owned_credentials() {
    let network = NetworkFixture::new(vec![json!({"sessions":[]}), json!({"sessions":[]})]);
    for (organization, project) in [("first", "same"), ("second", "same")] {
        let mut command = resource_command("translations");
        command["selection"] = json!({"organization":organization,"project":project});
        let mut session = saved_session();
        session.expires_at = 0;
        command["session"] = serde_json::to_value(session).unwrap();
        let result: Value =
            serde_json::from_str(&bridge::execute_using(&network, &command.to_string())).unwrap();
        assert_eq!(result, json!({"ok":{"sessions":[]}}));
    }
    let requests = network.requests.borrow();
    assert_eq!(requests.len(), 2);
    assert_eq!(
        requests[0].0.as_str(),
        "https://glossia.example/api/first/projects/same/translations?page=1"
    );
    assert_eq!(
        requests[1].0.as_str(),
        "https://glossia.example/api/second/projects/same/translations?page=1"
    );
}

#[test]
fn only_legacy_resources_wrap_results_and_treat_not_found_as_empty() {
    for resource in ["voice", "glossary"] {
        let network = NetworkFixture::new(vec![json!({"version":2,"content":"Hello"})]);
        let mut command = resource_command(resource);
        command["selection"] = json!({"organization":"team"});
        assert_eq!(
            feature_response(&network, command.clone()),
            json!({"ok":{resource:{"version":2,"content":"Hello"}}})
        );
        assert_eq!(
            network.requests.borrow()[0].0.as_str(),
            format!("https://glossia.example/api/team/{resource}")
        );
        let network = NetworkFixture::new(vec![]);
        network
            .responses
            .borrow_mut()
            .push_back(Err(error("not_found", "Not found.")));
        assert_eq!(
            feature_response(&network, command),
            json!({"ok":{resource:null}})
        );
    }
    for resource in ["translations", "analytics", "conversations", "profile"] {
        let network = NetworkFixture::new(vec![]);
        network
            .responses
            .borrow_mut()
            .push_back(Err(error("not_found", "Not found.")));
        assert_eq!(
            feature_response(&network, resource_command(resource))["error"]["kind"],
            "not_found"
        );
    }
}

#[test]
fn conversation_writes_replay_native_uuids_and_payloads_after_failures() {
    for (action, suffix, payload) in [
        ("create", "".to_owned(), json!({"id":CONVERSATION_ID})),
        (
            "send",
            format!("/{CONVERSATION_ID}/messages"),
            json!({"id":MESSAGE_ID,"content":"  Translate this, please. 🌍\n"}),
        ),
    ] {
        let detail = json!({"conversation":{"id":CONVERSATION_ID,"title":"Launch","status":"queued","updated_at":"now"},
            "messages":[],"future_field":{"keep":true}});
        let network = NetworkFixture::new(vec![detail.clone()]);
        network
            .responses
            .borrow_mut()
            .push_front(Err(error("network", "Could not reach Glossia. Try again.")));
        let command = conversation_command(action);
        assert_eq!(
            feature_response(&network, command.clone())["error"]["kind"],
            "network"
        );
        assert_eq!(
            network.requests.borrow().len(),
            1,
            "no implicit retry with a replacement ID"
        );
        assert_eq!(feature_response(&network, command), json!({"ok":detail}));
        let requests = network.requests.borrow();
        assert_eq!(requests[0], requests[1]);
        assert_eq!(
            requests[0].0.as_str(),
            format!("https://glossia.example/api/team/projects/mobile/toki/conversations{suffix}")
        );
        assert_eq!(requests[0].1, json!({"bearer":"access","json":payload}));
        assert_eq!(*network.methods.borrow(), ["POST", "POST"]);
    }
}

#[test]
fn showing_conversations_passes_all_polling_states_and_bounded_messages_through() {
    for status in ["queued", "running", "completed", "failed"] {
        let detail = json!({"conversation":{"id":CONVERSATION_ID,"title":null,"status":status,"updated_at":"now"},
            "messages":[{"id":MESSAGE_ID,"role":"assistant","content":"Hola","inserted_at":"now"}],
            "history_truncated":true});
        let network = NetworkFixture::new(vec![detail.clone()]);
        assert_eq!(
            feature_response(&network, conversation_command("show")),
            json!({"ok":detail})
        );
        assert_eq!(
            network.requests.borrow()[0].0.as_str(),
            format!(
                "https://glossia.example/api/team/projects/mobile/toki/conversations/{CONVERSATION_ID}"
            )
        );
        assert_eq!(network.requests.borrow()[0].1, json!({"bearer":"access"}));
        assert_eq!(*network.methods.borrow(), ["GET"]);
    }
}

#[test]
fn conversation_actions_reject_invalid_combinations_before_networking() {
    let mut commands = vec![];
    for key in ["id", "message_id", "content", "action", "selection"] {
        let mut command = conversation_command("send");
        command.as_object_mut().unwrap().remove(key);
        commands.push(command);
    }
    for action in ["create", "show"] {
        let mut command = conversation_command(action);
        command["content"] = json!("not allowed for this action");
        commands.push(command);
        let mut command = conversation_command(action);
        command["message_id"] = json!(MESSAGE_ID);
        commands.push(command);
    }
    commands.push(conversation_command("delete"));
    let mut command = conversation_command("show");
    command["url"] = json!("https://attacker.example");
    commands.push(command);
    for command in commands {
        let network = NetworkFixture::new(vec![]);
        let result = feature_response(&network, command);
        assert_eq!(result["error"]["kind"], "invalid_response", "{result}");
        assert!(network.requests.borrow().is_empty());
    }
}

#[test]
fn conversation_uuids_require_the_hyphenated_ascii_grammar() {
    for action in ["create", "show", "send"] {
        for bad in [
            "",
            "not-a-uuid",
            "019a19fe6c00700080000123456789ab",
            "{019a19fe-6c00-7000-8000-0123456789ab}",
            "019a19fe_6c00-7000-8000-0123456789ab",
            "019a19fe-6c00-7000-8000-0123456789ag",
            "../../api/other",
            "é19a19fe-6c00-7000-8000-0123456789ab",
        ] {
            let network = NetworkFixture::new(vec![]);
            let mut command = conversation_command(action);
            command["id"] = json!(bad);
            assert_eq!(
                feature_response(&network, command)["error"]["kind"],
                "invalid_input"
            );
            assert!(network.requests.borrow().is_empty());
            if action == "send" {
                let mut command = conversation_command(action);
                command["message_id"] = json!(bad);
                assert_eq!(
                    feature_response(&network, command)["error"]["kind"],
                    "invalid_input"
                );
                assert!(network.requests.borrow().is_empty());
            }
        }
    }
    let network = NetworkFixture::new(vec![json!({"messages":[]})]);
    let mut command = conversation_command("create");
    let id = CONVERSATION_ID.to_uppercase();
    command["id"] = json!(id);
    assert!(feature_response(&network, command).get("ok").is_some());
    assert_eq!(network.requests.borrow()[0].1["json"]["id"], id);
}

#[test]
fn message_validation_counts_unicode_characters_and_preserves_exact_content() {
    for content in [
        "".to_owned(),
        " \n\t\u{2003}".to_owned(),
        "a".repeat(4001),
        "🌍".repeat(4001),
    ] {
        let network = NetworkFixture::new(vec![]);
        let mut command = conversation_command("send");
        command["content"] = json!(content);
        assert_eq!(
            feature_response(&network, command)["error"]["kind"],
            "invalid_input"
        );
        assert!(network.requests.borrow().is_empty());
    }
    for content in [
        "x".to_owned(),
        "🌍".repeat(4000),
        format!(" {} ", "a".repeat(3998)),
    ] {
        let network = NetworkFixture::new(vec![json!({"messages":[]})]);
        let mut command = conversation_command("send");
        command["content"] = json!(content);
        assert!(feature_response(&network, command).get("ok").is_some());
        assert_eq!(network.requests.borrow()[0].1["json"]["content"], content);
    }
}

#[test]
fn conversation_errors_are_not_wrapped_or_treated_as_empty_results() {
    for kind in ["sign_in_required", "forbidden", "not_found", "server"] {
        for action in ["create", "show", "send"] {
            let network = NetworkFixture::new(vec![]);
            network
                .responses
                .borrow_mut()
                .push_back(Err(error(kind, "Safe failure.")));
            assert_eq!(
                feature_response(&network, conversation_command(action)),
                json!({"error":{"kind":kind,"message":"Safe failure."}})
            );
            assert_eq!(network.requests.borrow().len(), 1);
        }
    }
}

#[test]
fn translation_detail_fetches_a_direct_id_beyond_lists_and_retains_the_response() {
    let id = MESSAGE_ID.to_uppercase();
    let detail = json!({"session":{"id":id,"status":"completed","summary":"Translate this",
        "future_field":{"keep":true},"target_languages":["fr"]},"future_field":null});
    let network = NetworkFixture::new(vec![json!({"sessions":[]}), detail.clone()]);
    feature_response(&network, resource_command("translations"));
    let mut command = json!({"operation":"translation","id":id,
        "selection":{"organization":"exact-team","project":"exact-project"}});
    command["url"] = json!("https://attacker.example/steal");
    assert_eq!(feature_response(&network, command), json!({"ok":detail}));
    let requests = network.requests.borrow();
    assert_eq!(requests.len(), 2, "no search through list pages");
    assert_eq!(
        requests[1].0.as_str(),
        format!("https://glossia.example/api/exact-team/projects/exact-project/translations/{id}")
    );
    assert_eq!(requests[1].1, json!({"bearer":"access"}));
    assert_eq!(*network.methods.borrow(), ["GET", "GET"]);
}

#[test]
fn translation_detail_validates_only_api_id_and_selection_and_preserves_errors() {
    let command = json!({"operation":"translation","id":MESSAGE_ID,
        "selection":{"organization":"team/name","project":"project name"}});
    let network = NetworkFixture::new(vec![json!({"session":{"id":MESSAGE_ID}})]);
    assert!(
        feature_response(&network, command.clone())
            .get("ok")
            .is_some()
    );
    assert_eq!(
        network.requests.borrow()[0].0.as_str(),
        format!(
            "https://glossia.example/api/team%2Fname/projects/project%20name/translations/{MESSAGE_ID}"
        )
    );
    for id in [
        "",
        "not-a-uuid",
        "../other",
        "019a19fe6c00700080000123456789ac",
        "019a19fe-6c00-7000-8000-0123456789ag",
        "019a19fe-6c00-7000-8000-0123456789ac\n",
    ] {
        let network = NetworkFixture::new(vec![]);
        let mut command = command.clone();
        command["id"] = json!(id);
        assert_eq!(
            feature_response(&network, command)["error"]["kind"],
            "invalid_input"
        );
        assert!(network.requests.borrow().is_empty());
    }
    for selection in [
        json!({}),
        json!({"organization":"team"}),
        json!({"project":"mobile"}),
    ] {
        let network = NetworkFixture::new(vec![]);
        let mut command = command.clone();
        command["selection"] = selection;
        assert_eq!(
            feature_response(&network, command)["error"]["kind"],
            "selection_required"
        );
        assert!(network.requests.borrow().is_empty());
    }
    for kind in [
        "sign_in_required",
        "forbidden",
        "not_found",
        "server",
        "network",
    ] {
        let network = NetworkFixture::new(vec![]);
        network
            .responses
            .borrow_mut()
            .push_back(Err(error(kind, "Safe failure.")));
        assert_eq!(
            feature_response(&network, command.clone()),
            json!({"error":{"kind":kind,"message":"Safe failure."}})
        );
        assert_eq!(network.requests.borrow().len(), 1);
    }
}

#[test]
fn conversation_creation_retains_its_source_uuid_across_retries_without_normalizing_payloads() {
    let source = MESSAGE_ID.to_uppercase();
    let detail = json!({"conversation":{"id":CONVERSATION_ID,"translation_session_id":source,
        "status":"queued"},"messages":[],"future_field":true});
    let network = NetworkFixture::new(vec![detail.clone()]);
    network
        .responses
        .borrow_mut()
        .push_front(Err(error("network", "Try again.")));
    let mut command = conversation_command("create");
    command["translation_session_id"] = json!(source);
    assert_eq!(
        feature_response(&network, command.clone())["error"]["kind"],
        "network"
    );
    assert_eq!(network.requests.borrow().len(), 1);
    assert_eq!(feature_response(&network, command), json!({"ok":detail}));
    let requests = network.requests.borrow();
    assert_eq!(requests[0], requests[1]);
    assert_eq!(
        requests[0].0.as_str(),
        "https://glossia.example/api/team/projects/mobile/toki/conversations"
    );
    assert_eq!(
        requests[0].1,
        json!({"bearer":"access","json":{"id":CONVERSATION_ID,"translation_session_id":source}})
    );
    assert_eq!(*network.methods.borrow(), ["POST", "POST"]);
}

#[test]
fn conversation_source_is_optional_and_only_allowed_on_create() {
    for source in [None, Some(Value::Null)] {
        let detail = json!({"conversation":{"id":CONVERSATION_ID,"translation_session_id":null},"messages":[]});
        let network = NetworkFixture::new(vec![detail.clone()]);
        let mut command = conversation_command("create");
        if let Some(source) = source {
            command["translation_session_id"] = source;
        }
        assert_eq!(feature_response(&network, command), json!({"ok":detail}));
        assert_eq!(
            network.requests.borrow()[0].1["json"],
            json!({"id":CONVERSATION_ID})
        );
    }
    for source in [
        json!(""),
        json!("not-a-uuid"),
        json!("../other"),
        json!(123),
        json!({}),
    ] {
        let network = NetworkFixture::new(vec![]);
        let mut command = conversation_command("create");
        command["translation_session_id"] = source;
        assert!(feature_response(&network, command).get("error").is_some());
        assert!(network.requests.borrow().is_empty());
    }
    for action in ["show", "send"] {
        for source in [json!(MESSAGE_ID), Value::Null] {
            let network = NetworkFixture::new(vec![]);
            let mut command = conversation_command(action);
            command["translation_session_id"] = source;
            assert_eq!(
                feature_response(&network, command)["error"]["kind"],
                "invalid_response"
            );
            assert!(network.requests.borrow().is_empty());
        }
    }
}
