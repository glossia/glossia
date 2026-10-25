use super::*;
use crate::tests::{NetworkFixture, saved_session};

const ID: &str = "01922cc0-0000-7000-8000-000000000001";

fn register() -> Action {
    Action::Register {
        installation_id: ID.into(),
        platform: Platform::Ios,
        token: "ab".repeat(32),
        environment: Environment::Sandbox,
    }
}

#[test]
fn enrollment_uses_fixed_put_with_bearer_and_only_public_result() {
    let network = NetworkFixture::new(vec![
        json!({"registered":true,"registration_id":ID,"token":"secret"}),
    ]);
    assert_eq!(
        execute(&network, saved_session(), register()).unwrap(),
        json!({"registered":true,"registration_id":ID})
    );
    assert_eq!(network.methods.borrow()[0], "PUT");
    let requests = network.requests.borrow();
    assert_eq!(
        requests[0].0.as_str(),
        format!("https://glossia.example/api/me/push-devices/{ID}")
    );
    assert_eq!(
        requests[0].1,
        json!({"bearer":"access","json":{"platform":"ios","token":"ab".repeat(32),"environment":"sandbox"}})
    );
}

#[test]
fn unregister_has_no_provider_token_or_owner_selector() {
    let network = NetworkFixture::new(vec![json!({"deleted":true})]);
    execute(
        &network,
        saved_session(),
        Action::Unregister {
            installation_id: ID.into(),
        },
    )
    .unwrap();
    assert_eq!(network.methods.borrow()[0], "DELETE");
    assert_eq!(
        network.requests.borrow()[0].1,
        json!({"bearer":"access","json":null})
    );
    assert!(
        serde_json::from_value::<Action>(
            json!({"action":"unregister","installation_id":ID,"user_id":ID})
        )
        .is_err()
    );
}

#[test]
fn rejects_bad_ids_tokens_environments_sessions_and_origins_before_network() {
    let network = NetworkFixture::new(vec![]);
    for id in [
        "",
        "../settings",
        "id?owner=other",
        "01922CC0-0000-7000-8000-000000000001",
    ] {
        assert!(
            execute(
                &network,
                saved_session(),
                Action::Unregister {
                    installation_id: id.into()
                }
            )
            .is_err()
        );
    }
    for (platform, token, environment) in [
        (Platform::Ios, "not hex".into(), Environment::Production),
        (Platform::Ios, "a".repeat(33), Environment::Sandbox),
        (Platform::Ios, "ab".repeat(300), Environment::Production),
        (
            Platform::Android,
            "fcm-token-value-123".into(),
            Environment::Sandbox,
        ),
        (
            Platform::Android,
            "token with spaces".into(),
            Environment::Production,
        ),
        (Platform::Android, "a".repeat(4097), Environment::Production),
    ] {
        assert!(
            execute(
                &network,
                saved_session(),
                Action::Register {
                    installation_id: ID.into(),
                    platform,
                    token,
                    environment
                }
            )
            .is_err()
        );
    }
    let mut expired = saved_session();
    expired.expires_at = 0;
    assert!(execute(&network, expired, register()).is_err());
    let mut foreign = saved_session();
    foreign.registration.token_endpoint = "https://evil.example/token".into();
    assert!(execute(&network, foreign, register()).is_err());
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn android_and_bridge_use_the_same_contract() {
    let network = NetworkFixture::new(vec![json!({"registered":true,"registration_id":ID})]);
    let request = json!({"operation":"push","session":saved_session(),"action":"register","installation_id":ID,
        "platform":"android","token":"fcm-token-value-123","environment":"production"});
    let response: Value = serde_json::from_str(&crate::bridge::execute_using(
        &network,
        &request.to_string(),
    ))
    .unwrap();
    assert_eq!(response["ok"]["registration_id"], ID);
    assert_eq!(
        network.requests.borrow()[0].1["json"]["platform"],
        "android"
    );
}

#[test]
fn mismatched_registration_ids_and_unsuccessful_results_fail_closed() {
    for response in [
        json!({"registered":false,"registration_id":ID}),
        json!({"registered":true}),
        json!({"registered":true,"registration_id":"01922cc0-0000-7000-8000-000000000002"}),
    ] {
        assert!(
            execute(
                &NetworkFixture::new(vec![response]),
                saved_session(),
                register()
            )
            .is_err()
        );
    }
    for status in [400, 401, 403, 404, 409, 422, 429, 500, 501, 503] {
        assert!(
            !serde_json::to_string(&failure(status, b"secret-provider-token"))
                .unwrap()
                .contains("secret-provider-token")
        );
        assert_ne!(failure(status, b"").kind, "rejected");
    }
}
