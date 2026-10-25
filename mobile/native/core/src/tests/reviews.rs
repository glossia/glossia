use super::*;

#[test]
fn fluent_languages_use_exact_authenticated_profile_put_and_validate_before_transport() {
    for tags in [json!([]), json!(["es", "ar", "zh-Hant", "pt-BR"])] {
        let response = json!({"user": {"fluent_languages": tags}});
        let network = NetworkFixture::new(vec![response.clone()]);
        assert_eq!(
            feature_response(
                &network,
                json!({"operation": "fluent_languages", "fluent_languages": tags})
            ),
            json!({"ok": response})
        );
        assert_eq!(*network.methods.borrow(), ["PUT"]);
        let requests = network.requests.borrow();
        assert_eq!(requests[0].0.path(), "/api/me/fluent-languages");
        assert_eq!(
            requests[0].1,
            json!({"bearer": "access", "json": {"fluent_languages": tags}})
        );
    }
    for tags in [
        json!(["../escape"]),
        json!(["es", "ES"]),
        json!(["en_US"]),
        json!([""]),
        json!(["en--US"]),
        json!(["العربية"]),
        json!(vec!["en"; 101]),
    ] {
        let network = NetworkFixture::new(vec![]);
        assert!(
            feature_response(
                &network,
                json!({"operation": "fluent_languages", "fluent_languages": tags})
            )
            .get("error")
            .is_some()
        );
        assert!(network.requests.borrow().is_empty());
    }
}

fn command(action: &str) -> Value {
    json!({"operation": "translation_reviews", "action": action,
        "selection": {"organization": "acme", "project": "website"},
        "id": "abc12345-802e-4f91-9112-77d8a919efc5",
        "review_id": "def12345-802e-4f91-9112-77d8a919efc5", "answer": "Use informal tú."})
}

#[test]
fn review_commands_use_fixed_authenticated_routes_and_exact_optional_payloads() {
    let mut list = command("list");
    list.as_object_mut().unwrap().remove("answer");
    list.as_object_mut().unwrap().remove("review_id");
    let response = json!({"reviews": [{"status": "open", "question": "Formal or informal?"}]});
    let network = NetworkFixture::new(vec![
        response.clone(),
        json!({"review": {"status": "answered"}}),
        json!({"review": {"status": "answered"}}),
    ]);
    assert_eq!(feature_response(&network, list), json!({"ok": response}));
    assert!(
        feature_response(&network, command("answer"))
            .get("ok")
            .is_some()
    );
    let mut reusable = command("answer");
    reusable["guidance"] = json!("Use informal tú for Spanish onboarding.");
    reusable["context_scope"] = json!("locale");
    reusable["resolution_message_id"] = json!("aaa12345-802e-4f91-9112-77d8a919efc5");
    assert!(feature_response(&network, reusable).get("ok").is_some());
    assert_eq!(*network.methods.borrow(), ["GET", "POST", "POST"]);
    let requests = network.requests.borrow();
    let path =
        "/api/acme/projects/website/translations/abc12345-802e-4f91-9112-77d8a919efc5/reviews";
    assert_eq!(requests[0].0.path(), path);
    assert_eq!(requests[0].1, json!({"bearer": "access"}));
    assert_eq!(
        requests[1].0.path(),
        format!("{path}/def12345-802e-4f91-9112-77d8a919efc5/answer")
    );
    assert_eq!(
        requests[1].1,
        json!({"bearer": "access", "json": {"answer": "Use informal tú."}})
    );
    assert_eq!(
        requests[2].1["json"],
        json!({"answer": "Use informal tú.", "guidance": "Use informal tú for Spanish onboarding.", "context_scope": "locale", "resolution_message_id": "aaa12345-802e-4f91-9112-77d8a919efc5"})
    );
}

#[test]
fn invalid_reviews_never_reach_transport_and_unicode_limits_count_characters() {
    for (key, value) in [
        ("id", json!("../escape")),
        ("review_id", json!("bad")),
        ("resolution_message_id", json!("bad")),
        ("answer", json!(" \n")),
        ("answer", json!("字".repeat(8001))),
        ("guidance", json!("")),
        ("guidance", json!("x".repeat(8001))),
        ("context_scope", json!("project")),
        ("context_scope", json!("other")),
        ("url", json!("https://attacker.example")),
    ] {
        let network = NetworkFixture::new(vec![]);
        let mut input = command("answer");
        input[key] = value;
        assert!(feature_response(&network, input).get("error").is_some());
        assert!(network.requests.borrow().is_empty());
    }
    for scope in ["locale", "project"] {
        let network = NetworkFixture::new(vec![json!({"review": {}})]);
        let mut input = command("answer");
        input["answer"] = json!("字".repeat(8000));
        input["guidance"] = json!("独立したルール");
        input["context_scope"] = json!(scope);
        assert!(feature_response(&network, input).get("ok").is_some());
    }
}

#[test]
fn review_access_and_conflict_errors_are_not_retried_or_hidden() {
    for kind in ["forbidden", "not_found", "conflict", "network"] {
        let network = NetworkFixture::new(vec![]);
        network
            .responses
            .borrow_mut()
            .push_back(Err(error(kind, "Cannot answer")));
        assert_eq!(
            feature_response(&network, command("answer"))["error"]["kind"],
            kind
        );
        assert_eq!(network.requests.borrow().len(), 1);
    }
}
