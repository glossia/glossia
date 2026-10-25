use super::*;

fn response(network: &NetworkFixture, command: Value) -> Value {
    serde_json::from_str(&bridge::execute_using(network, &command.to_string())).unwrap()
}

fn destination(screen: &str) -> Value {
    json!({"screen":screen,"server":"https://glossia.example/",
        "organization":"team","project":"mobile","id":null,"translation_id":null})
}

fn parse(network: &NetworkFixture, url: &str) -> Value {
    response(
        network,
        json!({"operation":"navigation","action":"parse","url":url}),
    )
}

fn link(network: &NetworkFixture, destination: Value) -> Value {
    response(
        network,
        json!({"operation":"navigation","action":"link","destination":destination}),
    )
}

fn assert_invalid(value: Value) {
    assert_eq!(value["error"]["kind"], "invalid_link", "{value}");
    let message = value["error"]["message"].as_str().unwrap();
    assert!(message.contains("HTTPS server"));
    assert!(!value.to_string().contains("must-not-echo"));
    assert!(value.get("ok").is_none());
}

#[test]
fn all_routes_round_trip_through_the_bridge_with_canonical_origins_and_nulls() {
    let network = NetworkFixture::new(vec![]);
    for (server, canonical) in [
        ("https://GLOSSIA.example:443", "https://glossia.example/"),
        ("HTTPS://glossia.example/", "https://glossia.example/"),
        (
            "https://glossia.example:4443",
            "https://glossia.example:4443/",
        ),
        ("https://[::1]:4443", "https://[::1]:4443/"),
        (
            "https://[2001:0DB8:0:0:0:0:0:1]:443/",
            "https://[2001:db8::1]/",
        ),
        ("https://xn--xample-9ua.org", "https://xn--xample-9ua.org/"),
        (
            "https://glossia_example.org",
            "https://glossia_example.org/",
        ),
    ] {
        for (screen, route, id, source) in [
            ("toki", "team/mobile/toki".to_owned(), None, None),
            (
                "conversation",
                format!("team/mobile/toki/{CONVERSATION_ID}"),
                Some(CONVERSATION_ID),
                None,
            ),
            (
                "new_conversation",
                "team/mobile/toki/new".to_owned(),
                None,
                None,
            ),
            (
                "new_conversation",
                "team/mobile/toki/new".to_owned(),
                None,
                Some(MESSAGE_ID),
            ),
            (
                "translations",
                "team/mobile/translations".to_owned(),
                None,
                None,
            ),
            (
                "translation",
                format!("team/mobile/translations/{MESSAGE_ID}"),
                Some(MESSAGE_ID),
                None,
            ),
            ("analytics", "team/mobile/analytics".to_owned(), None, None),
            ("profile", "profile".to_owned(), None, None),
        ] {
            let mut destination = destination(screen);
            destination["server"] = json!(server);
            destination["id"] = json!(id.map(str::to_uppercase));
            destination["translation_id"] = json!(source.map(str::to_uppercase));
            if screen == "profile" {
                destination["organization"] = Value::Null;
                destination["project"] = Value::Null;
            }
            let linked = link(&network, destination.clone());
            destination["server"] = json!(canonical);
            destination["id"] = json!(id);
            destination["translation_id"] = json!(source);
            let mut query = url::form_urlencoded::Serializer::new(String::new());
            query.append_pair("server", canonical);
            if let Some(source) = source {
                query.append_pair("translation_id", source);
            }
            let url = format!("glossia://navigate/{route}?{}", query.finish());
            assert_eq!(linked, json!({"ok":{"destination":destination,"url":url}}));
            assert_eq!(parse(&network, &url), linked);
            assert_eq!(link(&network, linked["ok"]["destination"].clone()), linked);
        }
    }
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn parsing_normalizes_uuid_case_origin_and_query_order_but_not_workspace_case() {
    let network = NetworkFixture::new(vec![]);
    let url = format!(
        "GLOSSIA://NAVIGATE/team/mobile/toki/new?translation_id={}&server=HTTPS%3A%2F%2FGLOSSIA.example%3A443",
        MESSAGE_ID.to_uppercase()
    );
    let mut expected = destination("new_conversation");
    expected["translation_id"] = json!(MESSAGE_ID);
    assert_eq!(parse(&network, &url), link(&network, expected));
    let url = format!(
        "glossia://navigate/team/mobile/toki/{}?server=https://glossia.example",
        CONVERSATION_ID.to_uppercase()
    );
    assert_eq!(
        parse(&network, &url)["ok"]["destination"]["id"],
        CONVERSATION_ID
    );
    assert_invalid(parse(
        &network,
        "glossia://navigate/TEAM/mobile/toki?server=https://glossia.example",
    ));
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn destinations_require_exact_screen_workspace_and_id_combinations() {
    let network = NetworkFixture::new(vec![]);
    for screen in [
        "toki",
        "conversation",
        "new_conversation",
        "translations",
        "translation",
        "analytics",
        "profile",
    ] {
        let mut valid = destination(screen);
        if matches!(screen, "conversation" | "translation") {
            valid["id"] = json!(CONVERSATION_ID);
        }
        if screen == "profile" {
            valid["organization"] = Value::Null;
            valid["project"] = Value::Null;
            for key in ["organization", "project"] {
                let mut invalid = valid.clone();
                invalid[key] = json!("team");
                assert_invalid(link(&network, invalid));
            }
        } else {
            for key in ["organization", "project"] {
                let mut invalid = valid.clone();
                invalid[key] = Value::Null;
                assert_invalid(link(&network, invalid));
            }
        }
        if matches!(screen, "conversation" | "translation") {
            for id in [
                Value::Null,
                json!("not-a-uuid"),
                json!("019a19fe6c00700080000123456789ab"),
            ] {
                let mut invalid = valid.clone();
                invalid["id"] = id;
                assert_invalid(link(&network, invalid));
            }
        } else {
            let mut invalid = valid.clone();
            invalid["id"] = json!(CONVERSATION_ID);
            assert_invalid(link(&network, invalid));
        }
        let mut invalid = valid.clone();
        invalid["translation_id"] = json!(if screen == "new_conversation" {
            "bad"
        } else {
            MESSAGE_ID
        });
        assert_invalid(link(&network, invalid));
        for key in [
            "url",
            "content",
            "credentials",
            "access_token",
            "action",
            "translation_session_id",
        ] {
            let mut invalid = valid.clone();
            invalid[key] = json!("must-not-echo");
            assert_invalid(link(&network, invalid));
        }
        for key in ["screen", "server"] {
            let mut invalid = valid.clone();
            invalid.as_object_mut().unwrap().remove(key);
            assert_invalid(link(&network, invalid));
        }
        // Omitted optional values are accepted, but always serialized as null.
        valid
            .as_object_mut()
            .unwrap()
            .retain(|_, value| !value.is_null());
        let output = link(&network, valid);
        let normalized = output["ok"]["destination"].as_object().unwrap();
        for key in ["organization", "project", "id", "translation_id"] {
            assert!(normalized.contains_key(key));
        }
    }
    for command in [
        json!({"operation":"navigation","action":"parse","url":"glossia://navigate/profile?server=https://glossia.example","state":"must-not-echo"}),
        json!({"operation":"navigation","action":"link","destination":destination("toki"),"url":"must-not-echo"}),
        json!({"operation":"navigation","action":"parse","destination":destination("toki")}),
        json!({"operation":"navigation","action":"link","url":"must-not-echo"}),
        json!({"operation":"navigation","action":"delete","destination":destination("toki")}),
        json!({"operation":"navigation","destination":destination("toki")}),
        json!({"operation":"navigation","action":"parse","url":null}),
        json!({"operation":"navigation","action":"link","destination":null}),
    ] {
        assert_invalid(response(&network, command));
    }
    let mut invalid = destination("browser");
    assert_invalid(link(&network, invalid.clone()));
    invalid["screen"] = json!("Toki");
    assert_invalid(link(&network, invalid));
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn handles_follow_schema_rules_with_bounded_ascii_components() {
    let network = NetworkFixture::new(vec![]);
    for (organization, project) in [
        ("a".to_owned(), "0".to_owned()),
        ("team--1".to_owned(), "1-mobile".to_owned()),
        ("a".repeat(100), "1".repeat(100)),
    ] {
        let mut valid = destination("toki");
        valid["organization"] = json!(organization);
        valid["project"] = json!(project);
        let linked = link(&network, valid);
        assert_eq!(
            parse(&network, linked["ok"]["url"].as_str().unwrap()),
            linked
        );
    }
    for key in ["organization", "project"] {
        for value in [
            "",
            "UPPER",
            "-leading",
            "trailing-",
            "under_score",
            "two words",
            "équipe",
            ".",
            "..",
            "one/two",
            "one%2ftwo",
            "one\\two",
            "bad\nname",
            "bad\u{7f}",
            "../team",
        ] {
            let mut invalid = destination("toki");
            invalid[key] = json!(value);
            assert_invalid(link(&network, invalid));
        }
        let mut invalid = destination("toki");
        invalid[key] = json!("a".repeat(101));
        assert_invalid(link(&network, invalid));
    }
    let mut invalid = destination("toki");
    invalid["organization"] = json!("1team");
    assert_invalid(link(&network, invalid));
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn raw_paths_reject_encoded_components_and_dot_normalization_before_url_parsing() {
    let network = NetworkFixture::new(vec![]);
    for path in [
        "",
        "profile/",
        "profile/extra",
        "team/mobile/toki/",
        "team/mobile/toki//new",
        "team//toki",
        "/team/mobile/toki",
        "team/mobile/voice",
        "team/mobile/glossary",
        "team/mobile/profile",
        "team/mobile/Toki",
        "team/mobile/analytics/new",
        "team/mobile/translations/new",
        "team/mobile/toki/not-a-uuid",
        "team/mobile/toki/019a19fe6c00700080000123456789ab",
        "team/mobile/toki/019a19fe-6c00-7000-8000-0123456789ag",
        "team/mobile/translations/019a19fe-6c00-7000-8000-0123456789ac/edit",
        "team/mobile/./toki",
        "team/mobile/ignored/../toki",
        "team/mobile/%2e/toki",
        "team/mobile/ignored/%2E%2e/toki",
        "team/mobile/translations/%2e%2e/toki",
        "team/mobile/%74oki",
        "team%2fother/mobile/toki",
        "team/mobile%2Fother/toki",
        "team/mobile/toki/%30%31%39a19fe-6c00-7000-8000-0123456789ab",
        "team/mobile/toki/%252e%252e",
        "team/mobile/toki%5cnew",
        "team/mobile/toki\\new",
        "team/mobile/toki\n",
        "team/mobile/toki\0",
    ] {
        let url = format!("glossia://navigate/{path}?server=https%3A%2F%2Fglossia.example");
        assert_invalid(parse(&network, &url));
    }
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn invalid_queries_hosts_and_unclaimed_web_routes_never_become_navigation() {
    let network = NetworkFixture::new(vec![]);
    let base = "glossia://navigate/team/mobile/toki";
    for suffix in [
        "",
        "?",
        "?server",
        "?server=",
        "?server=https://glossia.example&server=https://glossia.example",
        "?server=https://glossia.example&state=must-not-echo",
        "?server=https://glossia.example&action=delete",
        "?server=https://glossia.example&content=must-not-echo",
        "?server=https://glossia.example&",
        "?&server=https://glossia.example",
        "?server=https://glossia.example&&",
        "?%73erver=https://glossia.example",
        "?Server=https://glossia.example",
        "?server=https://glossia.example#",
        "?server=https://glossia.example#must-not-echo",
        "?server=https://glossia.example&translation_id=019a19fe-6c00-7000-8000-0123456789ac",
    ] {
        assert_invalid(parse(&network, &format!("{base}{suffix}")));
    }
    for prefix in [
        "glossia://user@navigate",
        "glossia://user:pass@navigate",
        "glossia://@navigate",
        "glossia://navigate:443",
        "glossia://navigate:0",
        "glossia://%6eavigate",
        "glossia://navigate.",
        "glossia://other",
        "glossia:///navigate",
        "glossia:/navigate",
        "http://navigate",
        "https://navigate",
        "glossia://oauth",
        "other://navigate",
    ] {
        assert_invalid(parse(
            &network,
            &format!("{prefix}/team/mobile/toki?server=https://glossia.example"),
        ));
    }
    for route in [
        "team/mobile/toki/new",
        "profile",
        "team/mobile/translations",
    ] {
        for extra in [
            "&translation_id=",
            "&translation_id=not-a-uuid",
            "&translation_id=019a19fe6c00700080000123456789ab",
            "&translation_id=019a19fe-6c00-7000-8000-0123456789ac&translation_id=019a19fe-6c00-7000-8000-0123456789ac",
            "&%74ranslation_id=019a19fe-6c00-7000-8000-0123456789ac",
        ] {
            assert_invalid(parse(
                &network,
                &format!("glossia://navigate/{route}?server=https://glossia.example{extra}"),
            ));
        }
    }
    for url in [
        "https://glossia.example/team/mobile/toki",
        "https://glossia.example/open/toki",
        "glossia://oauth/callback?code=must-not-echo&state=must-not-echo",
    ] {
        assert_invalid(parse(&network, url));
    }
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn origins_are_strict_in_both_directions_without_accepting_url_normalization() {
    let network = NetworkFixture::new(vec![]);
    for server in [
        "",
        "http://glossia.example",
        "https:glossia.example",
        "https:///glossia.example",
        "https://",
        "https://user:must-not-echo@glossia.example",
        "https://@glossia.example",
        "https://glossia.example:0",
        "https://glossia.example:0000",
        "https://glossia.example:65536",
        "https://glossia.example:",
        "https://glossia.example/path",
        "https://glossia.example/.",
        "https://glossia.example/../",
        "https://glossia.example/%2e",
        "https://glossia.example//",
        "https://glossia.example?token=must-not-echo",
        "https://glossia.example?",
        "https://glossia.example/#",
        "https://glossia.example#must-not-echo",
        "https://glossia.example\\",
        "https://glossia.example\n",
        "\thttps://glossia.example",
        " https://glossia.example",
        "https://glossia.example ",
        "https://glossia.example\0",
        "https://glossia.example\u{7f}",
        "https://éxample.org",
        "https://glossia+example.org",
        "https://%67lossia.example",
        "https://[::1]:0",
        "https://[not-ipv6]",
        "https://[::1]/other",
    ] {
        let mut invalid = destination("toki");
        invalid["server"] = json!(server);
        assert_invalid(link(&network, invalid));
        let query = url::form_urlencoded::Serializer::new(String::new())
            .append_pair("server", server)
            .finish();
        assert_invalid(parse(
            &network,
            &format!("glossia://navigate/team/mobile/toki?{query}"),
        ));
    }
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn link_size_is_bounded_in_bytes_for_parsing_and_building() {
    let network = NetworkFixture::new(vec![]);
    let base = link(&network, destination("toki"));
    let length = base["ok"]["url"].as_str().unwrap().len();
    // Host parsing does not perform DNS resolution or impose DNS wire limits.
    let server = format!("https://{}glossia.example/", "a".repeat(2048 - length));
    let mut value = destination("toki");
    value["server"] = json!(server);
    let linked = link(&network, value.clone());
    let url = linked["ok"]["url"].as_str().unwrap();
    assert_eq!(url.len(), 2048);
    assert_eq!(parse(&network, url), linked);
    assert_invalid(parse(&network, &format!("{url}a")));
    value["server"] = json!(format!(
        "https://a{}",
        server.strip_prefix("https://").unwrap()
    ));
    assert_invalid(link(&network, value));
    assert!(network.requests.borrow().is_empty());
}

#[test]
fn navigation_does_not_consume_oauth_state_or_make_requests() {
    let network = NetworkFixture::new(vec![
        json!({"access_token":"signed-in", "refresh_token":"refresh", "token_type":"Bearer", "expires_in":3600}),
    ]);
    let login = begin_using(&network, "https://glossia.example", Some(registration())).unwrap();
    let callback = format!(
        "{REDIRECT_URI}?state={}&code=must-not-echo",
        login.pending.state
    );
    let pending = serde_json::to_value(login.pending).unwrap();
    assert_invalid(parse(&network, &callback));
    let linked = link(&network, destination("toki"));
    assert!(linked.get("ok").is_some());
    let validate = json!({"operation":"validate_callback","pending":pending,"callback":callback});
    assert_eq!(response(&network, validate), json!({"ok":{}}));
    assert!(network.requests.borrow().is_empty());
    let complete = json!({"operation":"complete","pending":pending,"callback":callback});
    assert_eq!(
        response(&network, complete)["ok"]["access_token"],
        "signed-in"
    );
    assert_eq!(network.requests.borrow().len(), 1);
}
